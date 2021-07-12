all:
	riscv64-unknown-linux-gnu-gcc -mabi=ilp32 -march=rv32i -static -mcmodel=medany -nostdlib -nostartfiles -ffreestanding -c asm_example.s -o asm_example.elf
	riscv64-unknown-linux-gnu-objdump -D -Mnumeric asm_example.elf > asm_example.dump
	riscv64-linux-gnu-objcopy asm_example.elf -O binary asm_example.bin
