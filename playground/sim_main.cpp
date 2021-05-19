//======================================================================
//
// UM-SJTU JI VE450 2021 Summer Capstone Design Project
//
//======================================================================

// For std::unique_ptr
#include <memory>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env) {
    // Prevent unused variable warnings
    if (false && argc && argv && env) {}

    Verilated::mkdir("logs");

    // Construct a VerilatedContext to hold simulation time, etc.
    // Multiple modules (made later below with Vtop) may share the same
    // context to share time, or modules may have different contexts if
    // they should be independent from each other.
    const std::unique_ptr<VerilatedContext> contextp(new VerilatedContext);

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    contextp->debug(0);

    // Verilator must compute traced signals
    contextp->traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    contextp->commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v".
    // "TOP" will be the hierarchical name of the module.
    const std::unique_ptr<Vtop> top(new Vtop(contextp.get(), "TOP"));

    // Set Vtop's input signals
    top->clk = 0;
    top->sel = 0;
    top->data_0 = 0x00000000;
    top->data_1 = 0x11111111;
    top->data_2 = 0x22222222;
    top->data_3 = 0x33333333;

    for (unsigned int i = 0; i < 15; i++) {
        contextp->timeInc(1);  // 1 timeprecision period passes...

        // Toggle a fast (time/2 period) clock
        top->clk = !top->clk;

        // Toggle control signals on an edge that doesn't correspond
        // to where the controls are sampled
        if (!top->clk) {
            top->sel = (i / 2) % 4;
        }

        // Evaluate model
        top->eval();

        // Read outputs
        VL_PRINTF("[%" VL_PRI64 "d] i=%x clk=%x sel=%x data_out=%x\n",
                  contextp->time(), i, top->clk, top->sel, top->data_out);
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
