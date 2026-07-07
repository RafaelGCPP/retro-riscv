# F1 - UART RX Channel: Architectural Decision Log

This document records key technical decisions made during the design phase, capturing trade-offs and rationale.

---

## ADR-001: Polling vs Interrupt-Driven UART RX

**Date:** 2026-07-07  
**Status:** Decided  
**Decision:** Implement polling-based UART RX in this feature iteration.

### Context
UART RX can be implemented in two modes:
1. **Polling:** Firmware busy-waits or periodically checks RX_VALID flag
2. **Interrupt-driven:** UART asserts IRQ line when byte received, CPU handles in ISR

### Decision Drivers
- PicoRV32 interrupt support requires additional wiring and firmware complexity
- Current firmware has no interrupt infrastructure (no IRQ handlers, no vector table)
- Polling is sufficient for low-throughput interactive console use case
- Feature scope prioritizes quick delivery for monitor development

### Decision
Use polling mode only. Defer interrupt support to future feature.

### Consequences
- **Positive:** Simpler implementation, fewer moving parts, easier testing
- **Positive:** Firmware remains single-threaded and deterministic
- **Negative:** CPU cannot sleep while waiting for input (power inefficient)
- **Negative:** High-throughput RX scenarios will be inefficient
- **Mitigation:** Document upgrade path to interrupts in future ADR

---

## ADR-002: Single-Byte vs FIFO Buffering

**Date:** 2026-07-07  
**Status:** Decided  
**Decision:** Implement single-byte RX buffer (latch register).

### Context
UART RX data can be buffered in:
1. **Single-byte latch:** Holds one received byte until software reads it
2. **FIFO buffer:** Stores multiple bytes (e.g., 16-byte FIFO)

### Decision Drivers
- Interactive console use case has low throughput (human typing speed ~10 chars/sec)
- Single-byte buffering matches uart-rx.v module interface (no built-in FIFO)
- FIFO adds RTL complexity and resource usage
- Scope prioritizes minimalism for initial RX support

### Decision
Use single-byte latch. If another byte arrives before software reads, it will be lost (overrun).

### Consequences
- **Positive:** Minimal RTL overhead (~9 flip-flops)
- **Positive:** Simple to implement and test
- **Negative:** Overrun possible if firmware is slow to read
- **Negative:** No buffering for bursty input (e.g., paste operations)
- **Mitigation:** Document limitation in hw-sw-contract.md
- **Future:** Add FIFO in later feature if needed (non-breaking addition)

---

## ADR-003: Register Map Reorganization

**Date:** 2026-07-07  
**Status:** Decided - Breaking Change  
**Decision:** Split single UART register into three distinct registers (TXDATA, RXDATA, STATUS).

### Context
Current design uses `0x1000_0000` for both:
- Write: transmit character
- Read: TX busy status

Adding RX requires a separate data register and status bits.

Options:
1. **Keep dual-purpose register:** Add RX data at new address, extend status bits
2. **Separate registers:** TXDATA (WO), RXDATA (RO), STATUS (RO)

### Decision Drivers
- Dual-purpose register is confusing and non-standard
- Separate registers improve clarity and follow industry practice (e.g., 16550 UART)
- Write-to-read semantics are error-prone in hardware
- Clean separation allows independent access patterns

### Decision
Reorganize into three registers at consecutive addresses.

### Consequences
- **Positive:** Clear, intuitive interface
- **Positive:** Future-proof for additional status bits or control registers
- **Positive:** Matches conventional UART register layouts
- **Negative:** **Breaking change** - old firmware will fail
- **Mitigation:** Update all firmware drivers in same PR
- **Mitigation:** Document migration in hw-sw-contract.md

### Register Layout

| Offset | Name | Access | Description |
|---|---|---|---|
| 0x00 | UART_TXDATA | WO | Write byte to transmit |
| 0x04 | UART_RXDATA | RO | Read received byte (clears RX_VALID) |
| 0x08 | UART_STATUS | RO | Status bits (TX_IDLE, RX_VALID) |

---

## ADR-004: UART_RXDATA Read Side Effect

**Date:** 2026-07-07  
**Status:** Decided  
**Decision:** Reading UART_RXDATA clears the RX_VALID flag.

### Context
When firmware reads received data, the hardware must signal that the byte has been consumed.

Options:
1. **Read clears flag:** Automatic acknowledgment on read
2. **Explicit clear:** Separate write to control register to acknowledge
3. **No clear:** Software must track consumption (flag never clears)

### Decision Drivers
- Read-clears-flag is standard UART behavior (e.g., 16550 RBR)
- Simplifies software (no extra acknowledge step)
- Hardware implementation is straightforward (detect read transaction)

### Decision
Reading UART_RXDATA automatically clears RX_VALID.

### Consequences
- **Positive:** Intuitive API for firmware developers
- **Positive:** Matches industry-standard UART behavior
- **Negative:** Non-idempotent read (second read returns stale data)
- **Mitigation:** Document in hw-sw-contract.md: "Reading UART_RXDATA is a destructive operation"

---

## ADR-005: .data Section Initialization Placement

**Date:** 2026-07-07  
**Status:** Decided  
**Decision:** Perform .data copy before .bss clear in start.S.

### Context
C runtime initialization requires two steps:
1. Copy initialized data from ROM (LMA) to RAM (VMA)
2. Zero-initialize .bss section

Order matters if there are dependencies.

### Decision Drivers
- Standard practice: .data copy first, then .bss clear
- .bss clear is simpler (no LMA lookup), should come second
- Logical flow: "set up initialized data, then clear uninitialized data"

### Decision
Sequence in start.S: stack setup → .data copy → .bss clear → call main.

### Consequences
- **Positive:** Follows standard C runtime initialization pattern
- **Positive:** Ensures globals are correctly initialized before main()
- **Negative:** Increases boot time slightly (~microseconds for small .data)
- **Mitigation:** None needed, performance impact negligible

---

## ADR-006: Verilator Input Injection Strategy

**Date:** 2026-07-07  
**Status:** Decided  
**Decision:** Implement UART RX serial protocol simulation in C++ testbench.

### Context
Verilator needs to inject character 'h' into uart_rxd pin for automated testing.

Options:
1. **Bit-bang UART protocol:** Simulate start/data/stop bits at correct timing
2. **Direct inject:** Drive uart_rx_data_wire directly (bypass protocol)
3. **External tool:** Use separate UART simulator (e.g., Python script)

### Decision Drivers
- Bit-banging validates full RTL path (realistic test)
- Direct injection bypasses uart-rx.v module (less coverage)
- External tool adds dependency and complexity
- Bit timing calculation is straightforward: 27MHz / 115200 baud

### Decision
Implement UART serial protocol in sim_main.cpp: start bit + 8 data bits + stop bit.

### Consequences
- **Positive:** Full end-to-end RTL validation
- **Positive:** Self-contained test (no external dependencies)
- **Positive:** Realistic simulation of physical UART behavior
- **Negative:** More complex C++ testbench code (~50 lines)
- **Negative:** Timing-sensitive (requires accurate cycle counting)
- **Mitigation:** Use well-tested timing formula: cycles_per_bit = CLK_HZ / BAUD_RATE

---

## ADR-007: QEMU vs Verilator Driver Unification

**Date:** 2026-07-07  
**Status:** Decided  
**Decision:** Maintain separate UART drivers (uart_tang_simple.c for Verilator/FPGA, uart_qemu_16550.c for QEMU).

### Context
QEMU uses 16550 UART model with different register layout than custom RTL.

Options:
1. **Unified driver:** Abstract layer that adapts to both models
2. **Separate drivers:** Conditional compilation selects appropriate driver

### Decision Drivers
- Register layouts are fundamentally different (16550 vs custom)
- Abstraction layer adds complexity without significant benefit
- Conditional compilation is already used in firmware build system
- Each driver is ~50 lines (duplication cost is low)

### Decision
Keep separate drivers, selected by TARGET build variable.

### Consequences
- **Positive:** Each driver is simple and focused
- **Positive:** No runtime overhead from abstraction layer
- **Negative:** API changes must be applied to both drivers
- **Mitigation:** Use shared uart.h header to enforce API consistency
- **Mitigation:** Document synchronization requirement in dev prompts

---

## ADR-008: Error Detection and Handling

**Date:** 2026-07-07  
**Status:** Deferred  
**Decision:** Defer UART error detection (framing, parity, overrun) to future feature.

### Context
uart-rx.v module provides uart_rx_break signal. Additional errors (framing, parity, overrun) could be implemented.

### Decision Drivers
- Feature scope focuses on basic RX functionality
- Interactive console has low error rate (short cables, controlled environment)
- Error handling adds complexity to firmware and RTL
- Can be added non-destructively in future (expand STATUS register)

### Decision
Implement "happy path" only. Ignore errors in this iteration.

### Consequences
- **Positive:** Faster implementation, simpler design
- **Positive:** Adequate for development/debug use case
- **Negative:** Production systems may need error handling
- **Mitigation:** Document limitation in hw-sw-contract.md
- **Future:** Add error status bits when reliability requirements increase

---

## Decision Summary Table

| ADR | Topic | Decision | Breaking? |
|---|---|---|---|
| ADR-001 | RX Mode | Polling (not interrupt-driven) | No |
| ADR-002 | Buffering | Single-byte latch (not FIFO) | No |
| ADR-003 | Register Map | 3 separate registers | **Yes** |
| ADR-004 | RX Read | Clears RX_VALID flag | No |
| ADR-005 | Init Order | .data copy before .bss clear | No |
| ADR-006 | Test Input | Bit-bang UART protocol | No |
| ADR-007 | Driver | Separate QEMU/Verilator drivers | No |
| ADR-008 | Errors | Defer error detection | No |

---

## Change History

- 2026-07-07: Initial decision log created (ADR-001 through ADR-008)
