NASM := nasm

IMAGE := comboot.img

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	rm -f boot.asm.d comboot.img

.PHONY: emulate
emulate: $(IMAGE)
	qemu-system-i386 -drive file=$(IMAGE),if=floppy,format=raw -serial stdio

$(IMAGE): boot.asm
	nasm -fbin -w+error -g -o $@ -MD $<.d $<

-include boot.asm.d
