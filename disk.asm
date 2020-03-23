org 0x7c00
bits 16

%define STACK 0x7b
%define COLOR_A 0x10
%define COLOR_B 0x30
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
    mov ax, 0x3
    int 0x10


    call showcontents

editboard:
    
    jmp editboard

editascii:

    jmp editascii

edittarget:

    jmp edittarget




gettarget:
    pusha
    mov si, TARGET
    mov di, TARGETPOS
    mov bl, 0x8
    call readdata
    popa
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
    mov [es:di], al
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
    mov cl, [es:di]
    mov al, cl
    call txt2nib
    mov ah, al
    shl ah, 0x4
    inc di
    inc di
    mov al, cl
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

;al = 0x00 ... 0x0f
nib2txt:
	add al, '0'
	cmp al, '9'
	jbe nib2txt0
	add al, 'A' - '9' - 0x1
nib2txt0:
	ret
	
;al = '0' ... '9' | 'A' .. 'F'
txt2nib:
	sub al, '0'
	cmp al, 0x9
	jbe txt2nib0
	sub al, 'A' - '9' - 0x1
txt2nib0:
	ret

END:

times (0x1be - ($ - $$)) db 0xA3

PARTITION_STATUS: db 0x80
CHS_START: db 0x0, 0x0, 0x0
PARTITION_TYPE: db 0xff
CHS_END: db 0x0, 0x0, 0x0
LBA_START: dd 0x0
VOLUME_SIZE: dd SECTORS

DAP:
db 0x10
db 0x0
dw 0x1
dw BUFFER
dw 0x0
TARGET: dq 0x1


times (0x1fc - ($ - $$)) db 0x0
dw (END - BEGIN)
db 0x55, 0xaa

times (SECTORS * 0x200 - ($ - $$)) db 0x00
