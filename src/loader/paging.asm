; Reference: https://brokenthorn.com/Resources/OSDev18.html


; UEFI allocation
%define AllocateAnyPages        0
%define EfiLoaderData           2

; page table allocation
%define PML4PageCount           1
%define PDPTPageCount           1
%define PDTPageCount            32

; page table 
%define PageTableFlags          0x03
%define PageTableSize           0x1000
%define LargePageFlags          0x83
%define LargePageSize           0x200000

; mapping count
%define PDPTEntryCount          32
%define PDTEntryCount           16384


setup_paging:
    ;--------------------------------------------------------------------------------------------
    ; Allocate Memory For The Page Tables
    ;--------------------------------------------------------------------------------------------
    ; allocate the PML4 table 
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData
    mov r8, PML4PageCount   
    lea r9, [rel PageMapLevel4Ptr]

    sub rsp, 40
    mov rax, [rel AllocatePages]
    call rax
    add rsp, 40

    test rax, rax
    jnz handle_error

    ; allocate the PDPT
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData    
    mov r8, PDPTPageCount  
    lea r9, [rel PageDirectoryPointerTablePtr]

    sub rsp, 40
    mov rax, [rel AllocatePages]
    call rax
    add rsp, 40

    test rax, rax
    jnz handle_error

    ; allocate the PD tables
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData
    mov r8, PDTPageCount 
    lea r9, [rel PageDirectoryTablePtr]

    sub rsp, 40
    mov rax, [AllocatePages]
    call rax
    add rsp, 40

    test rax, rax
    jnz handle_error

    ;--------------------------------------------------------------------------------------------
    ; zero out all allocated memory
    ;--------------------------------------------------------------------------------------------
    ; the allocated memory may containt leftover data 
    ; and if one of those data has bit 0 (present bit) set, the CPU will take it as valid entry
    ; which could cause it to access an invalid page or page table
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
    mov rcx, PDTEntryCount                              ; page table directory of all PDPT = 32 * 512                   
    rep stosq

    ;--------------------------------------------------------------------------------------------
    ; Link Page Table Hierarchy
    ;--------------------------------------------------------------------------------------------
    ; PML4[0] = &PDPT + flags
    mov rbx, [rel PageDirectoryPointerTablePtr]
    or rbx, PageTableFlags                              ; present + read/write          
    mov rax, [rel PageMapLevel4Ptr]                    
    mov [rax], rbx

    ; PDPTEntry[0] = &PDT + flags
    ; PDPTEntry[1] =  (&PDT + 1GiB) + flags
    ; and so on
    mov rbx, [rel PageDirectoryPointerTablePtr]
    mov rax, [rel PageDirectoryTablePtr]
    xor rcx, rcx
    link_pdpt_pdt_loop:
        or rax, PageTableFlags                          ; present + read/write 
        mov [rbx + rcx * 8], rax

        add rax, PageTableSize                          ; 4KiB
        inc rcx
        cmp rcx, PDPTEntryCount
        jl link_pdpt_pdt_loop

    ;--------------------------------------------------------------------------------------------
    ; Map Physical Memory
    ;--------------------------------------------------------------------------------------------
    ; PDEntry[0] = 0x00000000 + flags
    ; PDEntry[1] = 0x00200000 + flags
    ; and so on
    mov rax, 0x00000000
    mov rbx, [rel PageDirectoryTablePtr]                    
    xor rcx, rcx

    map_2mib_memory_loop:
        or rax, LargePageFlags                          ; present + read/write + page size
        mov [rbx + rcx * 8], rax

        add rax, LargePageSize   
        inc rcx                                     
        cmp rcx, PDTEntryCount             
        jl map_2mib_memory_loop

    ;--------------------------------------------------------------------------------------------
    ; Get UEFI Memory Map Key
    ;--------------------------------------------------------------------------------------------
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
    
    ;--------------------------------------------------------------------------------------------
    ; Exit UEFI Environment
    ;--------------------------------------------------------------------------------------------
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

    ;--------------------------------------------------------------------------------------------
    ; Load The New Page Tables
    ;--------------------------------------------------------------------------------------------
    ; replace UEFI's page tables with ours
    mov rax, [rel PageMapLevel4Ptr]
    mov cr3, rax

    ret