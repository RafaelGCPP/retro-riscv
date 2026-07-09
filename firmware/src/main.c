#include "uart.h"

#ifdef VERILATOR
#define HEARTBEAT_COUNT 1000u
#define simulation_exit(n) do { *(volatile uint32_t *)0x100000fcu = (uint32_t)(n); } while(0)
#else 
#define HEARTBEAT_COUNT 10000000u
#define simulation_exit(n) do { (void)(n); } while(0)
#endif


static void print_hex32(uint32_t value)
{
    static const char hex[] = "0123456789abcdef";

    for(int i = 7; i >= 0; --i) {
        uint8_t nibble = (value >> (i * 4)) & 0x0f;
        uart_putc(hex[nibble]);
    }
}

int main(void)
{
    uart_init();

    uart_puts("\n");
    uart_puts("Tang 20K RV32 BIOS\n");
    uart_puts("UART RX enabled. Press 'h' for help.\n");

    uart_puts("Test hex: 0x");
    print_hex32(0x1234abcd);
    uart_puts("\n");

    uart_puts("> ");

    while(1) {
        if (uart_rx_available()) {
            char c = uart_getc();
            uart_putc(c);
            uart_putc('\n');
            
            if (c == 'h' || c == 'H') {
                uart_puts("alive\n");
                simulation_exit(0);
                //break;
            }
        }
    }

    return 0;
}