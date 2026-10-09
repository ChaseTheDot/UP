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

    mov rbx, [rel BootServices]
    mov rax, [rbx + 40]                                     
    mov [rel AllocatePages], rax

    call setup_gop
    call setup_paging

    jmp $

    %include "src/loader/gop.asm"
    %include "src/loader/paging.asm"
          


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
