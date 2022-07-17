; Provides functions to print stuff to the console.

; Print a string
; Parameters:
;   si = String to print
console_print:
	push ax
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
	pop ax
	ret
