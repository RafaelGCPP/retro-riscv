ENTRY(_start)

MEMORY
{
    rom  (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    sram (rwx) : ORIGIN = 0x00010000, LENGTH = 8K
    ddr  (rwx) : ORIGIN = 0x20000000, LENGTH = 16M
}

SECTIONS
{
    . = ORIGIN(rom);

    .text : ALIGN(4)
    {
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
    } > rom

    .data : ALIGN(4)
    {
        __data_start = .;
        *(.data*)
        __data_end = .;
    } > sram AT > rom

    .bss : ALIGN(4)
    {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > sram

    . = ALIGN(16);
    __stack_top = ORIGIN(sram) + LENGTH(sram);

    __ddr_start = ORIGIN(ddr);
    __ddr_size  = LENGTH(ddr);
    __ddr_end   = ORIGIN(ddr) + LENGTH(ddr);
}