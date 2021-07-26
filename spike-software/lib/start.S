.section .text
.global _start
_start:
    li sp, 0x20000000
    j main
