ENTRY(boot)
SECTIONS {
    . = 0x7c00;
    .text :
    {
        *(.boot)
        *(.text)
    }
    .rodata : 
    {
        *(.rodata)
        *(.rdata*)
    }
    .data : 
    {
        *(.data)
    }
    .bss : 
    {
        *(.bss)
    }
}