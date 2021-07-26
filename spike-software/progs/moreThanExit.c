#include "ExecLib.h"

char buf[100] = {0};
reg_t tohost = 0;
reg_t fromhost = 0;
reg_t tohost_cmd[8] = {0};

char str0[] = "Test";
char str1[] = "Got file descriptor: ";
char str2[] = "This is a simple message\n";
char str3[] = " from host\n";
char str4[] = "open a file 'Test' and write a message to it\n";
char str5[] = "open the file 'Test' and read its content\n";

int main() {
  tohost_printstr(str4);

  reg_t fd = tohost_open(str0, O_RDWR | O_CREAT);

  tohost_printstr(str1);
  uint64_to_str(fd, buf);
  tohost_printstr(buf);
  tohost_printstr(str3);

  tohost_write(fd, str2, strlen_e(str2));

  tohost_close(fd);

  tohost_printstr(str5);

  fd = tohost_open(str0, O_RDWR);

  tohost_printstr(str1);
  uint64_to_str(fd, buf);
  tohost_printstr(buf);
  tohost_printstr(str3);

  tohost_read(fd, buf, strlen_e(str2));
  buf[strlen_e(str2) + 1] = 0;
  tohost_printstr(buf);

  tohost_close(fd);

  tohost_exit(0);
}
