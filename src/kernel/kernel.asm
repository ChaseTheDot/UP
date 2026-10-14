bits 64
default rel
section .text

kernel_start:
    lea r12, [kernel_msg]
    call debug_print

    cli
    hlt
    jmp $

    %include "src/kernel/debug.asm"

section .data
    kernel_msg db "Kernel is loaded!", 10, 0
