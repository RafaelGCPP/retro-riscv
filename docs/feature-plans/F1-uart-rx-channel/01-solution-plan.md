# F1 - UART RX Channel: Technical Solution Architecture

## 1. Hardware Architecture

### 1.1 UART RX Module Integration

**Existing Asset:** `verilog/uart-rx.v`

The UART RX module is already present in the codebase with the following interface:

```systemverilog
module uart_rx(
    input  wire       clk,
    input  wire       resetn,
    input  wire       uart_rxd,        // Physical RX pin
    input  wire       uart_rx_en,      // Enable signal
    output wire       uart_rx_break,   // BREAK detection
    output wire       uart_rx_valid,   // Valid data pulse
    output reg  [7:0] uart_rx_data     // Received byte
);
```

**Integration Requirements:**
- Instantiate in `top.sv` alongside existing `uart_tx` instance
- Configure parameters: `CLK_HZ=FREQ`, `BIT_RATE=115200`, `PAYLOAD_BITS=8`
- Add `uart_rxd` input pin to top-level module
- Create single-byte latch register to hold received data

### 1.2 New MMIO Register Map

**Breaking Change:** Replace single-register UART interface with three distinct registers.

| Register Name | Address | Width | Access | Description |
|---|---|---|---|---|
| UART_TXDATA | 0x1000_0000 | 32-bit | WO | TX Data - write byte to transmit |
| UART_RXDATA | 0x1000_0004 | 32-bit | RO | RX Data - read last received byte |
| UART_STATUS | 0x1000_0008 | 32-bit | RO | Status register (TX/RX flags) |

### 1.3 UART_STATUS Register Bitmap

```
Bit 31:2 - Reserved (read as 0)
Bit 1    - RX_VALID: 1 = received byte available in RXDATA
Bit 0    - TX_IDLE:  1 = transmitter ready for new byte
```

**Behavior Specification:**

- **UART_TXDATA (0x1000_0000):**
  - **Write:** Loads `mem_wdata[7:0]` into TX FIFO when `TX_IDLE=1`
  - **Read:** Returns `0x0000_0000` (undefined, discouraged)
  
- **UART_RXDATA (0x1000_0004):**
  - **Write:** No effect (discard)
  - **Read:** Returns last latched RX byte in `[7:0]`, upper bits zero
  - **Side Effect:** Reading this register **clears** `RX_VALID` flag
  
- **UART_STATUS (0x1000_0008):**
  - **Write:** No effect (discard)
  - **Read:** Returns status bitmap as defined above
  - **Side Effect:** None (non-destructive read)

### 1.4 RTL Implementation Strategy

**File:** `verilog/top.sv`

**Changes Required:**

1. **Add RX pin to module interface:**
   ```systemverilog
   module top (
       input  logic clk27mhz,
       input  logic uart_rxd,      // NEW
       output logic uart_txd
   );
   ```

2. **Instantiate UART RX module:**
   ```systemverilog
   logic       uart_rx_valid;
   logic [7:0] uart_rx_data_wire;
   logic [7:0] uart_rx_data_reg;  // Latched RX byte
   logic       uart_rx_valid_reg; // Latched valid flag
   
   uart_rx #(
       .CLK_HZ       (FREQ),
       .BIT_RATE     (115_200),
       .PAYLOAD_BITS (8)
   ) uart_rx_inst (
       .clk          (clk),
       .resetn       (resetn),
       .uart_rxd     (uart_rxd),
       .uart_rx_en   (1'b1),           // Always enabled
       .uart_rx_break(),               // Unused for now
       .uart_rx_valid(uart_rx_valid),
       .uart_rx_data (uart_rx_data_wire)
   );
   ```

3. **Add RX data latch logic:**
   ```systemverilog
   always_ff @(posedge clk) begin
       if (!resetn) begin
           uart_rx_data_reg  <= 8'h00;
           uart_rx_valid_reg <= 1'b0;
       end else begin
           if (uart_rx_valid) begin
               uart_rx_data_reg  <= uart_rx_data_wire;
               uart_rx_valid_reg <= 1'b1;
           end else if (uart_rxdata_read) begin
               uart_rx_valid_reg <= 1'b0; // Clear on read
           end
       end
   end
   ```

4. **Update address decode logic:**
   ```systemverilog
   localparam logic [31:0] UART_TXDATA_ADDR = 32'h1000_0000;
   localparam logic [31:0] UART_RXDATA_ADDR = 32'h1000_0004;
   localparam logic [31:0] UART_STATUS_ADDR = 32'h1000_0008;
   
   logic uart_txdata_select, uart_rxdata_select, uart_status_select;
   logic uart_rxdata_read;
   
   assign uart_txdata_select = mem_valid && (mem_addr == UART_TXDATA_ADDR);
   assign uart_rxdata_select = mem_valid && (mem_addr == UART_RXDATA_ADDR);
   assign uart_status_select = mem_valid && (mem_addr == UART_STATUS_ADDR);
   
   assign uart_rxdata_read = uart_rxdata_select && (mem_wstrb == 4'b0000);
   ```

5. **Update memory response mux:**
   ```systemverilog
   always_comb begin
       mem_ready = 1'b0;
       mem_rdata = 32'h0000_0000;
       
       if (mem_valid) begin
           if (uart_txdata_select) begin
               mem_ready = (mem_wstrb == 4'b0000) ? 1'b1 : uart_idle;
               mem_rdata = 32'h0000_0000; // Reads return 0
           end else if (uart_rxdata_select) begin
               mem_ready = 1'b1;
               mem_rdata = {24'b0, uart_rx_data_reg};
           end else if (uart_status_select) begin
               mem_ready = 1'b1;
               mem_rdata = {30'b0, uart_rx_valid_reg, uart_idle};
           end
           // ... existing ROM/RAM/sim_exit logic ...
       end
   end
   ```

### 1.5 QEMU vs Verilator Abstraction

**QEMU Path:**
- Uses existing 16550-compatible UART model
- Firmware driver in `uart_qemu_16550.c` must be updated to use new register map paradigm
- QEMU does not use `top.sv`, only firmware/linker script

**Verilator/FPGA Path:**
- Uses `uart-rx.v` + `uart-tx.v` modules wired in `top.sv`
- Firmware driver in `uart_tang_simple.c` updated to new register map
- Both targets share same RTL

---

## 2. Firmware Architecture

### 2.1 Critical Fix: `.data` Section Initialization

**Problem:** Currently, `start.S` only clears `.bss` but does not copy `.data` from ROM to RAM.

**Impact:** Any initialized global variables will have incorrect values at runtime.

**Solution:** Add data section copy routine in `start.S`:

```assembly
.section .text.start
.global _start

_start:
    la sp, __stack_top

    /*
     * Copy .data section from ROM (LMA) to RAM (VMA)
     */
    la t0, __data_start      # VMA (destination in RAM)
    la t1, __data_end        # VMA end
    la t2, __data_lma_start  # LMA (source in ROM)

copy_data:
    bgeu t0, t1, data_done
    lw t3, 0(t2)
    sw t3, 0(t0)
    addi t0, t0, 4
    addi t2, t2, 4
    j copy_data

data_done:
    /*
     * Clear .bss
     */
    la t0, __bss_start
    la t1, __bss_end

clear_bss:
    bgeu t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss

bss_done:
    call main

hang:
    j hang
```

**Linker Script Update:** `firmware/linker/tang20k.ld`

Add `__data_lma_start` symbol:

```ld
.data : ALIGN(4)
{
    __data_start = .;
    *(.data*)
    __data_end = .;
} > sram AT > rom

__data_lma_start = LOADADDR(.data);
```

### 2.2 Firmware Driver API Extension

**File:** `firmware/src/uart.h`

```c
#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <stdbool.h>

void uart_init(void);
void uart_putc(char c);
void uart_puts(const char *s);

// NEW FUNCTIONS:
bool uart_rx_available(void);  // Returns true if RX byte ready
char uart_getc(void);          // Blocking read (waits for char)
char uart_getc_nowait(void);   // Non-blocking read (returns 0 if none)

#endif
```

### 2.3 Target-Specific Driver Implementation

**File:** `firmware/src/uart_tang_simple.c` (Verilator/FPGA)

```c
#include <stdint.h>
#include <stdbool.h>
#include "uart.h"

#define UART_BASE 0x10000000u

#define UART_TXDATA  (*(volatile uint32_t *)(UART_BASE + 0x00u))
#define UART_RXDATA  (*(volatile uint32_t *)(UART_BASE + 0x04u))
#define UART_STATUS  (*(volatile uint32_t *)(UART_BASE + 0x08u))

#define UART_STATUS_TX_IDLE  0x01u
#define UART_STATUS_RX_VALID 0x02u

void uart_init(void) {
    // No initialization needed for simple UART
}

void uart_putc(char c) {
    if (c == '\n') {
        uart_putc('\r');
    }
    while ((UART_STATUS & UART_STATUS_TX_IDLE) == 0) {
        // Wait for TX ready
    }
    UART_TXDATA = (uint32_t)(uint8_t)c;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

bool uart_rx_available(void) {
    return (UART_STATUS & UART_STATUS_RX_VALID) != 0;
}

char uart_getc_nowait(void) {
    if (!uart_rx_available()) {
        return '\0';
    }
    return (char)(UART_RXDATA & 0xFFu);
}

char uart_getc(void) {
    while (!uart_rx_available()) {
        // Busy wait
    }
    return (char)(UART_RXDATA & 0xFFu);
}
```

**File:** `firmware/src/uart_qemu_16550.c` (QEMU target)

Update to mirror same API but using 16550 register layout.

### 2.4 Acceptance Test Implementation

**File:** `firmware/src/main.c`

```c
#include "uart.h"

#ifdef VERILATOR
#define HEARTBEAT_COUNT 1000u
#define simulation_exit(n) do { \
    *(volatile uint32_t *)0x100000fcu = (uint32_t)(n); \
} while(0)
#else 
#define HEARTBEAT_COUNT 10000000u
#define simulation_exit(n) do { (void)(n); } while(0)
#endif

int main(void) {
    uart_init();

    uart_puts("\n");
    uart_puts("Tang 20K RV32 BIOS\n");
    uart_puts("UART RX enabled. Press 'h' for help.\n");
    uart_puts("> ");

    // Wait for 'h' key
    while (1) {
        if (uart_rx_available()) {
            char c = uart_getc();
            
            // Echo the character
            uart_putc(c);
            uart_putc('\n');
            
            if (c == 'h' || c == 'H') {
                uart_puts("alive\n");
                simulation_exit(0);
                break;
            }
        }
    }

    return 0;
}
```

---

## 3. Verification Strategy

### 3.1 Verilator Simulation Test

**Enhancement:** Update `verilator/sim_main.cpp` to inject simulated keyboard input.

**Test Scenario:**
1. Simulation starts, firmware prints banner
2. Test harness injects character 'h' via `uart_rxd` pin
3. Firmware echoes 'h' and prints "alive"
4. Simulation exits with success code

### 3.2 QEMU Validation

**Test Scenario:**
1. Run `make qemu`
2. User types 'h' on terminal
3. Firmware echoes and prints "alive"
4. Validates firmware-only path without RTL

### 3.3 FPGA Readiness

- Ensure RTL synthesizes without errors in GoWin
- Constrain `uart_rxd` pin in `gowin/retro-riscv.cst`
- Manual validation on physical hardware

---

## 4. Memory and Performance Constraints

### 4.1 Memory Overhead
- RX data latch: +1 byte register in RTL
- RX valid flag: +1 bit register in RTL
- Firmware code growth: ~50 bytes for RX functions

### 4.2 Timing Analysis
- No change to critical path (UART operates at 115200 baud)
- RX valid flag synchronization already handled in `uart-rx.v`

---

## 5. Backward Compatibility

**Breaking Changes:**
- Old firmware code reading UART TX register for status will fail
- Must update all firmware drivers before merging

**Migration Path:**
1. Update firmware drivers first
2. Update RTL second
3. Update documentation last
4. Test all three targets before final merge

---

## 6. Future Evolution Hooks

This design prepares for:
- Interrupt-driven UART (add IRQ wire from uart_rx_valid to CPU)
- Multi-byte FIFO buffering (replace single latch with FIFO)
- Error detection (expose break/framing errors in status register)
