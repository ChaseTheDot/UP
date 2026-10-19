OUTPUT_FORMAT(elf64-x86-64)
ENTRY(kernel_start)

SECTIONS
{
    . = 0xFFFFFF8000200000;     /*higher half kernel*/

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}