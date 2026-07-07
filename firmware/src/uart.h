#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <stdbool.h>

void uart_init(void);
void uart_putc(char c);
void uart_puts(const char *s);
bool uart_rx_available(void);
char uart_getc(void);
char uart_getc_nowait(void);

#endif