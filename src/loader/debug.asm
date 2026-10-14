; mov dx, 0xE9
; mov al, 'A'
; out dx, al

global debug_print
debug_print:
    push rdx
    push rax

    print_loop:
            xor rbx, rbx
        next_character:
            mov al, [r12 + rbx]
            cmp al, 0
            je .done
            mov dx, 0xE9
            out dx, al

            inc rbx
            jmp next_character

    .done:
    pop rax
    pop rdx
    ret