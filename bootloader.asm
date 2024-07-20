section .text
bits 16
global boot

boot:

    mov ax, 0x2401
    int 0x15
    mov ax, 0x3
    int 0x10

    mov [disk], dl

    xor bx, bx
    mov ah, 0x2
    mov al, 0xE
    mov ch, 0x0
    mov cl, 0x2
    mov dh, 0x0
    mov dl, [disk]
    mov bx, kernel
    int 0x13
    cli
    lgdt [gdt_pointer]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp CODE_SEG:start
gdt_start:
    dq 0x0
gdt_code:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0
gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
gdt_end:

gdt_pointer:
    dw gdt_end - gdt_start
    dd gdt_start
disk:
    db 0x0
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

times 510 - ($-$$) db 0
dw 0xaa55

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

global start
global _keyboard_handler
global _read_port
global _write_port
global _load_idt
extern _kmain
extern _keyboard_handler_main
extern _kprint
extern _kprint_newline

start:
    cli
    mov esp, stack_space
    call _kmain
    hlt

;1 argument from edx
;[esp] is a stack where arguments come in,
;the arguments are then put into edx
;edx - port number
;returns - al -> read input
_read_port:
    mov edx, [esp + 4]
    in al, dx
    ret

;2 arguments from edx and al
;[esp] is a stack where arguments come in,
;the arguments are then put into edx and al
;edx - port number
;al - result from read_port
;puts the data from al into the lower 16 bits of edx(port number)
_write_port:
    mov edx, [esp + 4]
    mov al, [esp + 4 + 4]
    out dx, al
    ret

;1 argument from edx
;edx - idt pointer
_load_idt:
    mov edx, [esp + 4]
    lidt [edx]
    sti
    ret

_keyboard_handler:
    call _keyboard_handler_main
    iretd

section .bss
align 4
    resb 16384
    stack_space: 
