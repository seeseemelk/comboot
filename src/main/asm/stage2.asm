[org 0x0000]
[bits 16]
[cpu 8086]

const_type_hello equ 1
const_type_welcome equ 2
const_type_read equ 3
const_type_data equ 4
const_type_finish equ 5

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
	mov al, const_type_hello
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
; Print waiting message
	mov si, msg_waiting
	call console_print
; Wait for hello back from emulator
	mov al, const_type_welcome
	call packet_wait
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
msg_waiting db "Waiting for emulator", 0xd, 0xa, 0
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

; Variables for managing a packet's checksum.
var_packet_c0 db 0
var_packet_c1 db 0

; Receive a packet.
; Returns:
;  al = The type of packet received.
packet_receive:
	push di
	push cx
	push ax
	push es
; Get pointer to packet buffer
	mov ax, ds
	mov es, ax
	mov di, var_packet_buffer
; Store type
	call packet_receive_byte
	stosb
; Store length
	call packet_receive_byte
	stosb
; Store length in CL
	xor ch, ch
	mov cl, al
; Fetch all other bytes
	test cl, cl
; If there are no bytes to copy, don't loop
	jz .endloop
; Receive each byte and store it in the buffer
.loop:
	call packet_receive_byte
	stosb
	loop .loop
.endloop:
; Store checksum
	call packet_receive_byte_raw
	stosb
	call packet_receive_byte_raw
	stosb
; Return from function
	pop es
	pop ax
	pop cx
	pop di
	ret

; Receive a packet and handle it.
; Returns:
;  al = The type of packet received.
packet_receive_and_handle:
; Receive packet
	call packet_receive
; Execute handler depending on type
	cmp al, const_type_welcome
	jne .skip1
	call packet_handle_welcome
.skip1:
	cmp al, const_type_data
	jne .skip2
	call packet_handle_data
.skip2:
; Return from function
	ret

; Receive a single byte from UART and update the checksum calculation
; Returns:
;  al = The byte that was read
packet_receive_byte:
	call packet_receive_byte_raw
	jmp packet_checksum_update

; Receive a single byte from UART
; Returns:
;  al = The byte that was read
packet_receive_byte_raw:
	push dx
; Wait for a byte to be available
	call wait_for_data
; Receive a byte
	mov ah, 2
	xor al, al
	xor dx, dx
	int 0x14
; Return from function
	pop dx
	ret

; Wait for a packet
; Parameters:
;  al = The type of packet to wait for
packet_wait:
	push ax
	push dx
; Store packet type in dl
	mov dl, al
.loop:
; Receive a packet
	call packet_receive_and_handle
; If the packet was of the wrong type, try again
	cmp al, dl
	jne .loop
.endloop:
	pop dx
	pop ax
	ret

; Wait for a byte of data to be received.
wait_for_data:
	push ax
	push dx
; Prepare registers for interrupt
	xor dx, dx
; Get uart status
.loop:
	mov ah, 3
	xor al, al
	int 0x14
; If receive_data_ready is not set, loop again
	test ah, 0x01
	jz .loop
; Return from function
	pop dx
	pop ax
	ret

; Handles the welcome packet.
packet_handle_welcome:
	push ax
	push es
; Set ES segment
	mov ax, 0x40
	mov es, ax
; Modify BDA
	mov ax, [var_welcome_disks]
	mov [es:0x75], ax
; Restore ES and return from function
	pop es
	pop ax
	ret

; Handles the data packet
packet_handle_data:
	push cx
	push di
	push si
	push ax
; Get number of bytes of data read
	xor ch, ch
	mov cl, [var_packet_length]
; Set destination in ES:DI
	mov di, [var_packet_data_destination]
; Set source in DS:SI
	mov si, var_packet_content
; Copy all bytes
.loop:
	lodsb
	stosb
	loop .loop
; Store the new destination
	mov [var_packet_data_destination], di
; Return from function
	pop ax
	pop si
	pop di
	pop cx
	ret

; Buffer for receiving buffer.
var_packet_buffer:
var_packet_type db 0
var_packet_length db 0
; Packet contents
var_packet_content:
var_welcome_floppies:
db 0
var_welcome_disks:
db 0
; Rest of the packet
times 258-($ - var_packet_content) db 0

; Handle requests for int 0x13
irq_13:
; If AH = 2, let's run our custom read routine.
	cmp ah, 2
	je .read
; Else, run the default handler.
.default:
	jmp far [cs:var_int13_ip]
.read:
; Only execute this routine if we're attempting to access the floppy drive.
; Otherwise we run the default routine.
	cmp dl, 0
	jne .default
; Backup registers
	push ds
	push dx
	push cx
	push bx
; Store some information *before* setting the segment registers as we don't
; want to clobber ax
	mov [cs:var_int13_sector_count], al
; Set segment registers
	mov ax, cs
	mov ds, ax
; Store the simple information
	mov [var_int13_head], dh
	mov [var_int13_drive], dl
; Store the sector number
	mov al, cl
	and al, 0b0011_1111
	mov [var_int13_sector], al
; Store the cylinder number
	mov ax, cx
	mov cl, 6
	shr ax, cl
	mov [var_int13_cylinder], ax
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
; Set location data will be sent to
	mov [var_packet_data_destination], bx
; Wait for finish packet
	mov al, const_type_finish
	call packet_wait
; Clear carry to indicate no error
	clc
; Set status to success
	mov ah, 0
; Set number of sectors transferred
	mov al, [var_int13_sector_count]
; Restore register
	pop bx
	pop cx
	pop dx
	pop ds
	iret

var_int13_sector_count db 0
var_int13_cylinder dw 0
var_int13_sector db 0
var_int13_head db 0
var_int13_drive db 0
var_packet_data_destination dw 0

%include "print.asm"
