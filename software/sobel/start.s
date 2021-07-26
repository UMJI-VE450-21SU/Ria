.section    .start
.global     _start

_start:
    li      sp, 0x8000fff0
    jal     main
