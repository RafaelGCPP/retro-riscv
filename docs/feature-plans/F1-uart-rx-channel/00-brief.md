# Feature F1 - UART RX Channel: Technical Brief

## Executive Summary
Enable bidirectional UART communication by implementing the receive (RX) channel, allowing firmware to read user input from the serial console. This is a critical P0 feature required before developing the monitor functionality and DDR3 support.

## Business Goal Alignment
Currently, the system can only transmit data via UART TX. Without RX capability, user interaction is impossible, blocking:
- Interactive monitor/debugger development
- Memory inspection and manipulation tools
- Command-line interface for development/testing

## Strict Scope Boundaries

### In Scope
1. **Hardware (RTL):**
   - Wire existing `uart-rx.v` module into `top.sv`
   - Implement new 3-register MMIO interface (TXDATA, RXDATA, STATUS)
   - Update address decoding logic for new register map

2. **Firmware:**
   - Fix `.data` section initialization in `start.S` (copy from ROM to RAM)
   - Implement UART RX driver functions (getc, rx_available, etc.)
   - Conditional compilation for QEMU vs Verilator/FPGA targets
   - Update main.c to demonstrate interactive input

3. **Verification:**
   - Verilator simulation test with interactive input
   - QEMU firmware validation
   - Acceptance test: wait for 'h' key, echo, print "alive"

4. **Documentation:**
   - Update `hw-sw-contract.md` with new register map
   - Update `current-architecture.md` with RX data flow
   - Update `repository-map.md` if file structure changes

### Out of Scope
- Full assembly monitor implementation (future feature)
- DDR3 support (separate feature)
- FPGA synthesis automation in dev container
- Interrupt-driven UART (polling only in this iteration)
- UART error detection/handling (framing, parity, overrun)
- Multi-byte buffering (single-character buffering only)

## Hardware-Software Contract Impact

### Critical Change: UART Register Reorganization
Current state uses a single register at `0x1000_0000` with dual semantics:
- **Write:** Transmit character
- **Read:** TX busy status

New design separates concerns into 3 distinct registers:
- **UART_TXDATA** (`0x1000_0000`): Write-only TX data register
- **UART_RXDATA** (`0x1000_0004`): Read-only RX data register  
- **UART_STATUS** (`0x1000_0008`): Read-only status register

This is a **breaking change** requiring firmware driver updates.

## Target Platforms
- ✅ QEMU (firmware validation, uses 16550 model)
- ✅ Verilator (full RTL+firmware integration test)
- ✅ GoWin FPGA (Tang Primer 20K Dock - manual synthesis)

## Success Criteria
1. Verilator simulation accepts keyboard input and echoes it
2. QEMU firmware displays banner, waits for 'h' key press
3. Upon receiving 'h', firmware echoes "h\nalive\n"
4. All three targets (QEMU, Verilator, FPGA-ready) exhibit identical behavior
5. Architecture documentation updated and synchronized
