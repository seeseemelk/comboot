[org 0x0000]
[bits 16]
[cpu 8086]

const_int13_ip equ 0x13 * 4
const_int13_cs equ const_int13_ip + 2

; Entry point to stage2
start:
; Setup segment registers
	mov ax, cs
	mov ds, ax
	mov es, ax
; Print a message
	mov si, msg_hello
	call console_print
; Initialise serial port
	xor ah, ah
	mov al, 0 ; TODO: fill in
	mov dx, 0
	int 0x14
; Send hello packet
	mov al, 1
	mov cl, 0
	call packet_start
	call packet_end
; Store old int13 handler
	xor bx, bx
	mov es, bx
	mov ax, [es:const_int13_ip]
	mov [var_int13_ip], ax
	mov ax, [es:const_int13_cs]
	mov [var_int13_cs], ax
; Write new int13 handler
	mov ax, irq_13
	mov [es:const_int13_ip], ax
	mov ax, cs
	mov [es:const_int13_cs], ax
; Jump back to bootstrap loader
	int 0x19
; Halt and freeze
	mov si, msg_halting
	call console_print
.hang:
	cli
	hlt
	jmp start

msg_hello db "Stage 2 loaded", 0xd, 0xa, 0
msg_halting db "Halting", 0xd, 0xa, 0
var_int13_ip dw 0
var_int13_cs dw 0

; Starts sending a packet.
; Parameters:
;  al = The type of packet to send.
;  cl = The number of bytes to send.
packet_start:
; Reset checksum
	mov byte [var_packet_c0], 0
	mov byte [var_packet_c1], 0
; Send packet type
	call packet_send_byte
; Send packet length
	mov al, cl
	call packet_send_byte
	ret

; Ends a packet
packet_end:
	mov al, byte [var_packet_c0]
	call packet_send_byte_raw
	mov al, byte [var_packet_c1]
	call packet_send_byte_raw
	ret

; Sends packet data.
; Parameters:
;  si = Pointer to the data to send.
;  cl = Number of bytes to transmit.
packet_send_data:
	test cl, cl
	jz .skiploop
.loop:
	lodsb
	call packet_send_byte
	loop .loop
.skiploop:
	ret

; Sends a byte over uart.
; Use packet_send_byte_raw to send a byte without updating checksums.
; Parameters:
;  al = The byte to send.
packet_send_byte:
	call packet_checksum_update
packet_send_byte_raw:
	push ax
	push dx
	mov ah, 0x01
	mov dx, 0
	int 0x14
	pop dx
	pop ax
	ret

; Updates the packet checksum with a byte.
; Parameters:
;  al = The byte to update the checksum with
packet_checksum_update:
	push ax
; Update C0
	mov ah, byte [var_packet_c0]
	add ah, al
	adc ah, 0
	mov byte [var_packet_c0], ah
; Update C1
	add byte [var_packet_c1], ah
	adc byte [var_packet_c1], 0
	pop ax
	ret

var_packet_c0 db 0
var_packet_c1 db 0

; Handle requests for int 0x13
irq_13:
; If AH = 2, let's run our custom read routine.
	cmp ah, 2
	je .read
; Else, run the default handler.
.default:
	jmp far [cs:var_int13_ip]
.read:
; Store the simple information
	mov [cs:var_int13_sector_count], al
	mov [cs:var_int13_head], dh
	mov [cs:var_int13_drive], dl
; Store the sector number
	mov al, cl
	and al, 0b0011_1111
	mov [cs:var_int13_sector], al
; Store the cylinder number
	mov ax, cx
	mov cl, 6
	shr ax, cl
	mov [cs:var_int13_cylinder], ax
; Send the packet header
	mov al, 2
	mov cl, 6
	call packet_start
; Send the packet body
; Drive
	mov al, [var_int13_drive]
	call packet_send_byte
; Sector count
	mov al, [var_int13_sector_count]
	call packet_send_byte
; Cylinder (low)
	mov ax, [var_int13_cylinder]
	call packet_send_byte
; Cylinder (high)
	mov al, ah
	call packet_send_byte
; Sector
	mov al, [var_int13_sector]
	call packet_send_byte
; Head
	mov al, [var_int13_head]
	call packet_send_byte
; Send the packet trailer
	call packet_end
	iret

var_int13_sector_count db 0
var_int13_cylinder dw 0
var_int13_sector db 0
var_int13_head db 0
var_int13_drive db 0

%include "print.asm"
