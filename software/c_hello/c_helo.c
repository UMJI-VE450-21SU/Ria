#define N 13

char msg[N] = "Hello World!";

int main(void) {
  int i = 0;
  for (i = 0; i < N; i++) {
    asm volatile("sw %0, -8(x0)" :: "r"(msg[i]));
  }
  return 0;
}
