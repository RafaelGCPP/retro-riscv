#include "Vtop.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>

// UART bit timing: 27 MHz / 115200 baud ≈ 234 cycles per bit
static const unsigned int UART_CYCLES_PER_BIT = 234;

// Inject a character on UART RX line (start bit + 8 data bits LSB-first + stop bit)
static void inject_uart_char(char c, Vtop *top, vluint64_t &cycle, vluint64_t max_cycles) {
    // Idle state: RX line high (mark) - brief idle
    top->uart_rxd = 1;
    for (unsigned int i = 0; i < 50 && cycle < max_cycles; ++i) {
        top->clk27mhz = 0;
        top->eval();
        top->clk27mhz = 1;
        top->eval();
        cycle += 2;
    }

    // Start bit (low)
    top->uart_rxd = 0;
    for (unsigned int i = 0; i < UART_CYCLES_PER_BIT && cycle < max_cycles; ++i) {
        top->clk27mhz = 0;
        top->eval();
        top->clk27mhz = 1;
        top->eval();
        cycle += 2;
    }

    // Data bits (LSB first)
    for (int bit = 0; bit < 8; ++bit) {
        top->uart_rxd = (c >> bit) & 1;
        for (unsigned int i = 0; i < UART_CYCLES_PER_BIT && cycle < max_cycles; ++i) {
            top->clk27mhz = 0;
            top->eval();
            top->clk27mhz = 1;
            top->eval();
            cycle += 2;
        }
    }

    // Stop bit (high)
    top->uart_rxd = 1;
    for (unsigned int i = 0; i < UART_CYCLES_PER_BIT && cycle < max_cycles; ++i) {
        top->clk27mhz = 0;
        top->eval();
        top->clk27mhz = 1;
        top->eval();
        cycle += 2;
    }

    // Return to idle
    for (unsigned int i = 0; i < 50 && cycle < max_cycles; ++i) {
        top->clk27mhz = 0;
        top->eval();
        top->clk27mhz = 1;
        top->eval();
        cycle += 2;
    }
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vtop top;

    // Reset is internal to top.sv: reset_cnt holds resetn=0 for 255 cycles.
    // Each iteration below generates one complete clock cycle.
    const vluint64_t max_cycles = 1000000;

    top.clk27mhz = 0;
    top.uart_rxd = 1;  // RX idle high (mark)
    top.eval();

    // Phase 1: Run initial simulation to allow firmware boot and prompt printing
    // This allows the firmware to reach the point where it's waiting for input
    vluint64_t cycle = 0;
    for (; cycle < 500000 && !Verilated::gotFinish(); ++cycle) {
        top.clk27mhz = 0;
        top.eval();

        top.clk27mhz = 1;
        top.eval();
    }

    // Phase 2: Inject 'h' character via UART RX
    if (!Verilated::gotFinish()) {
        inject_uart_char('h', &top, cycle, max_cycles);
    }

    // Phase 3: Continue simulation to allow firmware to process input and respond
    for (; cycle < max_cycles && !Verilated::gotFinish(); ++cycle) {
        top.clk27mhz = 0;
        top.eval();

        top.clk27mhz = 1;
        top.eval();
    }

    top.final();

    // Exit code: 0 if Verilator simulation finished cleanly, 1 if timeout
    return Verilated::gotFinish() ? 0 : 1;
}
