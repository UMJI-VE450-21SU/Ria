#ifndef EXECLIB_H
#define EXECLIB_H
#include <stdint.h>

typedef uint64_t reg_t;
#define CASTPTR(ptr) (unsigned)(ptr)

#define RISCV_AT_FDCWD -100
#define SYSCALL_OPENAT 56
#define SYSCALL_CLOSE 57

#define SYSCALL_READ 63
#define SYSCALL_WRITE 64

#define SYSCALL_EXIT 93 

// self-defined syscalls
#define SYSCALL_PRINTSTR 2012

// I am not sure whether these values are all the same among all platform
#define O_RDONLY 00000000
#define O_WRONLY 00000001
#define O_RDWR 00000002

#define O_CREAT 00000100 


extern reg_t tohost;
extern reg_t fromhost;
extern reg_t tohost_cmd[8];

// helper if only I instruction set is implemented 
reg_t strlen_e(char *str);
reg_t get_digit(reg_t base, reg_t val);
reg_t mul(reg_t a, reg_t b);
void uint64_to_str(reg_t val, char *dest);

// syscalls
void tohost_exit(reg_t code);
void tohost_printstr(char *str);
reg_t tohost_open(char *file, reg_t flag);
reg_t tohost_close(reg_t fd);
reg_t tohost_write(reg_t fd, char *pbuf, reg_t len);
reg_t tohost_read(reg_t fd, char *pbuf, reg_t len);


void send_syscall();

#endif /* EXECLIB_H */
