; GOP preferred framebuffer information
%define PreferredHorizontalResolution   2560
%define PreferredVerticalResolution     1440
%define PreferredPixelFormat            1


setup_gop:
    ;----------------------------------------------------------------------------------------------------
    ; Locate Graphics Output Protocol
    ;----------------------------------------------------------------------------------------------------
    lea rcx, [rel efi_graphics_output_protocol_guid]
    xor edx, edx                                                    ; second argument is NULL
    lea r8, [rel GraphicsOutputProtocolPtr]

    ; 32 bytes of shadow space + 8 bytes for the return address
    ; stack must be 16 byte aligned
    sub rsp, 40                                         
    mov rax, [rel LocateProtocolPtr]
    call rax
    add rsp, 40

    test rax, rax                                                   ; EFI_SUCCESS = 0
    jnz gop_not_found

    ;----------------------------------------------------------------------------------------------------
    ; Get GOP MaxMode
    ;----------------------------------------------------------------------------------------------------
    mov rbx, [rel GraphicsOutputProtocolPtr]
    mov [rel GraphicsOutputProtocol], rbx

    mov rbx, [rbx + 24]
    mov [rel GraphicsOutputProtocolModePtr], rbx

    mov [GraphicsOutputProtocolMode], rbx

    mov ebx, [rbx + 0]
    mov [rel GraphicsOutputProtocolMaxMode], ebx

    ;----------------------------------------------------------------------------------------------------
    ; Find The Preferred GOP Mode
    ;----------------------------------------------------------------------------------------------------
    mov rbx, [rel GraphicsOutputProtocol]
    mov rbx, [rbx + 0]
    mov [rel QueryModePtr], rbx

    xor r12d, r12d                                                  ; mode number = 0
    mov r13d, [rel GraphicsOutputProtocolMaxMode]
    find_mode:
        cmp r12d, r13d
        jge no_matching_mode

        mov rcx, [rel GraphicsOutputProtocolPtr]
        mov edx, r12d
        lea r8, [rel GraphicsOutputProtocolInformationSizePtr]
        lea r9, [rel GraphicsOutputProtocolInformationPtr]

        sub rsp, 40
        mov rax, [rel QueryModePtr]
        call rax
        add rsp, 40

        test rax, rax                                               ; EFI_SUCCESS = 0
        jz check_info

        next_mode:
            inc r12d
            jmp find_mode  

        check_info:
            mov rbx, [rel GraphicsOutputProtocolInformationPtr]
            mov [rel GraphicsOutputProtocolInformation], rbx

            mov rbx, [rel GraphicsOutputProtocolInformation]
            mov ebx, [rbx + 4]
            mov [rel HorizontalResolution], ebx
            mov r14d, PreferredHorizontalResolution
            cmp r14d, [rel HorizontalResolution]
            jne next_mode

            mov rbx, [rel GraphicsOutputProtocolInformation]
            mov ebx, [rbx + 8]
            mov [rel VerticalResolution], ebx
            mov r14d, PreferredVerticalResolution
            cmp r14d, [rel VerticalResolution]
            jne next_mode

            mov rbx, [rel GraphicsOutputProtocolInformation]
            mov ebx, [rbx + 12]
            mov [rel PixelFormat], ebx
            mov r14d, PreferredPixelFormat                              ; BGRA
            cmp r14d, [rel PixelFormat]
            jne next_mode

            ;----------------------------------------------------------------------------------------------------
            ; Set The Preferred GOP Mode
            ;----------------------------------------------------------------------------------------------------
            mov rbx, [GraphicsOutputProtocol]
            mov rbx, [rbx + 8]
            mov [rel SetModePtr], rbx

            mov rcx, [rel GraphicsOutputProtocolPtr]
            mov edx, r12d                                               ; mode number matching the preferred info

            sub rsp, 40
            mov rax, [rel SetModePtr]
            call rax
            add rsp, 40

            test rax, rax                                               ; EFI_SUCCESS = 0
            jnz gop_not_found                                           

            ;----------------------------------------------------------------------------------------------------
            ; Save Framebuffer Info
            ;----------------------------------------------------------------------------------------------------
            mov rbx, [rel GraphicsOutputProtocolMode]
            mov rbx, [rbx + 24]
            mov [rel FramebufferBaseAddress], rbx

            mov rbx, [rel GraphicsOutputProtocolInformation]
            mov ebx, [rbx + 32]
            mov [rel PixelsPerScanLine], ebx 

            ret


