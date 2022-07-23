[org 0x0000]
[bits 16]
[cpu 8086]

struc DriveParameter
	dp_drive resb 1
	dp_heads_per_track resb 1
	dp_sectors_per_track resb 1
	dp_num_tracks resb 2
endstruc

const_type_hello equ 1
const_type_boot equ 2
const_type_read equ 3
const_type_data equ 4
const_type_finish equ 5
const_type_parameters equ 6
const_type_write equ 7

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
	push ax
	mov al, byte [var_packet_c0]
	call packet_send_byte_raw
	mov al, byte [var_packet_c1]
	call packet_send_byte_raw
	pop ax
	ret

; Sends packet data.
; Parameters:
;  si = Pointer to the data to send.
;  cl = Number of bytes to transmit.
packet_send_data:
	xor ch, ch
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
; If type == BOOT
	cmp al, const_type_boot
	jne .skip1
	call packet_handle_boot
	ret
.skip1:
; If type == DATA
	cmp al, const_type_data
	jne .skip2
	call packet_handle_data
	ret
.skip2:
; If type == PARAMETERS
	cmp al, const_type_parameters
	jne .skip3
	call packet_handle_parameters
	ret
.skip3:
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

; Handles the parameters packet
packet_handle_parameters:
	push bx
	push dx
; Get the disk parameters for the modified drive.
	mov dl, [var_parameters_disk]
	call drive_get_dp_struct
; If null, just jump to the end
	test bx, bx
	jz .end
; Mark the disk as virtual
	mov byte [bx + dp_drive], 0xFF
; Copy values from packet to disk parameter
;  Number of heads
	mov dl, [var_parameters_heads_per_track]
	mov [bx + dp_heads_per_track], dl
;  Sectors per track
	mov dl, [var_parameters_sectors_per_track]
	mov [bx + dp_sectors_per_track], dl
;  Number of tracks
	mov dx, [var_parameters_num_tracks]
	mov [bx + dp_num_tracks], dx
.end:
; Return from function
	pop dx
	pop bx
	ret

;debug_dot:
;	push si
;	mov si, msg_dot
;	call console_print
;	pop si
;	ret

;msg_dot db ".", 0

var_dp_a istruc DriveParameter
	at dp_drive, db 0
iend
var_dp_b istruc DriveParameter
	at dp_drive, db 1
iend
var_dp_c istruc DriveParameter
	at dp_drive, db 0x80
iend

; Gets the DP struct for a drive.
; Parameters:
;  dl = Drive number
; Returns:
;  bx = Pointer to drive struct.
drive_get_dp_struct:
	cmp dl, 0
	je .drive_a
	cmp dl, 1
	je .drive_b
	cmp dl, 0x80
	je .drive_c
; No drive found
	xor bx, bx
	ret
.drive_a:
	mov bx, var_dp_a
	ret
.drive_b:
	mov bx, var_dp_b
	ret
.drive_c:
	mov bx, var_dp_c
	ret

; Converts a drive id into an original drive id.
; Parameters:
;  dl = The drive number
; Returns:
;  dl = The converted drive number
drive_convert_id:
	push bx
; Get the drive parameters.
	call drive_get_dp_struct
; Get the target drive.
	mov dl, [cs:bx + dp_drive]
; Return from function
	pop bx
	ret

; Tests if a drive is a real drive.
; Parameters:
;  dl = Drive number
; Returns:
;  dl = if real, the converted drive number.
;       if virtual, the original value.
;  cf set if real
;  cf unset if virtual
drive_is_real:
; Test if drive number is one that could be virtual
	cmp dl, 0
	je .possible
	cmp dl, 1
	je .possible
	cmp dl, 0x80
	je .possible
; Else it is definitly real
	jmp .real
; It could be virtual, needs more definite test
.possible:
; Get the target drive
	push dx
	call drive_convert_id
; If it is 0xFF, it is emulated.
	cmp dl, 0xFF
	je .pop_virtual
; Else, adjust the stack to compensate for the DX value that was pushed.
	add sp, 2
; It is real
.real:
	stc
	jmp .return
.pop_virtual:
; Pop the original value off again.
	pop dx
; It is virtual
.virtual:
	clc
; Return from function
.return:
	ret

; Buffer for receiving buffer.
var_packet_buffer:
var_packet_type db 0
var_packet_length db 0
; Packet contents
var_packet_content:
var_boot_floppies:
var_parameters_disk:
	db 0
var_boot_disks:
var_parameters_heads_per_track:
	db 0
var_parameters_sectors_per_track:
	db 0
var_parameters_num_tracks:
	db 0
	db 0
; Rest of the packet
times 258-($ - var_packet_content) db 0

; Handle requests for int 0x13
irq_13:
; If AH = 0 (reset), let's just our custom reset routine
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
; If AH = 5 (format), let's run our costum routine.
	cmp ah, 5
	je .format
; If AH = 8 (parameters), let's run our custom routine
	cmp ah, 8
	je .parameters
; If AH = 0x15 (disk type), let's run our custom routine
	cmp ah, 0x15
	je .disk_type
; If AH = 0x17 (media type for format, floppy), let's just run the default routine
	cmp ah, 0x17
	je .default
; If AH = 0x18 (media type for format), let's just run the default routine
	cmp ah, 0x18
	je .default
; Any unsupported operations should panic
	mov al, ah
	call debug_unsupported
.reset:
; If the drive is real, we should run the default handler.
	call drive_is_real
	jc .default
; Virtual drive -> return success code
	xor ah, ah
	clc
	iret
.status:
; If the drive is real, we should run the default handler.
	call drive_is_real
	jc .default
	call debug_unsupported
.read:
; If the drive is real, we should run the default handler.
	call drive_is_real
	jc .default
; Backup registers
	push ds
	push dx
	push cx
	push bx
	push si
; Set segment registers without modifying AX
	push cs
	pop ds
; Store location data will be written to
	mov [var_packet_data_destination], bx
; Calculate the LBA address
	call drive_get_dp_struct
	call calculate_lba
; Send the packet header
	mov al, 2
	mov cl, 6
	call packet_start
; Send drive number
	mov al, [var_int13_drive]
	call packet_send_byte
; Send sector count
	mov al, [var_int13_sector_count]
	call packet_send_byte
; Send LBA
	mov si, var_int13_lba
	mov cl, 4
	call packet_send_data
; Send the packet trailer
	call packet_end
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
	pop si
	pop bx
	pop cx
	pop dx
	pop ds
	iret
.write:
; If the drive is real, we should run the default handler.
	call drive_is_real
	jc .default
; Backup registers
	push ds
	push dx
	push cx
	push bx
	push si
; Set segment registers
	push cs
	pop ds
; Store location data will be read from
	mov [var_packet_data_destination], bx
; Calculate the LBA address
	call drive_get_dp_struct
	call calculate_lba
; Send write packet
	mov al, const_type_write
	;mov cl, 6
	mov cl, 6 + 2 + 1 + 1
	call packet_start
; Send drive number
	mov al, [var_int13_drive]
	call packet_send_byte
; Send sector count
	mov al, [var_int13_sector_count]
	call packet_send_byte
; Send LBA
	mov si, var_int13_lba
	mov cl, 4
	call packet_send_data
; DEBUG - Send CHS
	mov al, [var_int13_cylinder + 0]
	call packet_send_byte
	mov al, [var_int13_cylinder + 1]
	call packet_send_byte
	mov al, [var_int13_head]
	call packet_send_byte
	mov al, [var_int13_sector]
	call packet_send_byte
; Send packet trailer
	call packet_end
; Number of blocks to transfer is in AL
; Number of 128-byte blocks should be in DX.
	xor dh, dh
	mov dl, [var_int13_sector_count]
; Shift left twice in order to multiply by 4 (from 512-byte blocks to 128-byte blocks)
	shl dx, 1
	shl dx, 1
; Load target address into BX again
	mov bx, [var_packet_data_destination]
.send_block:
; Send a block of data
; Send header
	mov al, const_type_data
	mov cl, 128
	call packet_start
; Send 128 bytes of data
	mov cx, 128
.send_byte:
	mov al, [es:bx]
	inc bx
	call packet_send_byte
	loop .send_byte
.end_send_byte:
; Send trailer
	call packet_end
; Check if more blocks need to be sent
	dec dx
	jnz .send_block
.end_send_block:
; Send finish packet
	mov al, const_type_finish
	xor cl, cl
	call packet_start
	call packet_end
; Restore registers
	pop si
	pop bx
	pop cx
	pop dx
	pop ds
; Set results
	mov al, [var_int13_sector_count]
	xor ah, ah
	clc
	iret
; Set result code to read protected
	stc
	mov ah, 0x03
	mov al, 0
	iret
.verify:
; If the drive is real, run the default handler.
	call drive_is_real
	jc .default
; Set return value
	mov ah, 0
	clc
	iret
.format:
; If the drive is real, run the default handler.
	call drive_is_real
	jc .default
; Otherwise, succeed
; Set result
	clc
	xor ah, ah
	iret
.parameters:
; If the drive is real, run the default handler.
	call drive_is_real
	jc .default
; Backup registers
	push ds
	mov [.parameters_bh], bh
; Set segment registers
	push cs
	pop ds
; Get pointer to drive parameters
	call drive_get_dp_struct
; Set return value
;  Low eight bytes of cylinder count
	mov ch, [bx + dp_num_tracks]
;  Sectors per track.
;  TODO - include high two bits of cylinder counter
	mov cl, [bx + dp_sectors_per_track]
;  Heads per cylinder
	mov dh, [bx + dp_heads_per_track]
;  Number of drives
;  TODO - properly calculate this
	mov dl, 1

; 4 means 1.44M drive
	mov bl, 4
; Set AX to 0 to indicate success
	xor ax, ax
	clc
; Restore registers
	mov bh, [.parameters_bh]
	pop ds
	iret
.parameters_bh db 0
.disk_type:
; If the drive is real, run the default handler.
	call drive_is_real
	jc .default
; Hard drives should use the hard drive handler.
	cmp dl, 0x80
	jge .hdd
.floppy:
; Set results for a floppy drive.
	mov ah, 1
	xor dx, dx
	xor cx, cx
	clc
	iret
.hdd:
; Set result for a HDD.
	mov ah, 3
; TODO - Return number of sectors
	xor dx, dx
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
var_int13_lba db 0, 0, 0, 0

; Calculates the LBA address.
; Formula to calculate this is:
;  lba = (cylinder * num_heads + head) * sectors_per_track + (sector - 1)
; Params:
;  AL, CH, CL, DH, DL = contains CHS address.
;  BX = Pointer to disk geometry.
; Returns:
;  LBA value stored in var_int13_lba
calculate_lba:
	push ax
	push bx
	push dx
	push cx

; Store the simple information
	mov [var_int13_sector_count], al
	mov [var_int13_head], dh
	mov [var_int13_drive], dl
; Store the sector number
	mov al, cl
	and al, 0b0011_1111
	mov [var_int13_sector], al
; Store the cylinder number
	;mov ah, cl
	;mov cl, 6
	;shr ah, cl
	xor ah, ah
	mov al, ch
	mov [var_int13_cylinder], ax

; Zero out AX:DX
	xor ax, ax
	xor dx, dx
; Multiply cylinders by number of heads
	mov al, [bx + dp_heads_per_track]
	mov cx, [var_int13_cylinder]
	mul cx
; Add heads
	xor ch, ch
	mov cl, [var_int13_head]
	call add32_16
; Multiply by sectors per track
	mov cl, [bx + dp_sectors_per_track]
	call mul32_16
; Store (sectors - 1) in cx
	mov cl, [var_int13_sector]
	dec cl
; Add them together
	call add32_16
; Write result out
	mov [var_int13_lba + 0], ax
	mov [var_int13_lba + 2], dx
; Return from function
	pop cx
	pop dx
	pop bx
	pop ax
	ret

; Calculates DX:AX = DX:AX * CX
; Parameters:
;   DX:AX = First term
;   CX = Second term
; Returns:
;   DX:AX = Result
mul32_16:
; TODO!! Optimize
	push cx
; Multiply low word
	mul cx
	mov [var_mul_xl], ax
	mov [var_mul_xh], dx
; Multiply high word
	mov ax, dx
	mul cx
	mov [var_mul_yl], ax
; Add high word
	mov dx, [var_mul_xh]
	add dx, [var_mul_yl]
; Load low word
	mov ax, [var_mul_xl]
; Return
	pop cx
	ret
var_mul_xl dw 0
var_mul_xh dw 0
var_mul_yl dw 0

; Calculates DX:AX = DX:AX + CX
; Parameters:
;   DX:AX = First operand
;   CX = Second operand
; Returns:
;   DX:AX = Result
add32_16:
	add ax, cx
	adc dx, 0
	ret

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

log:
	push ds
	push bx
	push cx
	push si

	push cs
	pop ds

	mov bl, al
	and bx, 0xF
	mov bl, [hex_to_ascii + bx]
	mov [msg_log_low], bl

	mov bl, al
	mov cl, 4
	shr bl, cl
	and bx, 0xF
	mov bl, [hex_to_ascii + bx]
	mov [msg_log_high], bl

	mov si, msg_log
	call console_print

	pop si
	pop cx
	pop bx
	pop ds
	ret

; The message "Unsupported operation"
msg_unsupported db "Unsupported operation: "
msg_unsupported_high db "?"
msg_unsupported_low db "?"
db 0xD, 0xA, 0

msg_log db "Log: "
msg_log_high db "?"
msg_log_low db "?"
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
