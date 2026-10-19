setup_gdt:
    lea rsp, [stack_top]                                            ; new stack for the kernel

    lea r12, [gdt_start]
    mov [gdt_base_address], r12

    lgdt [gdt_field]

    mov ax, 16                                                      ; kernel data segment offset in GDT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Copy the embedded kernel to physical address 0x00100000
    lea rsi, [kernel_bin_start]
    mov rdi, 0xFFFFFF8000200000
    mov rcx, (kernel_bin_end - kernel_bin_start)
    rep movsb

    push 8                                                          ; kernel code segment offset in GDT
    mov r12, 0xFFFFFF8000200000                                     ; kernel entry point
    push r12                                                        

    retfq                                                           ; jump to kernel
    
    ret