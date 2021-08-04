ENTRY (_start);
SECTIONS {
  . = 0x10000000;
  .sbss : { * (.sbss); }
  .data : { * (.data); }
  . = 0x80000000;
  .text : { * (.text); }
}
