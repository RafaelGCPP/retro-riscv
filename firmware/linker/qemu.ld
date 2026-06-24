ENTRY(_start)

MEMORY
{
    ram (rwx) : ORIGIN = 0x80000000, LENGTH = 16M
}

SECTIONS
{
    . = ORIGIN(ram);

    .text : ALIGN(4)
    {
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
    } > ram

    .data : ALIGN(4)
    {
        __data_start = .;
        *(.data*)
        __data_end = .;
    } > ram

    .bss : ALIGN(4)
    {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > ram

    . = ALIGN(16);
    __stack_top = ORIGIN(ram) + LENGTH(ram);
}