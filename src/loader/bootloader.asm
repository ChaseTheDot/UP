bits 64
default rel


;======================================================================================
; References
;======================================================================================

; DOS Header:
; https://medium.com/@trmz/the-image-dos-header-a-complete-deep-dive-afd882f36b66

; PE Header:
; https://learn.microsoft.com/en-us/windows/win32/debug/pe-format

; PE Format:
; https://blog.deephacking.tech/en/posts/anatomy-of-the-portable-executable-format/

; UEFI Specification:
; https://uefi.org/sites/default/files/resources/UEFI_Spec_2_10_Aug29.pdf

; x64 Calling Convention    
; https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-170
;======================================================================================


;======================================================================================
; PE CONSTANTS
;======================================================================================
%define DOSSignature                    0x5A4D
%define PESignature                     0x00004550

;--------------------------------------------------------------------------------------
; COFF/FILE Header
;--------------------------------------------------------------------------------------
%define MachineType                     0x8664
%define NumberOfSections                3
%define TimeDateStamp                   1790917236
%define PointerToSymbolTable            0
%define NumberOfSymbols                 0
%define SizeOfOptionalHeader            optional_header_end - optional_header_start
%define FileCharacteristics             0x0002

;--------------------------------------------------------------------------------------
; Optional Header
;--------------------------------------------------------------------------------------
%define OptionalHeaderMagic             0x20B
%define MajorLinkerVersion              0
%define MinorLinkerVersion              0
%define SizeOfCode                      code_section_end - code_section_start
%define SizeOfInitializedData           data_section_end - data_section_start
%define SizeOfUninitializedData         bss_section_end - bss_section_start
%define RelativeAddressOfEntryPoint     code_section_start - image_start 
%define RelativeBaseOfCode              code_section_start - image_start  
%define ImageBaseAddress                0x00040000
%define SectionAlignment                512
%define FileAlignment                   512
%define MajorOperatingSystemVersion     0
%define MinorOperatingSystemVersion     0
%define MajorImageVersion               0
%define MinorImageVersion               0
%define MajorSubsystemVersion           0
%define MinorSubsystemVersion           0
%define Win32VersionValue               0
%define SizeOfImage                     image_end - image_start     
%define SizeOfHeaders                   headers_end - headers_start   
%define CheckSum                        0
%define SubsystemType                   10
%define DllCharacteristics              0
%define SizeOfStackReserve              0x00010000
%define SizeOfStackCommit               0x00000100
%define SizeOfHeapReserve               0x00010000
%define SizeOfHeapCommit                0x00010000
%define LoaderFlags                     0
%define NumberOfRvaAndSizes             16 

;--------------------------------------------------------------------------------------
; Section Header
;--------------------------------------------------------------------------------------
%define CodeVirtualSize                 code_section_end - code_section_start
%define CodeVirtualAddress              code_section_start - image_start
%define CodeSizeOfRawData               code_section_end - code_section_start
%define CodePointerToRawData            code_section_start - image_start
%define CodePointerToRelocations        0
%define CodePointerToLinenumbers        0
%define CodeNumberOfRelocations         0
%define CodeNumberOfLinenumbers         0
%define CodeCharacteristics             0x60000020   

%define DataVirtualSize                 data_section_end - data_section_start
%define DataVirtualAddress              data_section_start - image_start
%define DataSizeOfRawData               data_section_end - data_section_start
%define DataPointerToRawData            data_section_start - image_start
%define DataPointerToRelocations        0
%define DataPointerToLinenumbers        0
%define DataNumberOfRelocations         0
%define DataNumberOfLinenumbers         0
%define DataCharacteristics             0xC0000040   

%define bssVirtualSize                  bss_section_end - bss_section_start
%define bssVirtualAddress               bss_section_start - image_start
%define bssSizeOfRawData                0
%define bssPointerToRawData             0
%define bssPointerToRelocations         0
%define bssPointerToLinenumbers         0
%define bssNumberOfRelocations          0
%define bssNumberOfLinenumbers          0
%define bssCharacteristics              0xC0000080
;======================================================================================


;======================================================================================
; BOOTLOADER CONSTANTS
;======================================================================================
;--------------------------------------------------------------------------------------
; GOP Preferred Framebuffer Information
;--------------------------------------------------------------------------------------
%define PreferredHorizontalResolution   2560
%define PreferredVerticalResolution     1440
%define PreferredPixelFormat            1
;======================================================================================


;======================================================================================
; PE HEADERS
;======================================================================================
;--------------------------------------------------------------------------------------
; DOS Header
;--------------------------------------------------------------------------------------
image_start:

headers_start:

dw DOSSignature
times 60 - ($ - image_start) db 0       ; zero unused DOS header fields
dd nt_header - image_start              ; e_lfanew

;--------------------------------------------------------------------------------------
; DOS STUB
;--------------------------------------------------------------------------------------
times 64 db 0                           ; unused DOS stub

;--------------------------------------------------------------------------------------
; NT Header
; |_ Signature
; |_ COFF/FILE Header
; |_ Optional Header
;--------------------------------------------------------------------------------------
nt_header:
; Signature
dd PESignature

; COFF/FILE Header
dw MachineType
dw NumberOfSections
dd TimeDateStamp
dd PointerToSymbolTable
dd NumberOfSymbols
dw SizeOfOptionalHeader
dw FileCharacteristics                  ; executable image

; Optional Header
optional_header_start:
dw OptionalHeaderMagic
db MajorLinkerVersion
db MinorLinkerVersion
dd SizeOfCode
dd SizeOfInitializedData
dd SizeOfUninitializedData
dd RelativeAddressOfEntryPoint          ; RVA of the instruction where execution starts
dd RelativeBaseOfCode                   ; RVA where the code section begins
dq ImageBaseAddress
dd SectionAlignment
dd FileAlignment
dw MajorOperatingSystemVersion
dw MinorOperatingSystemVersion
dw MajorImageVersion
dw MinorImageVersion
dw MajorSubsystemVersion
dw MinorSubsystemVersion
dd Win32VersionValue
dd SizeOfImage                          ; must be a multiple of SectionAlignment
dd SizeOfHeaders                        ; must be a multiple of FileAlignment 
dd CheckSum
dw SubsystemType
dw DllCharacteristics
dq SizeOfStackReserve
dq SizeOfStackCommit
dq SizeOfHeapReserve
dq SizeOfHeapCommit
dd LoaderFlags
dd NumberOfRvaAndSizes
times 16 dq 0
optional_header_end:

;--------------------------------------------------------------------------------------
; Section Header
;--------------------------------------------------------------------------------------
db ".text", 0, 0, 0
dd CodeVirtualSize
dd CodeVirtualAddress
dd CodeSizeOfRawData
dd CodePointerToRawData
dd CodePointerToRelocations
dd CodePointerToLinenumbers
dw CodeNumberOfRelocations
dw CodeNumberOfLinenumbers
dd CodeCharacteristics                  ; contains code + executable + readable

db ".data", 0, 0, 0
dd DataVirtualSize
dd DataVirtualAddress
dd DataSizeOfRawData
dd DataPointerToRawData
dd DataPointerToRelocations
dd DataPointerToLinenumbers
dw DataNumberOfRelocations
dw DataNumberOfLinenumbers
dd DataCharacteristics                  ; contains initialized data + writable + readable

db ".bss", 0, 0, 0, 0
dd bssVirtualSize
dd bssVirtualAddress
dd bssSizeOfRawData                     ; no raw data stored on disk
dd bssPointerToRawData
dd bssPointerToRelocations
dd bssPointerToLinenumbers
dw bssNumberOfRelocations
dw bssNumberOfLinenumbers
dd bssCharacteristics                   ; contains uninitialized data + writable + readable

times 512 - ($ - image_start) db 0      ; pad headers to FileAlignment
headers_end:
;======================================================================================


;======================================================================================
; PE SECTIONS
;======================================================================================
;--------------------------------------------------------------------------------------
; .text Section
;--------------------------------------------------------------------------------------
section .text
code_section_start:

    ; rax, rcx, rdx, r8, r9, r10 and r11 are used for passing arguments and return values
    ; rbx is specifically used for pointer dereferencing
    ; r12, R13 and r14 are used for general things

    mov [rel ImageHandle], rcx
    mov [rel SystemTable], rdx

    ; 4 byte padding right before ConsoleInHandle pointer on x64
    ; UEFI spec does not mention this padding for some reason
    ; So keep in mind, BootServices pointer is at offset 96 and NOT 92
    mov rbx, [rdx + 96]
    mov [rel BootServices], rbx

    mov r12, [rel BootServices]
    mov rbx, [r12 + 320]
    mov [rel LocateProtocolPtr], rbx

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

    mov rbx, [rel GraphicsOutputProtocolPtr]
    mov [rel GraphicsOutputProtocol], rbx

    mov rbx, [rbx + 24]
    mov [rel GraphicsOutputProtocolModePtr], rbx

    mov [GraphicsOutputProtocolMode], rbx

    mov ebx, [rbx + 0]
    mov [rel GraphicsOutputProtocolMaxMode], ebx

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
        jnz next_mode

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

        mov rbx, [GraphicsOutputProtocol]
        mov rbx, [rbx + 8]
        mov [rel SetModePtr], rbx

        test rax, rax                                               ; EFI_SUCCESS = 0
        jnz gop_not_found                                           

        mov rcx, [rel GraphicsOutputProtocolPtr]
        mov edx, r12d                                               ; mode number matching the preferred info

        sub rsp, 40
        mov rax, [rel SetModePtr]
        call rax
        add rsp, 40

        mov rbx, [rel GraphicsOutputProtocolMode]
        mov rbx, [rbx + 24]
        mov [rel FramebufferBaseAddress], rbx

        mov rbx, [rel GraphicsOutputProtocolInformation]
        mov ebx, [rbx + 32]
        mov [rel PixelsPerScanLine], ebx 

        ; allocate memory for each page tables
        mov rbx, [rel BootServices]
        mov rax, [rbx + 40]                                     
        mov [rel AllocatePages], rax

        ; page map level 4 table
        mov rcx, 0 
        mov rdx, 2    
        mov r8, 1   
        lea r9, [rel PageMapLevel4Ptr]

        sub rsp, 40
        call rax
        add rsp, 40

        test rax, rax
        jnz handle_error

        ; page directory pointer table
        mov rcx, 0 
        mov rdx, 2    
        mov r8, 1  
        lea r9, [rel PageDirectoryPointerTablePtr]

        sub rsp, 40
        mov rax, [rel AllocatePages]
        call rax
        add rsp, 40

        test rax, rax
        jnz handle_error

        ; page directory table
        mov rcx, 0 
        mov rdx, 2    
        mov r8, 32   
        lea r9, [rel PageDirectoryTablePtr]

        sub rsp, 40
        mov rax, [AllocatePages]
        call rax
        add rsp, 40

        test rax, rax
        jnz handle_error

        ; zero out all allocated memory
        ; this is done because the allocated memory contains leftover unpredictable data 
        ; and if one of those data has bit 0 (present bit) set
        ; the CPU will take it as valid entry, which could cause a fault upon access
        cld                                                         ; set the direction flag to one - just in case
        mov rdi, [rel PageMapLevel4Ptr]
        xor rax, rax
        mov rcx, 512                                          
        rep stosq

        mov rdi, [rel PageDirectoryPointerTablePtr]
        xor rax, rax
        mov rcx, 512            
        rep stosq

        mov rdi, [rel PageDirectoryTablePtr]
        xor rax, rax
        mov rcx, 16384                                              ; Page table directory of all PDPT = 32 * 512                   
        rep stosq

        ; link page tables
        ; PML4[0] = &PDPT + flags
        mov rbx, [rel PageDirectoryPointerTablePtr]
        xor rbx, 0x03                                               ; present + read/write          
        mov rax, [rel PageMapLevel4Ptr]                    
        mov [rax], rbx

        ; PDPT[0] = &PDT + flags
        ; PDPT[1] =  (&PDT + 1GiB) + flags
        ; so on, so forth
        mov rbx, [rel PageDirectoryPointerTablePtr]
        mov rax, [rel PageDirectoryTablePtr]
        xor rcx, rcx
    link_pdpt_pdt_loop:
        or rax, 0x03
        mov [rbx + rcx * 8], rax

        add rax, 0x1000                                             ; 4KiB
        inc rcx
        cmp rcx, 32
        jl link_pdpt_pdt_loop

        ; PD[1][1] = 0x00000000 + 0x83
        ; PD[1][2] = (0x00000000 + 2MiB) + 0x83
        ; ................
        ; PD[2][1] = (0x00000000 + 1GiB) + 0x83
        mov rax, 0x00000000
        mov rbx, [rel PageDirectoryTablePtr]                                           
        xor rcx, rcx

    map_huge_pages_loop:
        or rax, 0x83                                                ; present + read/write + page size
        mov [rbx + rcx * 8], rax
        
        add rax, 0x200000   
        inc rcx                                     
        cmp rcx, 16384                                              ; 32 * 512
        jl map_huge_pages_loop

        mov rbx, [rel BootServices]
        mov rax, [rbx + 56]
        mov [rel GetMemoryMap], rax

        lea rcx, [rel MemoryMapSize]
        lea rdx, [rel MemoryMapDestination]
        lea r8,  [rel MapKey]
        lea r9,  [rel DescriptorSize]
        lea rbx, [rel DescriptorVersion]
        sub rsp, 40
        mov [rsp + 32], rbx
        call rax
        add rsp, 40

        test rax, rax   
        jnz handle_error

        mov rbx, [rel BootServices]
        mov rax, [rbx + 232]
        mov [rel ExitBootServices], rax

        mov rcx, [rel ImageHandle]
        mov rdx, [rel MapKey]

        sub rsp, 40
        call rax
        add rsp, 40

        test rax, rax
        jnz handle_error

        mov r14, rax
        mov r15, rax

        ; replaces UEFI paging with the new one
        mov rax, [rel PageMapLevel4Ptr]
        mov cr3, rax

        jmp $
        

        next_mode:
            inc r12d
            jmp find_mode        


    no_matching_mode: 
        gop_not_found:
            handle_error:
                jmp $

    times 1024 - ($ - code_section_start) db 0                       ; pad code section to FileAlignment

code_section_end:

;--------------------------------------------------------------------------------------
; .data Section
;--------------------------------------------------------------------------------------
section .data
data_section_start:

    efi_graphics_output_protocol_guid:
        dd 0x9042A9DE
        dw 0x23DC
        dw 0x4A38
        db 0x96, 0xFB, 0x7A, 0xDE, 0xD0, 0x80, 0x51, 0x6A
    MemoryMapSize dq 16384

    times 512 - ($ - data_section_start) db 0                       ; pad data section to FileAlignment

data_section_end:

;--------------------------------------------------------------------------------------
; .bss Section
;--------------------------------------------------------------------------------------
section .bss
bss_section_start:

    ImageHandle                                     resq 1
    SystemTable                                     resq 1
    BootServices                                    resq 1
    LocateProtocolPtr                               resq 1
    GraphicsOutputProtocolPtr                       resq 1
    GraphicsOutputProtocol                          resq 1
    GraphicsOutputProtocolModePtr                   resq 1
    GraphicsOutputProtocolMode                      resq 1
    GraphicsOutputProtocolMaxMode                   resd 1
    QueryModePtr                                    resq 1
    GraphicsOutputProtocolInformationSizePtr        resq 1
    GraphicsOutputProtocolInformationPtr            resq 1
    GraphicsOutputProtocolInformation               resq 1
    HorizontalResolution                            resd 1
    VerticalResolution                              resd 1
    PixelFormat                                     resd 1
    SetModePtr                                      resq 1
    FramebufferBaseAddress                          resq 1
    PixelsPerScanLine                               resd 1
    AllocatePages                                   resq 1
    PageMapLevel4Ptr                                resq 1
    PageDirectoryPointerTablePtr                    resq 1
    PageDirectoryTablePtr                           resq 1
    GetMemoryMap                                    resq 1
    MemoryMapDestination                            resq 16384
    MapKey                                          resq 1
    DescriptorSize                                  resq 1
    DescriptorVersion                               resq 1
    ExitBootServices                                resq 1


    resb 512 - ($ - bss_section_start)                              ; pad image size in memory to multiple of SectionAlignment

bss_section_end:                                                   

image_end:
;======================================================================================
