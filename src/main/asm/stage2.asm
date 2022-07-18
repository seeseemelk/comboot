[org 0x0000]
[bits 16]
[cpu 8086]

const_type_hello equ 1
const_type_boot equ 2
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
; Wait for boot message from emulator
	mov al, const_type_boot
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
	push ax
; Reset checksum
	mov byte [var_packet_c0], 0
	mov byte [var_packet_c1], 0
; Send packet type
	call packet_send_byte
; Send packet length
	mov al, cl
	call packet_send_byte
	pop ax
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
	adc ah, 1 ; These three instruction are just a fancy way of calculating "mod 255"
	adc ah, 0
	dec ah
	mov byte [var_packet_c0], ah
; Update C1
	mov al, [var_packet_c1]
	add al, ah
	adc al, 1
	adc al, 0
	dec al
	mov [var_packet_c1], al

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
; Prepare return from function
	pop es
	pop ax
	pop cx
	pop di
; Get return value
	mov al, [var_packet_type]
	ret

; Receive a packet and handle it.
; Returns:
;  al = The type of packet received.
packet_receive_and_handle:
; Receive packet
	call packet_receive
; Execute handler depending on type
	cmp al, const_type_boot
	jne .skip1
	call packet_handle_boot
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

; Handles the boot packet.
packet_handle_boot:
	push ax
	push es
; Set ES segment
	mov ax, 0x40
	mov es, ax
; Modify BDA
	mov ax, [var_boot_disks]
	mov [es:0x75], ax
; Restore ES and return from function
	pop es
	pop ax
	ret

; Handles the data packet
packet_handle_data:
;	call debug_dot
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
;	call debug_dot
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

;debug_dot:
;	push si
;	mov si, msg_dot
;	call console_print
;	pop si
;	ret

msg_dot db ".", 0

; Buffer for receiving buffer.
var_packet_buffer:
var_packet_type db 0
var_packet_length db 0
; Packet contents
var_packet_content:
var_welcome_floppies:
	db 0
var_boot_disks:
	db 0
; Rest of the packet
times 258-($ - var_packet_content) db 0

var_execution_count db 2

; Handle requests for int 0x13
irq_13:
; If AH = 0 (reset), let's just run the default handler
	cmp ah, 0
	je .default
; If AH = 1 (status), let's run our custom status routine.
	cmp ah, 1
	je .status
; If AH = 2 (read), let's run our custom read routine.
	cmp ah, 2
	je .read
; If AH = 3 (write), let's run our custom write routine.
	cmp ah, 3
	je .write
; If AH = 4 (verify), let's run our custom routine.
	cmp ah, 4
	je .verify
; If AH = 8 (parameters), let's run our custom routine
	cmp ah, 8
	je .parameters
; If AH = 0x15 (disk type), let's run our custom routine
	cmp ah, 0x15
	je .disk_type
; Any unsupported operations should panic
	mov al, ah
	call debug_unsupported
.status:
	cmp dl, 0
	jne .default
	call debug_unsupported
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
; Set segment registers without modifying AX
	push cs
	pop ds
; Store the simple information
	mov [var_int13_sector_count], al
	mov [var_int13_head], dh
	mov [var_int13_drive], dl
; Store the sector number
	mov al, cl
	and al, 0b0011_1111
	mov [var_int13_sector], al
; Store the cylinder number
	mov ah, cl
	mov cl, 6
	shr ah, cl
	mov al, ch
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
	xor ah, ah
; Set number of sectors transferred
	mov al, [var_int13_sector_count]
; Restore register
	pop bx
	pop cx
	pop dx
	pop ds
	iret
.write:
; Set result code to read protected
	stc
	mov ah, 0x03
	mov al, 0
	iret
.verify:
; If accessing the hard drive, run default handler
	cmp dl, 0x80
	jge .default
; Set return value
	mov ah, 0
	clc
	iret
.parameters:
; If accessing the hard drive, run default handler
	cmp dl, 0x80
	jge .default
; Set return value
	xor ax, ax
	mov bl, 4
	mov dh, 2
	mov dl, 1
	mov cx, 0x50_3F
	clc
	iret
.disk_type:
; If accessing the hard drive, run default handler
	cmp dl, 0x80
	jge .default
; Set return value
	mov ah, 1
	mov dx, 0xb40
	xor cx, cx
	clc
	iret
; Default handler just jumps to the original handler.
.default:
	jmp far [cs:var_int13_ip]

var_int13_sector_count db 0
var_int13_cylinder dw 0
var_int13_sector db 0
var_int13_head db 0
var_int13_drive db 0
var_packet_data_destination dw 0

; Print the message 'Unsupported operation', followed by the hexadecimal
; value of AL.
; This function does not return.
; Parameters:
;  al = The value to print.
debug_unsupported:
	push cs
	pop ds

	mov bl, al
	and bx, 0xF
	mov bl, [hex_to_ascii + bx]
	mov [msg_unsupported_low], bl

	mov bl, al
	mov cl, 4
	shr bl, cl
	and bx, 0xF
	mov bl, [hex_to_ascii + bx]
	mov [msg_unsupported_high], bl

	mov si, msg_unsupported
	call console_print
.hang:
	hlt
	jmp .hang

; The message "Unsupported operation"
msg_unsupported db "Unsupported operation: "
msg_unsupported_high db "?"
msg_unsupported_low db "?"
db 0xD, 0xA, 0

; Lookup table to convert hex values into ascii
hex_to_ascii db "0123456789ABCDEF"

; Prints the message "!test!".
; Useful to quickily test things.
; This function does not return.
debug_test:
	mov ax, cs
	mov ds, ax
	mov si, msg_test
	call console_print
.hang:
	hlt
	jmp .hang
msg_test db "!test!", 0xD, 0xA, 0

%include "print.asm"
