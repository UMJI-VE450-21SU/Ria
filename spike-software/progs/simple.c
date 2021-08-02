#include "ExecLib.h"
#define N 5

char buf[5] = {0};
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
  int a[N];
  for (unsigned int i = 0; i < N; i++)
    a[i] = i;

  int result = sum(a);

  return 0;
}
