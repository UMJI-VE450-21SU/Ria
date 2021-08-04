#include "ExecLib.h"

reg_t payload(reg_t reg) {
  return (reg << 16) >> 16;
}

void tohost_exit(reg_t code) {
  while (1) {
    tohost = (code << 1) | 1;
  }
}

void send_syscall() {
  tohost = (reg_t) CASTPTR(tohost_cmd);
  while (!fromhost); 
  fromhost = 0;
}

reg_t strlen_e(char *str) {
  unsigned i = 0;
  while(str[i]) {
    i++;
  }
  return i;
}

void tohost_printstr(char *str) {
  for (unsigned i = 0; i < 8; i++) {
    tohost_cmd[i] = 0;
  }

  tohost_cmd[0] = SYSCALL_PRINTSTR; // sys_printstr()
  tohost_cmd[1] = (reg_t) CASTPTR(str);

  send_syscall();
}

reg_t tohost_open(char *file, reg_t flag) {

  tohost_cmd[0] = SYSCALL_OPENAT; // sys_printstr()
  tohost_cmd[1] = RISCV_AT_FDCWD;
  tohost_cmd[2] = (reg_t) CASTPTR(file);
  tohost_cmd[3] = strlen_e(file) + 1;
  tohost_cmd[4] = flag;
  tohost_cmd[5] = 0777; // give all permission for the mode

  send_syscall();
  
  return tohost_cmd[0];
}

reg_t tohost_close(reg_t fd) {

  tohost_cmd[0] = SYSCALL_CLOSE;
  tohost_cmd[1] = fd;

  send_syscall();
  
  return tohost_cmd[0];
}

reg_t tohost_write(reg_t fd, char *pbuf, reg_t len) {

  tohost_cmd[0] = SYSCALL_WRITE;
  tohost_cmd[1] = fd;
  tohost_cmd[2] = (reg_t) CASTPTR(pbuf);
  tohost_cmd[3] = len;

  send_syscall();
  
  return tohost_cmd[0];
}

reg_t tohost_read(reg_t fd, char *pbuf, reg_t len) {

  tohost_cmd[0] = SYSCALL_READ;
  tohost_cmd[1] = fd;
  tohost_cmd[2] = (reg_t) CASTPTR(pbuf);
  tohost_cmd[3] = len;

  send_syscall();

  return tohost_cmd[0];
}


reg_t get_digit(reg_t base, reg_t val) {
  reg_t i = 0;
  while (val >= base && i < 9) {
    val -= base;
    i++;
  }
  if (val >= base) i = 0;
  return i;
}

reg_t mul(reg_t a, reg_t b) {
  reg_t sum = 0;
  for (reg_t i = 0; i < b; i++) {
    sum += a;
  }
  return sum;
}

void uint64_to_str(reg_t val, char *dest) {
  unsigned d = 0, i = 0, j = 0;
  static unsigned base[100] = {0};
  base[1] = 1;
  for (j = 2; j < 100; j++) {
    base[j] = mul(base[j - 1], 10);
  }
  for (j = 1; base[j] - 1 < val; j++); 
  j--;

  while (val > 0) {
    d = get_digit(base[j], val);
    dest[i++] = '0' + d;
    val -= mul(base[j], d);
    j--;
  }
  if (i == 0) {
    dest[i++] = '0';
  }
  dest[i] = 0;
}
