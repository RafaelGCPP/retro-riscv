.section .text.start
.global _start

_start:
    /*
     * Set stack pointer.
     */
    la sp, __stack_top

    /*
     * Copy .data section from LMA to VMA
     */
    la t0, __data_start
    la t1, __data_end
    la t2, __data_lma_start

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