.section    .start
.global     _start

_start:
  li    sp, 0x10000600
  jal   main
  j     halt

halt:
  #li    t1, 1
  #sw    t1, -4(x0)
  j     halt
