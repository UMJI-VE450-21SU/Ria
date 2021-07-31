#include "ExecLib.h"

char buf[100] = {0};
reg_t tohost = 0;
reg_t fromhost = 0;
reg_t tohost_cmd[8] = {0};

char hello[] = "Hello\n";

int main() {
  tohost_printstr(hello);

  tohost_exit(0);
}
