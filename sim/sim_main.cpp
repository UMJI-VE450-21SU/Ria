// Project: RISC-V SoC Microarchitecture Design & Optimization
//          Verilator simulation
// Author:  Yichao Yuan, Li Shi
// Date:    2021/07/02

#include <iostream>
#include <memory>
#include <verilated.h>
#include "Vtop.h"

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env) {
  // This is a more complicated example, please also see the simpler examples/make_hello_c.

  std::cout << "the arguments are :" << std::endl;
  for (int i = 0; argv[i]; ++i) {
    std::cout << argv[i] << " ";
  }

  std::cout << std::endl;
  // Prevent unused variable warnings
  if (false && argc && argv && env) {}

  Verilated::mkdir("logs");

  const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

  // Set debug level, 0 is off, 9 is highest presently used
  // May be overridden by commandArgs argument parsing
  contextp->debug(0);

  // Randomization reset policy
  // May be overridden by commandArgs argument parsing
  contextp->randReset(2);

  // Verilator must compute traced signals
  contextp->traceEverOn(true);

  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  contextp->commandArgs(argc, argv);

  // Construct the Verilated model, from Vtop.h generated from Verilating "top.v".
  // Using unique_ptr is similar to "Vtop* top = new Vtop" then deleting at end.
  // "TOP" will be the hierarchical name of the module.
  const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};


  // Simulate until $finish
  while (!contextp->gotFinish()) {
    contextp->timeInc(1);  // 1 timeprecision period passes...
    top->clock = !top->clock;
    top->eval();

    if (contextp->time() > 500) break;
  }

  // Final model cleanup
  top->final();

  // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
  Verilated::mkdir("logs");
  contextp->coveragep()->write("logs/coverage.dat");
#endif

  return 0;
}
