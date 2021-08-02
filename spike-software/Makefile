RISCV := riscv64-unknown-elf

PROGS_PATH := progs

LIB_PATH := lib
LIB_OBJECT := $(patsubst %.c, %.o, $(wildcard $(LIB_PATH)/*.c))
LIB_OBJECT += $(patsubst %.S, %.o, $(wildcard $(LIB_PATH)/*.S))

OUTPUT_PATH := out

LDSCRIPT := common.ld

GCC_OPTS := -mabi=ilp32 -march=rv32i -nostdlib -nostartfiles -I$(LIB_PATH)

LD_OPTS := -m elf32lriscv

TARGETS := \
  moreThanExit \
  sobel \
	simple

TARGETS_ELF := $(foreach target, $(TARGETS), $(target).elf)

default: $(TARGETS_ELF)

# how to make it output to a directory?
%.elf : $(PROGS_PATH)/%.o $(LIB_OBJECT)
	$(RISCV)-ld  $(LD_OPTS) -T $(LDSCRIPT) $^ $(wildcard $(LIB_PATH)/*.o) -o $@
	$(RISCV)-objdump -D $@ > $@.dump

%.o : %.c
	$(RISCV)-gcc $(GCC_OPTS) -o $@ -c $^

%.o : %.S
	$(RISCV)-gcc $(GCC_OPTS) -o $@ -c $^





.PHONY: clean clean-library clean-progs library

clean: clean-library clean-progs
	rm -f *.elf
	rm -f *.dump

clean-library:
	rm -f $(LIB_PATH)/*.o

clean-progs:
	rm -f $(PROGS_PATH)/*.o
