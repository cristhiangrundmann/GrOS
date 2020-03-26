org 0x7c00
bits 16

%define SECTORS 0x1
%define STACK 0x7

%define COLOR_HA 0x10
%define COLOR_HB 0x30
%define COLOR_AS 0x20
%define COLOR_ED 0x0f
%define COLOR_DE 0x00
%define COLOR_CU 0x40

main:

    ;REGISTER SETUP
    xor ax, ax
    mov ds, ax
    mov bp, ax
    mov sp, ax
    mov bp, sp
    mov ah, STACK
    mov ss, ax
    mov ah, 0xb8
    mov es, ax

    jmp draw
    
loop:

    ;CURSOR
    mov dh, [es:di+0x1]
    mov cl, dh
    and cl, 0x0f
    or cl, COLOR_CU
    mov [es:di+0x1], cl

    xor ax, ax
    int 0x16

    mov [es:di+0x1], dh

    cmp al, 0x20
    jb loop_noascii

    mov ah, [es:di+0x1]
    and ah, 0xf0
    or ah, COLOR_ED

    cmp di, 0xa0 * 0x8
    jb loop_ascii

    mov cl, al
    call hexascii
    and al, 0x0f
    call hexascii
    cmp al, cl
    jne loop

    mov [es:di], ax
    push di
    call swap
    jmp loop_type_done

loop_ascii:
    mov [es:di], ax
    push di
    call swap
    call type
    inc di
    inc di
loop_type_done:
    call type
    pop di
    inc di
    inc di
    jmp loop

loop_noascii:
    cmp ah, 0x4b
    jne loop_nleft
    dec di
    dec di
loop_nleft:
    cmp ah, 0x4d
    jne loop_nright
    inc di
    inc di
    jmp loop
    
loop_nright:
    cmp ah, 0x48
    jne loop_nup
    sub di, 0xa0
loop_nup:
    cmp ah, 0x50
    jne loop_ndown
    add di, 0xa0 
loop_ndown:
    cmp ah, 0x0f
    jne loop_ntab
    call swap
loop_ntab:
    cmp ah, 0x42
    je loop_disk
    cmp ah, 0x43
    jne loop
    pusha
    mov di, 0xa0*0x8
    xor si, si
    mov cx, 0x1020
loop0:
    call read
    add si, 0x20
    add di, 0xa0
    dec ch
    jnz loop0
    popa

loop_disk:
    pusha

    ;TARGET
    mov cl, 0x8
    mov di, 0xa0*0x18
    mov si, TARGET - STACK*0x1000
    call read
    mov al, 0x0
    mov si, DAP
    int 0x13
    jc main
    popa
draw:
    pusha
    mov ax, 0x3
    int 0x10
    ;ASCII
    mov dh, COLOR_AS
    mov si, 0x1ff
    mov di, 0xa0*0x8-0x22
    mov ah, COLOR_DE
draw_as:
    mov cl, 0x40
draw_as0:
    mov [es:di+0x1], dh
    mov al, [ss:si]
    call type
    dec di
    dec di
    dec si
    jl draw_hex
    dec cl
    jnz draw_as0
    sub di, 0x20
    jmp draw_as

    ;HEX
draw_hex:
    mov di, 0xa0 * 0x8
    xor si, si
    mov cx, 0x1020
draw_hex0:
    call write
    add si, 0x20
    add di, 0xa0
    dec ch
    jnz draw_hex0

    ;TARGET
    mov cl, 0x8
    mov si, TARGET - STACK*0x1000
    mov di, 0xa0*0x18
    call write
    popa
    jmp loop

;si = source
;di = destination
;cl = count
write:
    pusha
    mov ah, COLOR_DE
    mov ch, COLOR_HA
write0:
    mov al, [ss:si]
    inc si
    mov [es:di+0x1], ch
    mov [es:di+0x3], ch
    call type
    inc di
    inc di
    call type
    xor ch, COLOR_HA ^ COLOR_HB
    inc di
    inc di
    dec cl
    jnz write0
    popa
    ret

;di = source
;si = destination
;cl = count
read:
    pusha
read0:
    mov al, [es:di]
    call hexascii
    mov ah, al
    shl ah, 0x4
    inc di
    inc di
    mov al, [es:di]
    call hexascii
    or ah, al
    inc di
    inc di
    mov [ss:si], ah
    inc si
    dec cl
    jnz read0
    popa
    ret



swap:
    push ax
    mov ax, di
    mov ch, 0xa0
    cmp ax, 0xa0*0x8
    jnb swap_hex
    div ch
    shl ax, 0x1
    shl ah, 0x1
    jnc swap_even
    inc al
swap_even:
    shr ah, 0x1
    add al, 0x8
    jmp swap_do
swap_hex:
    sub ax, 0xa0*0x8
    div ch
    and ah, 0xff-0x2
    shr ax, 0x1
    jnc swap_even2
    add ah, 0x40
swap_even2:
swap_do:
    mov cl, ah
    mul ch
    mov ch, 0x0
    add ax, cx
    mov di, ax 
    pop ax
    ret

;swap nibble with ASCII char
;eg. 0x9 <-> '9'
hexascii:
    xor al, 0x30
    cmp al, 0x3a
    jb hexascii0
    add al, 0x99
    jc hexascii0
    sub al, 0x92
hexascii0:
    ret

DAP:
db 0x10
db 0x0
dw 0x1
dw 0x0
dw STACK*0x100
TARGET: dq 0x0


times (0x1be - ($ - $$)) db 0x0

PARTITION_STATUS: db 0x80
CHS_START: db 0x0, 0x0, 0x0
PARTITION_TYPE: db 0xff
CHS_END: db 0x0, 0x0, 0x0
LBA_START: dd 0x0
VOLUME_SIZE: dd SECTORS

;ah = forecolor
;al = data
;di = destination
type:
    pusha
    cmp di, 0xa0 * 0x8
    jb type_do
    push di
    shr di, 0x2
    jc type_odd
    shr al, 0x4
    jmp type_di
type_odd:
    and al, 0x0f
type_di:
    call hexascii
    pop di
type_do:
    cmp al, 0x20
    jnb type_char
    mov al, 0xf9
type_char:
    mov bx, [es:di]
    and bh, 0xf0
    or ah, bh
    mov [es:di], ax
    popa
    ret



times 0x1fe - ($-$$) db 0x0
db 0x55, 0xaa