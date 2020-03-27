org 0x7c00
bits 16

%define SECTORS 1
%define COLOR_ASCII 0x20
%define COLOR_HEX_A 0x10
%define COLOR_HEX_B 0x30
%define COLOR_CURSOR 0x40
%define COLOR_DE 0x00
%define COLOR_ED 0x0f

main:
    ;SEGMENTS
    xor ax, ax
    mov ds, ax
    mov bp, ax
    mov sp, bp
    mov ah, 0xb8
    mov es, ax
    mov ah, 0x7
    mov ss, ax

    ;CLEAR SCREEN
    mov ax, 0x3
    int 0x10

draw:
    pusha
    push es
    push 0xb800 + 0xa*0x7
    pop es
    mov ah, COLOR_DE
    mov si, TARGET - 0x7000 + 0x7
    mov di, 0x8e
    mov cl, 0x7
draw0:
    mov al, [ss:si]
    call type
    dec di
    dec di
    dec si
    dec cl
    jnl draw0
    mov si, 0x1ff
draw1:
    mov di, 0x7e
draw2:
    mov al, [ss:si]
    call type
    dec si
    dec di
    dec di
    jnl draw2
    mov bx, es
    sub bl, 0xa
    mov es, bx
    jnl draw1
draw3:
    pop es
    popa


loop:
    cmp di, 0x10000 - 0x2
    jne loopm1
    mov di, 0xa0 - 0x2
loopm1:
    cmp di, 0xa0
    jne loopm2
    xor di, di
loopm2:
    mov cx, es
    cmp cl, 0xa * 0x19
    jne loopm3
    mov cl, 0x0
loopm3:
    cmp cl, 0xa * (-1)
    jne loopm4
    mov cl, 0xa * 0x18
loopm4:
    mov es, cx

    ;CURSOR
    mov dh, [es:di+0x1]
    mov cl, dh
    and cl, 0x0f
    or cl, COLOR_CURSOR
    mov [es:di+0x1], cl

    xor ax, ax
    int 0x16

    mov [es:di+0x1], dh

    cmp al, 0x20
    jb loop1
    mov cx, es
    cmp cl, 0xa * 0x8
    jb loop0

    mov ch, al
    call hexascii
    and al, 0x0f
    call hexascii
    cmp al, ch
    jne loop

    mov [es:di], al
    mov cl, 0x1
    push di
    and di, 0xffff - 0x2
    mov si, ADDRESS - 0x7000 + 0x1
    call read
    call swap
ADDRESS:
    mov ax, COLOR_ED * 0x100
    call type
    call swap
    pop di
    inc di
    inc di
    jmp loop
loop0:
    mov ah, COLOR_ED
    call type
    inc di
    inc di
    jmp loop
loop1:
    cmp ah, 0x4b
    jne loop2
    dec di
    dec di
loop2:
    cmp ah, 0x4d
    jne loop3
    inc di
    inc di
loop3:
    cmp ah, 0x48
    jne loop4
    mov cx, es
    sub cl, 0xa
    mov es, cx
loop4:
    cmp ah, 0x50
    jne loop5
    mov cx, es
    add cl, 0xa
    mov es, cx
loop5:
    cmp ah, 0x0f
    jne loop6
    call swap
loop6:
    cmp ah, 0x42
    je loop7
    cmp ah, 0x43
    jne loop
    pusha
    push es
    push 0xb800
    pop es
    mov di, 0xa0*0x8
    mov cl, 0x20
    xor si, si
loop6a:
    call read
    add di, 0xa0
    add si, 0x20
    cmp si, 0x200
    jne loop6a
    pop es
    popa
loop7:
    pusha
    push es
    push 0xb800 + 0xa*0x17 + 0x8
    pop es
    mov cl, 0x8
    mov si, TARGET - 0x7000
    xor di, di
    call read
    pop es
    mov al, 0x0
    mov si, DAP
    int 0x13
    jc main
    popa
    
    jmp draw

read:
    pusha
read0:
    mov al, [es:di]
    call hexascii
    shl al, 0x4
    mov ah, al
    inc di
    inc di
    mov al, [es:di]
    call hexascii
    or al, ah
    inc di
    inc di
    mov [ss:si], al
    inc si
    dec cl
    jnz read0
    popa
    ret

type:
    pusha
    or ah, COLOR_ASCII
    mov dh, al
    cmp al, 0x20
    jae type0
    mov al, 0xf9
type0:
    mov [es:di], ax
    call swap
    xor ah, COLOR_HEX_A ^ COLOR_ASCII
    push di
    shr di, 0x3
    jnc type1
    xor ah, COLOR_HEX_A ^ COLOR_HEX_B
type1:
    pop di
    mov al, dh
    shr al, 0x4
    call hexascii
    mov [es:di], ax
    inc di
    inc di
    mov al, dh
    and al, 0x0f
    call hexascii
    mov [es:di], ax
    call swap
    popa
    ret

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
dw 0x0700
TARGET: dq 0x1

times (0x1be - ($ - $$)) db 0xA3

PARTITION_STATUS: db 0x80
CHS_START: db 0x0, 0x0, 0x0
PARTITION_TYPE: db 0xff
CHS_END: db 0x0, 0x0, 0x0
LBA_START: dd 0x0
VOLUME_SIZE: dd SECTORS

swap:
    push ax
    mov ax, es
    sub al, 0xa*0x8
    jb swap1
    shr di, 0x2
    shl di, 0x1
    shr al, 0x2
    jnc swap0
    sub al, 0x2
    add di, 0x40
swap0:
    shl al, 0x1
    jmp swap3
swap1:
    shl al, 0x1
    cmp di, 0x40
    jb swap2
    add al, 0xa
    sub di, 0x40
swap2:
    shl di, 0x1
    add al, 0xa*0x18
swap3:
    mov es, ax
    pop ax
    ret


times 0x1fe - ($ - $$) db 0x0
db 0x55, 0xaa