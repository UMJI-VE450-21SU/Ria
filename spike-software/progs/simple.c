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
  tohost_printstr(str0);

  tohost_exit(0);
}
