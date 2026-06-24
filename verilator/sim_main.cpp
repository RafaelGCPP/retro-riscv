#include "Vtop.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vtop top;

    // O reset é interno ao top.sv: reset_cnt segura resetn=0 por 255 ciclos.
    // Cada iteração abaixo gera um ciclo completo de clock.
    const vluint64_t max_cycles = 50000000;

    top.clk = 0;
    top.eval();

    for (vluint64_t cycle = 0; cycle < max_cycles && !Verilated::gotFinish(); ++cycle) {
        top.clk = 0;
        top.eval();

        top.clk = 1;
        top.eval();
    }

    top.final();
    return 0;
}
