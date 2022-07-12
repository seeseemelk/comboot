; Packet format
; Each packet has the following format:
;   DEST TYPE LENGTH CONTENTS CHECKSUM
; DEST, TYPE, LENGTH are single byte values.
; CONTENTS has a length equal to the value of LENGTH.
; CHECKSUM is a Fletcher-16 checksum.
;
; Possibles types:
;  00 = ping
;  01 = pong
;  02 = hello
;
; Example messages:
;  hello:
;   01 02 00 03 07

0 0
1 1
3 4
3 7


; Sends a packet over uart.
; Parameters:
;  si = The contents of the packet to send.
;  cl = The number of bytes to send.
;  ah = The type of packet to send.
;  al = The target system for the packet.
send_packet:
	mov dx, ax
	; Send the destination
	call send_uart_byte
	; Send the packet type
	mov al, ah
	call send_uart_byte
	; Send the packet length
	mov al, cl
	call send_uart_byte
	; Send the packet itself
	call send_uart_string
	ret


; Sends a string over uart.
; Parameters:
;  si = The contents of the packet to send.
;  cl = The number of bytes to send.
; Returns:
;  ax = Checksum for the packet
send_uart_string:
	push cx
	pushd dx
	xor dx, dx
	test cl, cl
	jz .skip
	.loop:
		lodsb
		call send_uart_byte
		add dh, dl
		add dl, al
		loop .loop
	.skip:
	pop dx
	pop cx
	ret

; Sends a byte over uart.
; Parameters:
;  al = The byte to send.
send_uart_byte:
	push ax
	push dx
	mov ah, 0x01
	mov dx, [serial_port]
	int 0x14
	pop dx
	pop ax
	ret
