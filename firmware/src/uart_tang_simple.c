#include <stdint.h>
#include <stdbool.h>
#include "uart.h"

#define UART_BASE 0x10000000u

#define UART_TXDATA  (*(volatile uint32_t *)(UART_BASE + 0x00u))
#define UART_RXDATA  (*(volatile uint32_t *)(UART_BASE + 0x04u))
#define UART_STATUS  (*(volatile uint32_t *)(UART_BASE + 0x08u))

#define UART_STATUS_TX_IDLE  0x01u
#define UART_STATUS_RX_VALID 0x02u

void uart_init(void)
{
}

void uart_putc(char c)
{
    if (c == '\n') {
        uart_putc('\r');
    }

    while ((UART_STATUS & UART_STATUS_TX_IDLE) == 0) {
    }

    UART_TXDATA = (uint32_t)(uint8_t)c;
}

bool uart_rx_available(void)
{
    return (UART_STATUS & UART_STATUS_RX_VALID) != 0;
}

char uart_getc_nowait(void)
{
    if (!uart_rx_available()) {
        return '\0';
    }
    return (char)(UART_RXDATA & 0xFFu);
}

char uart_getc(void)
{
    while (!uart_rx_available()) {
    }
    return (char)(UART_RXDATA & 0xFFu);
}

void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s++);
    }
}