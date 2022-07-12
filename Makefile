NASM := nasm
SRC_DIR := src
BIN_DIR := bin
IMAGE := $(BIN_DIR)/comboot.img

CREATE_DIRS := $(BIN_DIR)/.create
SRC_C := $(wildcard $(SRC_DIR)/*.c)
OBJ_C := $(SRC_C:$(SRC_DIR)/%.c=$(BIN_DIR)/%.o)
DEP_C := $(SRC_C:$(SRC_DIR)/%.c=$(BIN_DIR)/%.d)
COMBOOT_STAGE2 = $(BIN_DIR)/comboot_stage2.bin

COMMONFLAGS =
CFLAGS = $(COMMONFLAGS) -0 -we -zl -s -ms
LDFLAGS = $(COMMONFLAGS)
CC = wcc
LD = wlink

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	rm -rf $(BIN_DIR)

.PHONY: emulate
emulate: $(IMAGE)
	qemu-system-i386 -drive file=$(IMAGE),if=floppy,format=raw -serial stdio

$(IMAGE): $(SRC_DIR)/boot.asm $(COMBOOT_STAGE2) $(CREATE_DIRS)
	nasm -fbin -w+error -g -o $(@:$(SRC_DIR)/%=$(BIN_DIR)/%) -MD $(<:$(SRC_DIR)/%=$(BIN_DIR)/%).d $<

$(COMBOOT_STAGE2): linker.lnk $(OBJ_C)
	$(LD) file bin/test.o @linker.lnk

$(BIN_DIR)/%.o: $(SRC_DIR)/%.c $(CREATE_DIRS)
	$(CC) $(CFLAGS) -ad=$(@:%.o=%.d) -add=$< -adt=$@ -fo=$@ $<

%/.create:
	mkdir -p $(dir $@)
	touch $@

-include $(BIN_DIR)/boot.asm.d
-include $(DEP_C)
