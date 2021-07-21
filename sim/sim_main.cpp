// Project: RISC-V SoC Microarchitecture Design & Optimization
//          Verilator simulation
// Author:  Yichao Yuan, Li Shi
// Date:    2021/07/02

#include <iostream>
#include <memory>
#include <verilated.h>
#include "Vtop.h"

#include "sim_memory.h"
#include "store_buffer.h"

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env) {
  // This is a more complicated example, please also see the simpler examples/make_hello_c.

  std::ios_base::sync_with_stdio(true);
  std::cout << "the arguments are :" << std::endl;
  for (int i = 0; argv[i]; ++i) {
    std::cout << argv[i] << " ";
  }

  std::cout << std::endl;
  // Prevent unused variable warnings
  if (false && argc && argv && env) {}

  Verilated::mkdir("logs");

  const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

  contextp->debug(0);

  contextp->randReset(2);

  contextp->traceEverOn(true);

  contextp->commandArgs(argc, argv);

  const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};

  auto mem = make_BucketMemory();

  mem->load_image_to(std::string{argv[1]}, 0);

  printf("Current memory layout: \n");

  mem->print_all();

  auto imem = std::make_unique<IMem>(mem.get());

  auto dmem = std::make_unique<DMem>(mem.get());

  unsigned char finish_flag = 0;

  char char_print = 0;

  StoreBuffer store_buffer(std::move(dmem));

  // Simulate until $finish
  while (!contextp->gotFinish()) {
    contextp->timeInc(1);  // 1 timeprecision period passes...
    top->clock = !top->clock;

    top->reset = contextp->time() < 4 ? 1 : 0;

    if (contextp->time() >= 4) {
      imem->read_transction(top->core2icache_addr, reinterpret_cast<char *>(top->icache2core_data));
      top->icache2core_data_valid = 1;
      if (top->clock == 1) {
        // When store instructions retire, write data to memory
        if (store_buffer.CommitStoreRequest(__builtin_popcount(top->store_retire)) == -1)
          finish_flag = 1;
        // Branch mis-prediction -> flush store buffer
        if (top->recover)
          store_buffer.FlushStoreBuffer();
        // Execute store instructions -> add store requests to store buffer
        if (top->core2dcache_data_we)
          store_buffer.AddStoreRequest(new store_request_t(top->core2dcache_addr, top->core2dcache_data, top->core2dcache_data_size));
        // Execute load instructions -> first check store buffer then check memory
        else
          store_buffer.LoadData(top->core2dcache_addr, reinterpret_cast<char *>(&(top->dcache2core_data)));
      }
      top->dcache2core_data_valid = 1;
    }

    top->eval();

    printf("[%ld] {dmem} c2d_addr=0x%x, c2d_we=%d, c2d_size=%d, d2c_v=%d, {imem} c2i_addr=0x%x, i2d_v=%d \n", 
        contextp->time(), top->core2dcache_addr, top->core2dcache_data_we, top->core2dcache_data_size, (int) (top->dcache2core_data_valid), 
        top->core2icache_addr, (int)(top->icache2core_data_valid));
    printf("    {dmem} c2d_data=%ld, d2c_data=%ld\n", top->core2dcache_data, top->dcache2core_data); 
    printf("{ctrl} clk=%d, rst=%d\n", top->clock, top->reset);
    printf("{dmem/hex} c2d_data=");
    for(int i = 0; i < 8; ++i) {
      printf("%02x", (unsigned char)(reinterpret_cast<char *>(&(top->core2dcache_data))[i]));
    }
    printf("\n");
    printf("{dmem/hex} d2c_data=");
    for(int i = 0; i < 8; ++i) {
      printf("%02x", (unsigned char)(reinterpret_cast<char *>(&(top->dcache2core_data))[i]));
    }
    printf("\n");
    printf("{imem/hex} i2c_data=");
    for(int i = 0; i < 16; ++i) {
      printf("%02x", (unsigned char)(reinterpret_cast<char *>(top->icache2core_data)[i]));
    }
    printf("\n");

    if (contextp->time() > 1000)
      finish_flag = 1;

    if (finish_flag)
      break;
  }

  printf("Current memory layout: \n");

  mem->print_all();

  // Final model cleanup
  top->final();

  // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
  Verilated::mkdir("logs");
  contextp->coveragep()->write("logs/coverage.dat");
#endif

  return 0;
}
