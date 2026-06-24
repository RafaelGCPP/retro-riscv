#include <stdint.h>
#include "uart.h"

#define UART_BASE 0x10000000u

#define UART_STATUS (*(volatile uint32_t *)(UART_BASE + 0x00u))
#define UART_TX     (*(volatile uint32_t *)(UART_BASE + 0x00u))

#define UART_TX_IDLE 0x01u

void uart_init(void)
{
}

void uart_putc(char c)
{
    if (c == '\n') {
        uart_putc('\r');
    }

    while ((UART_STATUS & UART_TX_IDLE) == 0) {
    }

    UART_TX = (uint32_t)(uint8_t)c;
}

void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s++);
    }
}