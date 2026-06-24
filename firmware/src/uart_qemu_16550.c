#include "uart.h"

#define UART_BASE 0x10000000u

#define UART_RBR 0x00u
#define UART_THR 0x00u
#define UART_LSR 0x05u

#define UART_LSR_RX_READY 0x01u
#define UART_LSR_TX_EMPTY 0x20u

static inline uint8_t mmio_read8(uint32_t addr)
{
    return *(volatile uint8_t *)addr;
}

static inline void mmio_write8(uint32_t addr, uint8_t value)
{
    *(volatile uint8_t *)addr = value;
}

void uart_init(void)
{
    /*
     * QEMU virt's 16550 UART is already initialized enough for early output.
     */
}

void uart_putc(char c)
{
    if(c == '\n') {
        uart_putc('\r');
    }

    while((mmio_read8(UART_BASE + UART_LSR) & UART_LSR_TX_EMPTY) == 0) {
    }

    mmio_write8(UART_BASE + UART_THR, (uint8_t)c);
}

void uart_puts(const char *s)
{
    while(*s) {
        uart_putc(*s++);
    }
}