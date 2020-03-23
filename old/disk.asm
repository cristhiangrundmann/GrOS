;Created by Cristhian Grundmann, 2019
;Single sector disk editor

org 0x7c00
bits 16

%define DRIVE 0x80
%define SECTORS 0x10
%define BUFFER 0x7e00
%define STACKHI 0x7b
%define ERRORWORD 0x0446
%define CLEARCHAR 0xf9
%define CLEARBACK 0x07
%define CLEAR (CLEARBACK * 0x100 + CLEARCHAR)
%define DATA_A 0x10
%define DATA_B 0x30
%define DATA_N 0x0f
%define BOARDX 0x8
%define BOARDY 0x3
%define BOARDPOS 0x2 * (0x50 * BOARDY + BOARDX)
%define TARGETX 0x20
%define TARGETY 0x15
%define TARGETPOS 0x2 * (0x50 * TARGETY + TARGETX)
	
	jmp begin
times (0x3 - ($ - $$)) nop
drive: db DRIVE	
begin:
	
	;segments
	xor ax, ax
	mov ds, ax
	mov ah, 0xb8
	mov es, ax
	mov ah, STACKHI
	mov sp, ax
	mov bp, sp
	
	;clear
	xor di, di
clear0:
	mov [es:di], word CLEAR
	inc di
	inc di
	cmp di, 0xfa0
	jb clear0
	
	call showdata
	
editboard:
	mov dx, (BOARDY * 0x100 + BOARDX)
editboard0:
	cmp dl, BOARDX + 0x40
	jne editboard1
	inc dh
editboard1:
	sub dx, (BOARDY * 0x100 + BOARDX)
	and dx, 0x0f3f
	add dx, (BOARDY * 0x100 + BOARDX)
	mov ah, 0x2
	int 0x10
	call key
	cmp ah, 0x3b
	je edittarget
	jmp editboard0
	
edittarget:
	mov dl, TARGETX
edittarget0:
	mov dh, TARGETY
	sub dl, TARGETX
	and dl, 0xf
	add dl, TARGETX
	mov ah, 0x2
	int 0x10
	call key
	cmp ah, 0x1
	je editboard
	jmp edittarget0
	
key:
	xor ah, ah
	int 0x16
	cmp al, 'F'
	jg key0
	cmp al, 'A'
	jge key1
	cmp al, '9'
	jg key0
	cmp al, '0'
	jb key0
key1:
	mov ch, al
	mov ah, 0x8
	int 0x10
	mov bl, ah
	and bl, 0xf0
	xor bl, DATA_N & 0x0f
	mov al, ch
	xor bh, bh
	mov ah, 0x9
	mov cx, 0x1
	int 0x10
	inc dl	
key0:
	cmp ah, 0x4b
	jne key2
	dec dl

key2:
	cmp ah, 0x4d
	jne key3
	inc dl
key3:
	cmp ah, 0x48
	jne key4
	dec dh
	
key4:
	cmp ah, 0x50
	jne key5
	inc dh
key5:
	cmp ah, 0x3f
	jne key6
	;read
	call gettarget
	pusha
	mov ah, 0x42
	mov dl, [ds:drive]
	mov si, dap
	int 0x13
	jc begin
	popa
	call showdata
key6:
	cmp ah, 0x43
	jne key7
	;write
	call gettarget
	mov si, BUFFER
	mov di, BOARDPOS
key6a:
	call readdata
	add di, 0xa0
	add si, 0x20
	cmp si, BUFFER + 0x200
	jb key6a
	pusha
	mov ax, 0x4300
	mov dl, [ds:drive]
	mov si, dap
	int 0x13
	jc begin
	call showdata
	popa
key7:
	cmp ah, 0x1c
	jne key8
	;function
	cmp [ds:BUFFER + 0x1fe], word 'FN'
	jne key8
	pusha
	call FUNCTION
	mov ax, 0x500
	int 0x10
	popa
key8:
	ret
	
gettarget:
	mov si, sector
	mov di, TARGETPOS
	call readdata
	ret

showdata:
	pusha
	mov si, BUFFER
	mov di, BOARDPOS
	mov bl, 0x20
showdata0:
	call writedata
	add si, 0x20
	add di, 0xa0
	cmp si, BUFFER + 0x200
	jb showdata0
	mov si, sector
	mov di, TARGETPOS
	mov bl, 0x8
	call writedata
	popa
	ret

readdata:
	pusha
readdata0:
	mov al, [es:di]
	cmp al, CLEARCHAR
	je readdata1
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
	jmp readdata0	
readdata1:
	popa
	ret
	
writedata:
	pusha
	mov ah, DATA_A
writedata0:
	cmp bl, 0x0
	je writedata1
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
	dec bl
	xor ah, (DATA_A ^ DATA_B) & 0xf0
	jmp writedata0
writedata1:
	popa
	ret
	
nib2txt:
	add al, '0'
	cmp al, '9'
	jbe nib2txt0
	add al, 'A' - '9' - 0x1
nib2txt0:
	ret
	
txt2nib:
	sub al, '0'
	cmp al, 0x9
	jbe txt2nib0
	sub al, 'A' - '9' - 0x1
txt2nib0:
	ret
	
dap:
db 0x10
db 0x0
dw 0x1
dw BUFFER
dw 0x0
sector: dq 0x1

times (0x1be - ($ - $$)) db 0xA3

PARTITION_STATUS: db 0x80
CHS_START: db 0x0, 0x0, 0x0
PARTITION_TYPE: db 0xff
CHS_END: db 0x0, 0x0, 0x0
LBA_START: dd 0x0
VOLUME_SIZE: dd SECTORS

times (0x1fe - ($ - $$)) db 0x00
db 0x55, 0xaa

FUNCTION:
times (0x3fd - ($ - $$)) nop
	ret
db 'FN'

times (SECTORS * 0x200 - ($ - $$)) db 0x00
