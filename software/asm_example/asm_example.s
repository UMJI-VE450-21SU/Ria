# .section    .start
# .global     _start

_text:
  addi  x0, x0, 0
  jal   x0, main

intmul:
  add   t1, x0, a1
  jal   x0, loop1

loop1:
  add   t2, t2, a0
  addi  t1, t1, -1
  beq   t1, x0, exit
  jal   x0, loop1

main:
  addi  t2, x0, 0
  addi  a0, x0, 120   # first parameter in the multiplication
  addi  a1, x0, 6     # second parameter in the multiplication
  jal   ra, intmul

exit:
  sw    t2, 4(x0)
  addi  t1, x0, 72    # H
  sw    t1, -8(x0)
  addi  t1, x0, 101   # e
  sw    t1, -8(x0)
  addi  t1, x0, 108   # l
  sw    t1, -8(x0)
  addi  t1, x0, 108   # l
  sw    t1, -8(x0)
  addi  t1, x0, 111   # o
  sw    t1, -8(x0)
  addi  t1, x0, 32    # Space
  sw    t1, -8(x0)
  addi  t1, x0, 87    # W
  sw    t1, -8(x0)
  addi  t1, x0, 111   # o
  sw    t1, -8(x0)
  addi  t1, x0, 114   # r
  sw    t1, -8(x0)
  addi  t1, x0, 108   # l
  sw    t1, -8(x0)
  addi  t1, x0, 100   # d
  sw    t1, -8(x0)
  addi  t1, x0, 10    # \n
  sw    t1, -8(x0)
  jal   x0, halt

halt:
  addi  t1, x0, 1
  sw    t1, -4(x0)
  jal   x0, halt
