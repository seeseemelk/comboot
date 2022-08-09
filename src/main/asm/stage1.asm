[bits 16]
[org 0x7C00]
[cpu 8086]

; Entrypoint to stage 1.
; Jump past the configuration variables.
entry:
	jmp start

; START OF CONFIGURATION
serial_port db 0
stage2_sector db 2
stage2_sector_count equ (stage2_end - stage2_start - 1) / 512 + 1
stage2_pages equ (stage2_sector_count - 1) / 2 + 1
; END OF CONFIGURATION

; Proper start of stage 1.
start:
; Store the address of the boot device
	mov byte [var_boot_device], dl
; Print hello message
	mov si, msg_hello
	call console_print
; Calculate address where stage2 should be loaded to
; Target address wil be stored in ES:BX.
; Prepares ES by setting it to 0 so we can read the BDA.
	mov ax, 0x40
	mov es, ax
; read-modify-write the BDA. It contains the number of kib of
; free memory. Stage 2 will be stored at the end of free space.
	mov ax, [es:0x13]
	sub ax, stage2_pages
	mov [es:0x13], ax
; Convert address to segment
	mov cl, 6
	shl ax, cl
; Store calculated addresses. BX will be 0, so only ES
; is of importance.
	mov es, ax
	mov [cs:var_stage2_cs], ax
	xor bx, bx
; Test if we still have retries left.
; If we don't we should print an error.
.retry:
	dec byte [var_retries]
	jz .fail
; Load stage 2
	clc
	mov ah, 2
	mov al, stage2_sector_count
	mov ch, 0
	mov cl, [stage2_sector]
	mov dh, 0
	mov dl, [var_boot_device]
	int 0x13
; If an error was encountered, retry
	jc .retry
; Jump to stage 2
	jmp far [cs:var_stage2_ip]
; Print an error message if an error was encountered
.fail:
	mov si, msg_error
	call console_print
; Hang forever
	cli
.hang:
	hlt
	jmp .hang

%include "print.asm"

msg_hello db 'ComBoot v0.1 - by Seeseemelk', 0xD, 0xA, 0
msg_error db 'Failed to load stage 2', 0xD, 0xA, 0
var_boot_device db 0
var_retries db 3
var_stage2_ip dw 0
var_stage2_cs dw 0

times (510 - ($ - $$)) db 0
db 0x55
db 0xAA

stage2_start:
incbin "stage2.bin"
stage2_end:
