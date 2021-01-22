org 0x7c00
bits 16

%define SECTORS 0x2

%define BCOLORAS 0x20
%define BCOLORH1 0x10
%define BCOLORH2 0x30
%define BCOLORCU 0x40
%define FCOLORDE 0x00
%define FCOLORED 0x0f

    ;mov ah, 0x5
    ;mov cx, 0x4200
    ;int 0x16

main:
    cld
    sti
    xor ax, ax
    mov bp, ax
    mov sp, bp
    mov ah, 0x07
    mov ds, ax
    mov ss, ax
    mov ah, 0xb8
    mov es, ax

    mov ax, 0x3
    int 0x10
    mov ax, 0x1112
    mov bl, 0x0
    int 0x10

draw:
    pusha
    push es

    mov bx, 0xb800 + 0xa*0x2
    mov es, bx
    mov ah, FCOLORDE
    mov si, TARGET - 0x7000
    mov di, 0x20
    mov cl, 0x8

draw0:
    lodsb
    call type
    dec cl
    jnz draw0

    mov bl, 0xa*0x4
    mov es, bx
    xor si, si
    mov ch, 0x20
draw1:
    mov cl, 0x10
    mov di, 0x20
draw2:
    lodsb
    call type
    dec cl
    jnz draw2
    add bx, 0xa
    mov es, bx
    dec ch
    jnz draw1
    pop es
    popa

mloop:
    and di, 0x7f
    
mloopc0:

    mov ax, es
    cmp ax, 0xb800 + 0xa*0x2
    jnl mloopc2
    mov ax, 0xb800 + 0xa * 0x23
mloopc2:
    cmp ax, 0xb800 + 0xa * 0x24
    jb mloopc3
    mov ax, 0xb800 + 0xa*0x2
mloopc3:
    mov es, ax

    mov ax, [es:di]
    push ax
    and ah, 0x0f
    or ah, BCOLORCU
    mov [es:di], ax
   
    xor ax, ax
    int 0x16

    pop word [es:di]

    cmp al, 0x20
    jb mloop1

    mov bx, [es:di]
    cmp bh, 0x10
    jb mloop

    cmp di, 0x40
    jb mloop0
    mov ah, al
    call hexascii
    and al, 0x0f
    call hexascii
    cmp ah, al
    jne mloop

    push di
    stosb
    mov cl, 0x1
    mov si, mloop_addr - 0x7000 + 0x1
    and di, 0xffff - 0x3
    call read
    call swap
mloop_addr:
    mov ax, FCOLORED * 0x100 + '?'
    call type
    pop di
mloop_incdi:
    inc di
    inc di
    jmp mloop
mloop0:
    mov ah, FCOLORED
    call type
    jmp mloop
mloop1:
    mov al, ah
    cmp al, 0x4b ;0x4b = left arrow
    jne mloop2
    dec di
    dec di
    jmp mloop
mloop2:
    cmp al, 0x4d ;0x4d = right arrow
    je mloop_incdi
    cmp al, 0x48 ;0x48 = up arrow
    jne mloop3
    mov cx, es
    sub cx, 0xa
    mov es, cx
mloop3:
    cmp al, 0x50 ;0x50 = down arrow
    jne mloop4
    mov cx, es
    add cx, 0xa
    mov es, cx
mloop4:
    cmp al, 0x0f ;0x0f = tab
    jne mloop5
    call swap
mloop5:

    ;if read keybind is f8, then ah = 0x42 automatically
    ;mov ah, 0x42

    ;read key
    cmp al, 0x42 ;0x42 = f8
    je mloop7

    ;write key
    cmp al, 0x43 ;0x43 = f9
    jne mloop8

    ;if write keybind if f9, then ah = 0x43 automatically
    ;mov ah, 0x43

    pusha
    push es
    push 0xb800
    pop es
    mov di, 0xa0*0x4 + 0x40
    mov cl, 0x10
    xor si, si
mloop6:
    call read
    add di, 0xa0
    add si, 0x10
    cmp si, 0x200
    jne mloop6
    pop es
    popa
mloop7:
    pusha
    push es
    push 0xb800 + 0xa*0x2
    pop es
    mov cl, 0x8
    mov si, TARGET - 0x7000
    mov di, 0x40
    call read
    pop es
    mov al, 0x0
    mov si, DAP - 0x7000
    int 0x13

    jc main
    popa
    jmp draw
mloop8:
    cmp al, 0x86 ;0x86 = f12
    jne mloop
    xor si, si
    lodsw

    cmp ax, 0x9090
    jne mloop

    call 0x7000
    jmp mloop

read:
    pusha
read0:
    mov ax, [es:di]
    stosw
    call hexascii
    shl al, 0x4
    mov dh, al
    mov ax, [es:di]
    stosw
    call hexascii
    and al, 0x0f
    or al, dh
    mov [si], al
    inc si
    dec cl
    jnz read0
    popa
    ret

type:
    push ax
    or ah, BCOLORAS
    push di
    stosw
    xor ah, BCOLORAS ^ BCOLORH1
    shr di, 0x2
    jnc type0
    xor ah, BCOLORH1 ^ BCOLORH2
type0:
    pop di
    call swap
    push ax
    shr al, 0x4
    call hexascii
    stosw
    pop ax
    and al, 0x0f
    call hexascii
    stosw
    call swap
    pop ax
    ret

swap:
    cmp di, 0x40
    jl swap0
    shr di, 0x2
swap0:
    shl di, 0x1
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

times 0x1fe-($-$$) db 0x0
db 0x55, 0xaa