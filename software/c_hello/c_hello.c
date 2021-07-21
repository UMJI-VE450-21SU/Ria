#define N 14

char msg[N] = "Hello World!\n";

int main(void) {
  int i = 0;
  for (i = 0; i < N - 1; i++) {
    asm volatile("sw %0, -8(x0)" :: "r"(msg[i]));
  }
  return 0;
}
