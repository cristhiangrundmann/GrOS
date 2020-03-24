org 0x7c00
bits 16

%define STACK 0x7b
%define COLOR_A 0x10
%define COLOR_B 0x30
%define COLOR_C 0x10
%define COLOR_N 0x0f
%define BUFFER 0x7e00
%define ASCIIX 0x8
%define ASCIIY 0x0
%define ASCIIPOS 0x2 * (0x50 * ASCIIY + ASCIIX)
%define BOARDX 0x8
%define BOARDY 0x8
%define BOARDPOS 0x2 * (0x50 * BOARDY + BOARDX)
%define TARGETX 0x20
%define TARGETY 0x18
%define TARGETPOS 0x2 * (0x50 * TARGETY + TARGETX)
%define SECTORS 1

BEGIN:
main:
    ;SET SEGMENTS
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov ah, 0xb8
    mov es, ax
    mov ah, STACK
    mov sp, ax
    mov sp, bp

    ;CLEAR SCREEN
    ;mov ax, 0x3
    ;int 0x10

    mov cx, (BOARDY*0x100 + BOARDX)
    call showcontents

edit:
    call readkey
    cmp cl, BOARDX-1
    jne edit0
    mov cl, BOARDX+0x3f
    dec ch
edit0:
    cmp cl, BOARDX+0x40
    jne edit1
    mov cl, BOARDX
    inc ch
edit1:
    cmp ch, 0x19
    jne edit2
    xor ch, ch
edit2:
    cmp ch, 0xff
    jne edit3
    mov ch, 0x18
edit3:
    cmp ch, 0x18
    jne edit4
    and cl, 0xf
    or cl, 0x20
edit4:
    jmp edit

;al = ascii
;cx = cursor
type:
    pusha
    mov dh, al
    mov ah, 0x8
    int 0x10
    mov bl, ah
    and bl, 0xf0
	xor bl, COLOR_N & 0x0f
    mov al, dh
	mov ah, 0x9
	mov cx, 0x1
	int 0x10
    popa
    ret

setcursor:
    pusha
    mov ah, 0x2
    mov dx, cx
    int 0x10
    popa
    ret

readkey:
    call setcursor
    xor ah, ah
    int 0x16
    cmp al, 0x7e
    jg readkey0
    cmp al, 0x20
    jb readkey0
    pusha
    cmp ch, BOARDY
    jb readkey_b0
    cmp al, '0'
    jb readkey_b1
    cmp al, 'F'
    jg readkey_b1
    cmp al, '9'
    jbe readkey_b2
    cmp al, '0'
    jge readkey_b2
readkey_b1:
    popa
    ret
readkey_b0:
    call type
    sub cl, BOARDX
    shl cx, 1
    mov dh, cl
    and cl, 0x3f
    shr dh, 0x6
    add ch, dh
    add ch, BOARDY
    add cl, BOARDX
    
    mov dh, al
    shr al, 0x4
    call nib2txt
    call setcursor
    call type

    mov al, dh
    and al, 0x0f
    call nib2txt
    inc cl
    call setcursor
    call type
    popa
	inc cl
    ret
readkey_b2:
    popa
    ret
readkey0:
    cmp ah, 0x4b
    jne readkey1
    dec cl
readkey1:
    cmp ah, 0x4d
    jne readkey2
    inc cl
readkey2:
    cmp ah, 0x48
    jne readkey3
    dec ch
readkey3:
    cmp ah, 0x50
    jne readkey4
    inc ch
readkey4:
    cmp ah, 0x3f
    jne readkey5
    call gettarget
	pusha
	mov ah, 0x42
	mov si, DAP
	int 0x13
	jc main
	popa
	call showcontents
readkey5:
    cmp ah, 0x43
    jne readkey6
    call gettarget
	mov si, BUFFER
	mov di, BOARDPOS
readkey5a:
    mov bl, 0x20
	call readdata
	add di, 0xa0
	add si, 0x20
	cmp si, BUFFER + 0x200
	jb readkey5a
	pusha
	mov ax, 0x4300
	mov si, DAP
	int 0x13
	jc main
	call showcontents
	popa
readkey6:
    ret

;show buffer content and target
showcontents:
    pusha
    mov si, BUFFER
    mov di, ASCIIPOS
    mov bl, 0x40
showcontents0:
    mov ah, [ds:si]
    mov al, ah
    and al, 0b11100000
    jnz showcontents1
    mov ah, 0xf9
showcontents1:
    mov al, ah
    mov ah, COLOR_C
    mov [es:di], ax
    inc di
    inc di
    inc si
    dec bl
    jnz showcontents2
    add di, 0x20
    mov bl, 0x40
showcontents2:
    cmp si, BUFFER + 0x200
    jne showcontents0
    mov si, BUFFER
    mov di, BOARDPOS
    mov bl, 0x20
showcontents3:
    call writedata
    add si, 0x20
    add di, 0xa0
    cmp si, BUFFER + 0x200
    jb showcontents3
    mov si, TARGET
    mov di, TARGETPOS
    mov bl, 0x8
    call writedata
    popa
    ret

;ds:si = destination
;es:di = source on screen
;bl = byte count > 0
readdata:
    pusha
readdata0:
    mov al, [es:di]
    call txt2nib
    mov ah, al
    shl ah, 0x4
    inc di
    inc di
    mov al, [es:di]
    call txt2nib
    xor ah, al
    inc di
    inc di
    mov [ds:si], ah
    inc si
    dec bl
    jz readdata1
    jmp readdata0
readdata1:
    popa
    ret

;ds:si = source
;es:di = destination on screen
;bl = byte count > 0
writedata:
    pusha
    mov ah, COLOR_A
writedata0:
    mov cl, [ds:si]
    mov al, cl
    shr al, 0x4
    call nib2txt
    mov [es:di], ax
    inc di
    inc di
    mov al, cl
    and al, 0x0f
    call nib2txt
    mov [es:di], ax
    inc di
    inc di
    inc si
    xor ah, (COLOR_A ^ COLOR_B) & 0xf0
    dec bl
    jnz writedata0
    popa
    ret

END:

;times (0x1be - ($ - $$)) db 0x00

;PARTITION_STATUS: db 0x80
;CHS_START: db 0x0, 0x0, 0x0
;PARTITION_TYPE: db 0xff
;CHS_END: db 0x0, 0x0, 0x0
;LBA_START: dd 0x0
;VOLUME_SIZE: dd SECTORS

DAP:
db 0x10
db 0x0
dw 0x1
dw BUFFER
dw 0x0
TARGET: dq 0x1


gettarget:
    pusha
    mov si, TARGET
    mov di, TARGETPOS
    mov bl, 0x8
    call readdata
    popa
    ret

;al = '0' ... '9' | 'A' .. 'F'
txt2nib:
	sub al, '0'
	cmp al, 0x9
	jbe txt2nib0
	sub al, 'A' - '9' - 0x1
txt2nib0:
	ret


;al = 0x00 ... 0x0f
nib2txt:
	add al, '0'
	cmp al, '9'
	jbe nib2txt0
	add al, 'A' - '9' - 0x1
nib2txt0:
	ret


times (0x1fe - ($ - $$)) db 0x0
db 0x55, 0xaa

times (SECTORS * 0x200 - ($ - $$)) db 0x00
