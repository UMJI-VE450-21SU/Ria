#include "ExecLib.h"
#define N 5

char buf[100] = {0};
reg_t tohost = 0;
reg_t fromhost = 0;
reg_t tohost_cmd[8] = {0};

int sum(int* a) {
  int result = 0;
  for (unsigned int i = 0; i < N; i++)
    result += a[i];
  return result;
}

int main() {
  int a[N] = {1, 2, 3, 4, 5};

  int result = sum(a);

  tohost_exit(0);
}
