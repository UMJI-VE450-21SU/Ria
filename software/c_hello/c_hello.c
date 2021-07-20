#define N 7

char msg[N] = "Hello\n";

int main(void) {
  int i = 0;
  // for (i = 0; i < N - 1; i++) {
  //   asm volatile("sw %0, -8(x0)" :: "r"(msg[i]));
  // }
  asm volatile("sw %0, -8(x0)" :: "r"(msg[0]));
  asm volatile("sw %0, -8(x0)" :: "r"(msg[1]));
  asm volatile("sw %0, -8(x0)" :: "r"(msg[2]));
  asm volatile("sw %0, -8(x0)" :: "r"(msg[3]));
  asm volatile("sw %0, -8(x0)" :: "r"(msg[4]));
  asm volatile("sw %0, -8(x0)" :: "r"(msg[5]));
  return 0;
}
