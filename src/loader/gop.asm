; GOP preferred framebuffer information
%define PreferredHorizontalResolution   2560
%define PreferredVerticalResolution     1440
%define PreferredPixelFormat            1


setup_gop:
    ;----------------------------------------------------------------------------------------------------
    ; Locate Graphics Output Protocol
    ;----------------------------------------------------------------------------------------------------
    lea rcx, [efi_graphics_output_protocol_guid]
    xor edx, edx                                                    ; second argument is NULL
    lea r8, [GraphicsOutputProtocol]

    ; 32 bytes of shadow space + 8 bytes for the return address
    ; stack must be 16 byte aligned
    sub rsp, 40                                         
    call [LocateProtocol]
    add rsp, 40

    test rax, rax                                                   ; EFI_SUCCESS = 0
    jnz gop_not_found

    ;----------------------------------------------------------------------------------------------------
    ; Get GOP MaxMode
    ;----------------------------------------------------------------------------------------------------
    mov r12, [GraphicsOutputProtocol]
    mov r13, [r12 + 24]
    mov [GraphicsOutputProtocolMode], r13

    mov r14d, [r13 + 0]
    mov [GraphicsOutputProtocolMaxMode], r14d

    ;----------------------------------------------------------------------------------------------------
    ; Find The Preferred GOP Mode
    ;----------------------------------------------------------------------------------------------------
    mov r12, [GraphicsOutputProtocol]
    mov rax, [r12 + 0]
    mov [QueryMode], rax

    xor ebx, ebx                                                    ; mode number = 0
    mov r12d, [GraphicsOutputProtocolMaxMode]
    find_mode:
        cmp ebx, r12d
        jge no_matching_mode

        mov rcx, [GraphicsOutputProtocol]
        mov edx, ebx
        lea r8, [GraphicsOutputProtocolInformationSize]
        lea r9, [GraphicsOutputProtocolInformation]

        sub rsp, 40
        call [QueryMode]
        add rsp, 40

        test rax, rax                                               ; EFI_SUCCESS = 0
        jz check_info

        next_mode:
            inc ebx
            jmp find_mode  

        check_info:
            mov r13, [GraphicsOutputProtocolInformation]
            mov r14d, [r13 + 4]                                     ; horizontal resolution
            cmp r14d, PreferredHorizontalResolution                                       
            jne next_mode

            mov r13, [GraphicsOutputProtocolInformation]
            mov r14d, [r13 + 8]                                     ; vertical resolution
            cmp r14d, PreferredVerticalResolution
            jne next_mode

            mov r13, [GraphicsOutputProtocolInformation]
            mov r14d, [r13 + 12]                                    ; pixel format
            cmp r14d, PreferredPixelFormat                          ; BGRA
            jne next_mode

            ;----------------------------------------------------------------------------------------------------
            ; Set The Preferred GOP Mode
            ;----------------------------------------------------------------------------------------------------
            mov r12, [GraphicsOutputProtocol]
            mov rax, [r12 + 8]
            mov [SetMode], rax

            mov rcx, [GraphicsOutputProtocol]
            mov edx, ebx                                            ; mode number matching the preferred info

            sub rsp, 40
            call [SetMode]
            add rsp, 40

            test rax, rax                                           ; EFI_SUCCESS = 0
            jnz gop_not_found                                           

            ;----------------------------------------------------------------------------------------------------
            ; Save Framebuffer Info
            ;----------------------------------------------------------------------------------------------------
            mov r12, [GraphicsOutputProtocolMode]
            mov r13, [r12 + 24]
            mov [FramebufferBaseAddress], r13

            mov r12, [GraphicsOutputProtocolInformation]
            mov r13d, [r12 + 4]
            mov [HorizontalResolution], r13d

            mov r12, [GraphicsOutputProtocolInformation]
            mov r13d, [r12 + 8]
            mov [VerticalResolution], r13d

            mov r12, [GraphicsOutputProtocolInformation]
            mov r13d, [r12 + 12]
            mov [PixelFormat], r13d

            mov r13d, [r12 + 32]
            mov [PixelsPerScanLine], r13d 

            ret


