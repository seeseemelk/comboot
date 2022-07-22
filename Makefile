NASM := nasm

SRC := src/main/asm
BIN := bin/asm
IMAGE := $(BIN)/comboot.img
STAGE1 := $(BIN)/stage1.bin
STAGE2 := $(BIN)/stage2.bin

FLAGS := -w+error -g -I$(SRC) -I$(BIN)

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	rm -rf $(BIN)

.PHONY: emulate
emulate: $(IMAGE)
	qemu-system-i386 -drive file=$(IMAGE),if=floppy,format=raw -serial tcp::4444,server -gdb tcp::1234,server

$(IMAGE): $(STAGE1) $(STAGE2)
	cp $(STAGE1) $(IMAGE)

$(STAGE1): $(STAGE2)

$(BIN)/%.bin: $(SRC)/%.asm $(BIN)/.mkdir
	nasm -fbin $(FLAGS) -o $@ -MD $@.d $<

$(BIN)/.mkdir:
	mkdir -p $(dir $@)
	touch $@

-include $(BIN)/stage1.asm.d
-include $(BIN)/stage2.asm.d
