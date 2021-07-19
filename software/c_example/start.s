.section    .start
.global     _start

_start:
  li    sp, 0x10000600
  jal   main
  j     exit

exit:
  li    t1, 72        # H
  sw    t1, -8(x0)
  li    t1, 101       # e
  sw    t1, -8(x0)
  li    t1, 108       # l
  sw    t1, -8(x0)
  li    t1, 108       # l
  sw    t1, -8(x0)
  li    t1, 111       # o
  sw    t1, -8(x0)
  li    t1, 32        # Space
  sw    t1, -8(x0)
  li    t1, 87        # W
  sw    t1, -8(x0)
  li    t1, 111       # o
  sw    t1, -8(x0)
  li    t1, 114       # r
  sw    t1, -8(x0)
  li    t1, 108       # l
  sw    t1, -8(x0)
  li    t1, 100       # d
  sw    t1, -8(x0)
  li    t1, 10        # \n
  sw    t1, -8(x0)
  j     halt

halt:
  li    t1, 1
  sw    t1, -4(x0)
  j     halt
