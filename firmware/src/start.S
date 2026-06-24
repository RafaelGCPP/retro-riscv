.section .text.start
.global _start

_start:
    /*
     * Set stack pointer.
     */
    la sp, __stack_top

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