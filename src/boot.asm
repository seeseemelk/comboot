[bits 16]
[org 0x7C00]
[cpu 8086]

entry:
jmp start

; START OF CONFIGURATION
serial_port dw 0
; END OF CONFIGURATION

start:

; Print hello message
mov si, msg_hello
call print

; Initialise serial port
xor ah, ah
mov al, 0 ; TODO: fill in
mov dx, [serial_port]
int 0x14

; Send hello to serial port
call send_packet

jmp $

; Print a string
; si = String to print
print:
	push bx
	push si
	mov ah, 0x0e
	mov bl, 0x02
	cld
	.loop:
		lodsb
		test al, al
		jz .endloop
		int 0x10
		jmp .loop
	.endloop:
	pop si
	pop bx
	ret

; Print a string to the serial port.
; si = String to print
send_packet:
	push si
	cld
	.loop:
		lodsb
		test al, al
		jz .endloop
		call write_char
		jmp .loop
	.endloop:
	pop si
	ret

; Writes a character
; al = The character to send.
write_char:
	push ax
	push dx
	mov ah, 0x01
	mov dx, [serial_port]
	int 0x14
	pop dx
	pop ax
	ret

msg_hello db 'cowBOOT v0.1 - by Seeseemelk', 0xD, 0xA, 0

times (510 - ($ - $$)) db 0
db 0x55
db 0xAA