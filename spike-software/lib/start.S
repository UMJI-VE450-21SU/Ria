.section .bss
.global tohost
.global fromhost
.align 8
tohost: 
.skip 8, 0
.align 8
fromhost:
.skip 8, 0
.section .text
.global _start
_start:
    li sp, 0x20000000
    jal main
    slli t0, a0, 1
    ori t0, t0, 1
    la t1, tohost
    sw t0, 0(t1)
wait:
    j wait
