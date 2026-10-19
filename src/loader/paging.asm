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
    ; Allocate Memory For The Userspace Page Tables
    ;--------------------------------------------------------------------------------------------
    ; allocate the PML4 table 
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData
    mov r8, PML4PageCount   
    lea r9, [PageMapLevel4]

    sub rsp, 40
    call [AllocatePages]
    add rsp, 40

    test rax, rax
    jnz handle_error

    ; allocate the PDPT
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData    
    mov r8, PDPTPageCount  
    lea r9, [PageDirectoryPointerTable]

    sub rsp, 40
    call [AllocatePages]
    add rsp, 40

    test rax, rax
    jnz handle_error

    ; allocate the PD tables
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData
    mov r8, PDTPageCount 
    lea r9, [PageDirectoryTable]

    sub rsp, 40
    call [AllocatePages]
    add rsp, 40

    test rax, rax
    jnz handle_error

    ;--------------------------------------------------------------------------------------------
    ; Allocate Memory For The Kernel Page Tables
    ;--------------------------------------------------------------------------------------------
    ; allocate the PDPT
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData    
    mov r8, PDPTPageCount  
    lea r9, [PageDirectoryPointerTableHigher]

    sub rsp, 40
    call [AllocatePages]
    add rsp, 40

    test rax, rax
    jnz handle_error

    ; allocate the PD tables
    mov rcx, AllocateAnyPages 
    mov rdx, EfiLoaderData
    mov r8, PDTPageCount 
    lea r9, [PageDirectoryTableHigher]

    sub rsp, 40
    call [AllocatePages]
    add rsp, 40

    test rax, rax
    jnz handle_error

    ;--------------------------------------------------------------------------------------------
    ; zero out all allocated memory
    ;--------------------------------------------------------------------------------------------
    ; the allocated memory may containt leftover data 
    ; and if one of those data has bit 0 (present bit) set, the CPU will take it as valid entry
    ; which could cause it to access an invalid page or page table
    mov rdi, [PageMapLevel4]
    xor rax, rax
    mov rcx, 512                                          
    rep stosq

    mov rdi, [PageDirectoryPointerTable]
    xor rax, rax
    mov rcx, 512            
    rep stosq

    mov rdi, [PageDirectoryTable]
    xor rax, rax
    mov rcx, PDTEntryCount                              ; page table directory of all PDPT = 32 * 512                   
    rep stosq

    ;--------------------------------------------------------------------------------------------
    ; Link Page Table Hierarchy
    ;--------------------------------------------------------------------------------------------
    ; PML4 Table[0] = &PDPT + flags
    mov r12, [PageDirectoryPointerTable]
    or r12, PageTableFlags                              ; present + read/write          
    mov r13, [PageMapLevel4]                    
    mov [r13], r12

    ; PDP Table[0] Entry[0] = &PDT + flags
    ; PDP Table[0] Entry[1] =  (&PDT + 1GiB) + flags
    ; and so on
    mov r12, [PageDirectoryTable]
    mov r13, [PageDirectoryPointerTable]
    xor rbx, rbx
    link_pdpt_pdt_loop:
        mov r14, r12                                    ; saves it from corrupting
        or r14, PageTableFlags                          ; present + read/write 
        mov [r13 + (rbx * 8)], r14

        add r12, PageTableSize                          ; 4KiB
        inc rbx
        cmp rbx, PDPTEntryCount
        jl link_pdpt_pdt_loop

    ; PD Table[0] Entry[0] = 0x00000000 + flags
    ; PD Table[0] Entry[1] = 0x00200000 + flags
    ; and so on
    mov r12, 0x00000000
    mov r13, [PageDirectoryTable]                    
    xor rbx, rbx

    map_2mib_memory_loop:
        mov r14, r12
        or r14, LargePageFlags                          ; present + read/write + page size
        mov [r13 + (rbx * 8)], r14

        add r12, LargePageSize   
        inc rbx                                     
        cmp rbx, PDTEntryCount             
        jl map_2mib_memory_loop

    ;--------------------------------------------------------------------------------------------
    ; Link Page Table Hierarchy For Higher Half Kernel
    ;--------------------------------------------------------------------------------------------    
    ; PML4 Table[511] = &PDPT + flags    
    mov r12, [PageDirectoryPointerTableHigher]
    or r12, PageTableFlags
    mov r13, [PageMapLevel4]
    mov [r13 + 4088], r12                               

    ; PDP Table[0] Entry[0] = &PDT + flags
    ; PDP Table[0] Entry[1] = (&PDT + 4KiB) + flags
    ; and so on
    mov r12, [PageDirectoryTableHigher]    
    mov r13, [PageDirectoryPointerTableHigher]
    xor rbx, rbx
    link_higher_pdpt_pdt_loop:
        mov r14, r12
        or r14, PageTableFlags                          ; present + read/write 
        mov [r13 + (rbx * 8)], r14

        add r12, PageTableSize                          ; 4KiB
        inc rbx
        cmp rbx, PDPTEntryCount
        jl link_higher_pdpt_pdt_loop

    ; PD Table[0] Entry[0] = 0x00000000 + flags
    ; PD Table[0] Entry[1] = 0x00200000 + flags
    mov r12, 0x00000000
    mov r13, [PageDirectoryTableHigher]                    
    xor rbx, rbx

    map_higher_2mib_memory_loop:
        mov r14, r12
        or r14, LargePageFlags                          ; present + read/write + page size
        mov [r13 + (rbx * 8)], r14

        add r12, LargePageSize   
        inc rbx                                     
        cmp rbx, PDTEntryCount             
        jl map_higher_2mib_memory_loop

    ;--------------------------------------------------------------------------------------------
    ; Get UEFI Memory Map Key and Exit UEFI Environment
    ;--------------------------------------------------------------------------------------------
    mov r12, [BootServices]
    mov rax, [r12 + 56]
    mov [GetMemoryMap], rax

    lea rcx, [MemoryMapSize]
    lea rdx, [MemoryMapDestination]
    lea r8,  [MapKey]
    lea r9,  [DescriptorSize]
    lea r12, [DescriptorVersion]
    sub rsp, 40
    mov [rsp + 32], r12                                 ; 5th argument
    call [GetMemoryMap]
    add rsp, 40

    test rax, rax   
    jnz handle_error
    
    mov r12, [BootServices]
    mov rax, [r12 + 232]
    mov [ExitBootServices], rax

    mov rcx, [ImageHandle]
    mov rdx, [MapKey]

    sub rsp, 40
    call [ExitBootServices]
    add rsp, 40

    test rax, rax
    jnz handle_error

    ;--------------------------------------------------------------------------------------------
    ; Load The New Page Tables
    ;--------------------------------------------------------------------------------------------
    ; replace UEFI's page tables with ours
    mov r12, [PageMapLevel4]
    mov cr3, r12

    ret