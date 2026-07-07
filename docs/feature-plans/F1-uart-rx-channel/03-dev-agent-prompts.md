# F1 - UART RX Channel: Development Agent Prompts

This file contains precise, contextual prompts for software engineering agents to implement each dev story without hallucination or ambiguity.

---

## **Dev Story DS1: Fix .data Section Initialization**

### Prompt for Dev Agent DS1

```
Task: Update firmware startup code to correctly copy initialized global variables from ROM to RAM.

Context:
- The current start.S only clears .bss but does not copy .data section
- The linker places .data LMA (load address) in ROM and VMA (runtime address) in RAM
- Without this copy, initialized globals will have incorrect values

Files to modify:
1. firmware/src/start.S
2. firmware/linker/tang20k.ld
3. firmware/linker/qemu.ld

Instructions:

Step 1: Update firmware/src/start.S
- Add a new section BEFORE the bss_clear loop
- Load addresses: __data_start (VMA), __data_end (VMA), __data_lma_start (LMA)
- Loop: copy words from LMA to VMA until reaching __data_end
- Use registers t0, t1, t2, t3 for the copy loop
- Keep existing bss clear logic intact

Step 2: Update firmware/linker/tang20k.ld
- After the .data section definition, add:
  __data_lma_start = LOADADDR(.data);
- Ensure this comes AFTER the closing brace of the .data section

Step 3: Update firmware/linker/qemu.ld
- Apply the same change as Step 2

Validation:
- Run: make -C firmware clean && make -C firmware TARGET=tang20k
- Verify firmware builds without linker errors
- Run: make qemu
- Verify banner prints correctly (regression test)

Do not modify any other files. Do not add interrupt handlers or other features.
```

---

## **Dev Story DS2: Define UART Register Map**

### Prompt for Dev Agent DS2

```
Task: Reorganize UART MMIO interface in top.sv from single register to three separate registers.

Context:
- Current design uses 0x1000_0000 for both TX write and status read
- New design separates into:
  - UART_TXDATA: 0x1000_0000 (write-only)
  - UART_RXDATA: 0x1000_0004 (read-only, stub for now)
  - UART_STATUS: 0x1000_0008 (read-only)

File to modify:
- verilog/top.sv

Instructions:

Step 1: Update address decode constants
- Rename UART_TX_ADDR to UART_TXDATA_ADDR (keep value 0x1000_0000)
- Add UART_RXDATA_ADDR = 0x1000_0004
- Add UART_STATUS_ADDR = 0x1000_0008

Step 2: Add decode select signals
- Replace uart_select with three separate signals:
  - uart_txdata_select
  - uart_rxdata_select
  - uart_status_select

Step 3: Update memory response mux (always_comb block at end of file)
- Replace uart_select branch with three separate branches
- UART_TXDATA: write triggers uart_enable, read returns 0x00000000
- UART_RXDATA: always returns 0x00000000 (stub - RX not wired yet)
- UART_STATUS: returns {30'b0, 1'b0, uart_idle}  (bit 0 = TX_IDLE, bit 1 = RX_VALID stub)

Step 4: Preserve existing behavior
- UART TX write logic remains unchanged
- sim_exit_select logic remains unchanged

Validation:
- Run: make verilator
- Verify RTL compiles without errors
- Check that firmware can still print banner

Do not add UART RX module instantiation yet. Do not modify firmware files.
```

---

## **Dev Story DS3: Integrate UART RX Module**

### Prompt for Dev Agent DS3

```
Task: Wire uart-rx.v module into top.sv and implement RX data latch.

Context:
- UART RX module already exists in verilog/uart-rx.v
- Need to add uart_rxd input pin to top module
- Need single-byte latch for received data
- Reading UART_RXDATA should clear RX_VALID flag

File to modify:
- verilog/top.sv

Instructions:

Step 1: Add uart_rxd input to module interface
- Modify: module top ( ... )
- Add: input logic uart_rxd
- Place it next to uart_txd for clarity

Step 2: Declare internal RX signals (before module instantiations)
- logic uart_rx_valid;
- logic [7:0] uart_rx_data_wire;
- logic [7:0] uart_rx_data_reg;
- logic uart_rx_valid_reg;
- logic uart_rxdata_read;

Step 3: Instantiate uart_rx module (after uart_tx instantiation)
- Instance name: uart_rx_inst
- Parameters: CLK_HZ = FREQ, BIT_RATE = 115_200, PAYLOAD_BITS = 8
- Connections:
  - clk, resetn (standard)
  - uart_rxd (top-level input)
  - uart_rx_en = 1'b1 (always enabled)
  - uart_rx_break (leave unconnected)
  - uart_rx_valid, uart_rx_data (to internal wires)

Step 4: Add RX data latch logic (after uart_rx instantiation)
- always_ff @(posedge clk):
  - On !resetn: clear uart_rx_data_reg and uart_rx_valid_reg
  - On uart_rx_valid pulse: latch uart_rx_data_wire and set uart_rx_valid_reg
  - On uart_rxdata_read: clear uart_rx_valid_reg

Step 5: Update decode logic
- Define uart_rxdata_read = uart_rxdata_select && (mem_wstrb == 4'b0000)

Step 6: Update memory response mux
- UART_RXDATA branch: return {24'b0, uart_rx_data_reg}
- UART_STATUS branch: return {30'b0, uart_rx_valid_reg, uart_idle}

Validation:
- Run: make verilator
- Verify RTL compiles without errors
- Optional: inspect waveforms to verify uart_rx_valid_reg toggles

Do not modify firmware yet. Do not add interrupt logic.
```

---

## **Dev Story DS4: Implement UART RX Driver Functions**

### Prompt for Dev Agent DS4

```
Task: Extend firmware UART driver to support RX operations using new register map.

Context:
- New MMIO registers: UART_TXDATA (0x00), UART_RXDATA (0x04), UART_STATUS (0x08)
- UART_STATUS bit 0 = TX_IDLE, bit 1 = RX_VALID
- Need to add three new driver functions

Files to modify:
1. firmware/src/uart.h
2. firmware/src/uart_tang_simple.c
3. firmware/src/uart_qemu_16550.c

Instructions:

Step 1: Update firmware/src/uart.h
- Add #include <stdbool.h> after <stdint.h>
- Add three new function prototypes after uart_puts:
  - bool uart_rx_available(void);
  - char uart_getc(void);
  - char uart_getc_nowait(void);

Step 2: Update firmware/src/uart_tang_simple.c
- Replace UART_STATUS and UART_TX macros with:
  - UART_TXDATA  (*(volatile uint32_t *)(UART_BASE + 0x00u))
  - UART_RXDATA  (*(volatile uint32_t *)(UART_BASE + 0x04u))
  - UART_STATUS  (*(volatile uint32_t *)(UART_BASE + 0x08u))
- Add new constants:
  - #define UART_STATUS_TX_IDLE  0x01u
  - #define UART_STATUS_RX_VALID 0x02u
- Update uart_putc() to use UART_TXDATA for writes and UART_STATUS for polling
- Implement three new functions:
  - uart_rx_available(): return (UART_STATUS & UART_STATUS_RX_VALID) != 0
  - uart_getc_nowait(): if !available return '\0', else return (char)(UART_RXDATA & 0xFFu)
  - uart_getc(): busy-wait while !available, then return (char)(UART_RXDATA & 0xFFu)

Step 3: Update firmware/src/uart_qemu_16550.c
- Apply similar changes for QEMU's 16550 register layout
- Map new register map to 16550 equivalents:
  - UART_TXDATA -> THR (transmit holding register)
  - UART_RXDATA -> RBR (receive buffer register)
  - UART_STATUS -> LSR (line status register)
- Implement same three RX functions using 16550 semantics

Validation:
- Run: make -C firmware clean
- Run: make -C firmware TARGET=tang20k
- Run: make -C firmware TARGET=verilator
- Run: make -C firmware TARGET=qemu
- Verify all targets build without errors

Do not modify main.c yet. Do not add interrupt handling.
```

---

## **Dev Story DS5: Implement Acceptance Test**

### Prompt for Dev Agent DS5

```
Task: Update main.c to implement interactive UART RX test: wait for 'h', echo, print "alive".

Context:
- Firmware now has uart_rx_available() and uart_getc() functions
- Acceptance test: print banner, wait for 'h' key, echo it, print "alive", exit simulation
- Must work in QEMU (manual input) and Verilator (automated input)

File to modify:
- firmware/src/main.c

Instructions:

Step 1: Update banner text
- Change "Build target running." to "UART RX enabled. Press 'h' for help."

Step 2: Replace the while(1) heartbeat loop with interactive loop
- Print "> " prompt before loop
- Inside loop:
  - Check if (uart_rx_available())
  - Read character: char c = uart_getc();
  - Echo character: uart_putc(c); uart_putc('\n');
  - If (c == 'h' || c == 'H'):
    - uart_puts("alive\n");
    - simulation_exit(0);
    - break;
- Remove old heartbeat delay loop

Step 3: Ensure clean exit for Verilator
- simulation_exit(0) will trigger $finish in Verilator
- QEMU will ignore simulation_exit macro

Validation:
- Run: make qemu
  - Type 'h' on keyboard
  - Expect output: "h\nalive\n"
- Run: make verilator (after DS6 completes)
  - Expect automated test to pass

Do not modify UART driver files. Do not add command parsing logic beyond 'h' check.
```

---

## **Dev Story DS6: Enhance Verilator Test Harness**

### Prompt for Dev Agent DS6

```
Task: Update Verilator C++ testbench to inject UART RX input and validate firmware response.

Context:
- Firmware waits for 'h' character on UART RX
- Need to simulate UART serial protocol: start bit + 8 data bits + stop bit at 115200 baud
- Clock frequency in Verilator: 27 MHz

File to modify:
- verilator/sim_main.cpp

Instructions:

Step 1: Calculate bit timing
- UART baud rate: 115200 bps
- Bit period: 1/115200 = 8.68 µs
- Cycles per bit at 27 MHz: 27000000 / 115200 ≈ 234 cycles

Step 2: Add UART TX injection function (from testbench perspective, it's RX for DUT)
- Function: void inject_uart_char(char c, Vtop* top)
- Idle state: top->uart_rxd = 1 (mark)
- Start bit: top->uart_rxd = 0, wait 234 cycles
- Data bits: for each bit in c (LSB first), set uart_rxd, wait 234 cycles
- Stop bit: top->uart_rxd = 1, wait 234 cycles

Step 3: Inject 'h' character after banner detection
- Monitor simulation output for prompt "> "
- After detecting prompt, inject character 'h'
- Continue simulation for ~1000 more cycles to allow firmware to process

Step 4: Validate output
- Check simulation output contains "h" and "alive"
- If present, exit with success code 0
- If timeout (e.g., 1000000 cycles), exit with error code 1

Validation:
- Run: make verilator
- Verify simulation output shows:
  - Banner
  - Prompt "> "
  - Echoed "h"
  - "alive"
  - Clean exit code 0

Do not modify RTL files. Do not modify firmware files.
```

---

## **Dev Story DS7: Update Architecture Documentation**

### Prompt for Dev Agent DS7

```
Task: Synchronize architecture documentation with implemented UART RX feature.

Context:
- UART now has 3-register interface instead of 1-register
- .data section initialization is now mandatory
- UART RX module integrated into top.sv

Files to modify:
1. docs/architecture/hw-sw-contract.md
2. docs/architecture/current-architecture.md
3. docs/architecture/repository-map.md

Instructions:

Step 1: Update docs/architecture/hw-sw-contract.md
- Section 5 (MMIO Register Contract):
  - Replace "5.1 UART TX Data Register" with three subsections:
    - 5.1 UART_TXDATA Register (0x1000_0000)
    - 5.2 UART_RXDATA Register (0x1000_0004)
    - 5.3 UART_STATUS Register (0x1000_0008)
  - Document each register's:
    - Address, access mode (RO/WO), bit layout, side effects
    - UART_STATUS bitmap: bit 0 = TX_IDLE, bit 1 = RX_VALID
    - UART_RXDATA side effect: reading clears RX_VALID flag
- Section 4 (Memory Map table):
  - Update UART row to show address range 0x1000_0000 - 0x1000_0008
  - Update size to "12 bytes logical"

Step 2: Update docs/architecture/current-architecture.md
- Section 3.6 (UART Path):
  - Add RX module description
  - Document RX data flow: uart_rxd -> uart_rx module -> latch register -> MMIO read
  - Add note: "Single-byte buffering, polling mode only"
- Section 3.3 (Memory Map):
  - Update UART entry to show three registers
- Section 4.2 (Startup and Runtime Model):
  - Add bullet: ".data section copied from ROM to RAM during boot"

Step 3: Update docs/architecture/repository-map.md
- Section 3.2 (verilog/):
  - Update uart-rx.v description: "UART receiver peripheral logic (integrated in top.sv)"
- Section 3.3 (firmware/src/):
  - Add note: "start.S now initializes .data section before clearing .bss"

Validation:
- Cross-check all register addresses in docs match verilog/top.sv
- Verify memory map table is consistent across all three docs
- Check that side effects are clearly documented

Do not modify code files. Do not add speculative future features.
```

---

## General Agent Guidelines

For all dev stories:

1. **Strict Scope Adherence:** Only modify files explicitly listed in the prompt
2. **No Speculation:** Do not add features not described in the instructions
3. **Preserve Existing Behavior:** Regression tests must pass
4. **C23/SystemVerilog Best Practices:** Use modern language features
5. **UTF-8/LF:** All files must use UTF-8 encoding and LF line endings
6. **English Only:** All comments and documentation in English

## Error Handling Protocol

If an agent encounters ambiguity:

1. Flag the ambiguity in the implementation notes
2. Make the safest conservative choice that preserves existing functionality
3. Document the assumption made
4. Proceed with implementation

Do not block implementation on minor uncertainties.
