section .text
bits 16     
global boot ;boot is the entry for bootloader, so it must be global

boot:

    mov ax, 0x2401;Bit for enabling Protected Mode
    int 0x15;Enable Protected Mode
    mov ax, 0x3;Bit for setting the Video Mode to TTY
    int 0x10;Interrupt for setting video mode

    mov [disk], dl;Move current disk into [disk] variable

    xor bx, bx
    mov ah, 0x2;Load sector
    mov al, 0xE;Number of sectors to load
    mov ch, 0x0;Track id
    mov cl, 0x2;Starting Sector
    mov dh, 0x0;Head id
    mov dl, [disk];Drive id
    mov bx, kernel;Offset of memory location
    int 0x13
    cli
    lgdt [gdt_pointer];Load GDT
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    mov ax, DATA_SEG;prepare for flat memory model setup
    mov ds, ax;load data segment register with DATA_SEG
    mov es, ax;load extra segment register with DATA_SEG
    mov fs, ax;load general purpose segment register fs with DATA_SEG
    mov gs, ax;load general purpose segment register gs with DATA_SEG
    mov ss, ax;load stack segment register with DATA_SEG
    jmp CODE_SEG:start;load code segment register with CODE_SEG, and ip register with start
gdt_start: ;NULL DESCRIPTOR GDT BEGINNING
    dq 0x0
gdt_code: ;CODE SEGMENT
    dw 0xffff ;Segment limit
    dw 0x0 ;Segment Base (bits 0-15)
    db 0x0 ;Segment Base (bits 16-24)
    db 10011010b ;Access byte (in binary) : Present, Ring 0, Code Segment, Executable, Readable
    ;In CODE SEGMENTS Write access is never allowed
    db 11001111b ;Flags (in binary) : 4 bits of segment limit (bits 16-19), granularity (1), operation size (32-bit protected), long mode (disabled), available for system software (reserved)
    db 0x0 ;Segment Base (bits 24-31)
gdt_data: ;DATA SEGMENT
    dw 0xffff ;Segment limit
    dw 0x0 ;Segment Base (bits 0-15)
    db 0x0 ;Segment Base(bits 16-24)
    db 10010010b ;Access byte (in binary) : Present, Ring 0, Data Segment, Writable
    ;In DATA SEGMENTS Read access is always allowed
    db 11001111b ;Flags (in binary) : 4 bits of segment limit (bits 16-19), granularity (1), operation size (32-bit protected), long mode (disabled), available for system software (reserved)
    db 0x0 ;Segment Base (bits 24-31)
gdt_end: ;The end of the GDT

gdt_pointer:
    dw gdt_end - gdt_start;GDT limit : size - 1
    dd gdt_start;GDT base : 0x0
disk:
    db 0x0
CODE_SEG equ gdt_code - gdt_start ;The beginning of the CODE SEGMENT : Kernel code should be loaded here
DATA_SEG equ gdt_data - gdt_start ;The beginning of the DATA SEGMENT : Kernel data should be loaded here

times 510 - ($-$$) db 0; fill remaining bytes with 0 until the file becomes 510 bytes long
dw 0xaa55;final 2 bytes, AA55 declaring end of bootloader

kernel:

;;kernel.asm
;I copied it here cuz I didn't know how to load
;the kernel from a separate file.
;The memory offset kept getting fucked.
bits 32

;section .text
        ;align 4
        ;dd 0x1BADB002
        ;dd 0x00
        ;dd - (0x1BADB002 + 0x00)

global start                ;start is the entry, it must be global
global _keyboard_handler    ;_keyboard_handler is going to be called in kernel.c, must be global
global _read_port           ;_read_port is used in kernel.c, it must be global
global _write_port          ;_write_port is used in kernel.c, it must be global
global _load_idt            ;_load_idt is used in kernel.c, it must be global
extern _kmain               ;_kmain was defined in kernel.c it is extern
extern _keyboard_handler_main;_keyboard_handler_main is defined in kernel.c it is extern
extern _kprint              ;_kprint is defined in kernel.c it is extern
extern _kprint_newline      ;_kprint_newline is defined in kernel.c it is extern

start:
    cli                 ;clear all interrupt flags, disable interrupts
    mov esp, stack_space;sets stack pointer "esp" to point towards stack_space, a 16kb buffer
    call _kmain         ;Call _kmain from C
    hlt                 ;halt the program

;1 argument from edx
;[esp] is a stack where arguments come in,
;the arguments are then put into edx
;edx - port number
;returns - al -> read input
_read_port:
    mov edx, [esp + 4]  ;read input from esp + 4, this is the port number
    in al, dx           ;I/O operation, reads data from port dx, stores in al
    ret                 ;simple return

;2 arguments from edx and al
;[esp] is a stack where arguments come in,
;the arguments are then put into edx and al
;edx - port number
;al - result from read_port
;puts the data from al into the lower 16 bits of edx(port number)
_write_port:
    mov edx, [esp + 4]  ;read argument from esp + 4, first argument, this is the port number
    mov al, [esp + 4 + 4];read argument from esp + 8, second argument, this is the character to be written
    out dx, al          ;I/O operation, writes the character in al to port dx
    ret                 ;simple return

;1 argument from edx
;edx - idt pointer
_load_idt:
    mov edx, [esp + 4]  ;reads argument from esp + 4, this is the idt_ptr
    lidt [edx]          ;loads IDT from idt_ptr
    sti                 ;enable interrupts since IDT has now been loaded
    ret                 ;simple return

_keyboard_handler:      
    call _keyboard_handler_main ;calls C function _keyboard_handler_main
    iretd                       ;interrupt return double word. Interrupt returns should be used when returning
                                ;from an interrupt handler to a program that was interrupted by an interrupt. 
                                ;These class of instructions pop the flags register that was pushed into the stack
                                ;when the interrupt call was made.
                                ;e.g. pop EIP, pop CS, pop EFLAGS
section .bss
align 4
    resb 16384      ;stack will have 16kb of memory
    stack_space: 
