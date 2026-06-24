#include "uart.h"

#ifndef HEARTBEAT_COUNT
#define HEARTBEAT_COUNT 10000000u
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
    uart_puts("Build target running.\n");

    uart_puts("Test hex: 0x");
    print_hex32(0x1234abcd);
    uart_puts("\n");

    while(1) {
        uart_puts("> ");

        /*
         * Por enquanto só um heartbeat bobo.
         * Depois colocamos getchar(), parser e comandos.
         */
        for(volatile uint32_t i = 0; i < HEARTBEAT_COUNT; ++i) {
        }

        uart_puts("alive\n");
    }

    return 0;
}