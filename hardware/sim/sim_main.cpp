#include <iostream>

// For std::unique_ptr
#include <memory>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vcore_blank.h"

#include <string>
#include <fstream>
#include <vector>
#include <exception>
#include <cstdint>
//#include <bitset>
#include <ios>
#include <cstdio>
#include <utility>
#include <cassert>

class Icache {
  std::vector<int> icache_mem;

  public:
  Icache(const std::string binName) {
    std::ifstream bin_in{binName, std::ios::binary};
    uint32_t word;
    while(bin_in) {
      bin_in.read(reinterpret_cast<char *>(&word), sizeof word);
      icache_mem.push_back(word);
    } 
  }

  int get_word_from(const unsigned addr) {
    if (addr > icache_mem.size()) 
      throw std::range_error(std::string("icache access out of range, at: ") + std::to_string(addr));
    else 
      return icache_mem[addr];
  }

  unsigned get_mem_size() {return icache_mem.size();}
};

class Dcache {
  std::vector<uint8_t> dcache_mem;
  char outbytes[8];

  public:
  Dcache() = default;

  Dcache(const std::string initFile) {
    init_from_file(initFile);
  }

  void init_from_file(const std::string initFile) {
    // stupid implementation, should know how to use iterator for stream
    std::ifstream bin_in{initFile, std::ios::binary};
    uint8_t byte;
    while(bin_in) {
      byte = 0;
      bin_in.read(reinterpret_cast<char *>(&byte), 1);
      dcache_mem.push_back(byte);
    } 
  }

  void dump_to_file(const std::string dumpFile) {
    std::ofstream dump_out{dumpFile, std::ios::binary};
    for(const auto &i: dcache_mem) {
      dump_out.put(i);
    }
  }

  std::pair<char *, unsigned> get_bytes_from(const unsigned addr, const unsigned size = 8) {
    unsigned valid_bytes_cnt = 0;
    for(int i = 0; i < size; ++i) {
      if (addr + i >= dcache_mem.size()) break;
      outbytes[i] = dcache_mem[addr + i]; 
      valid_bytes_cnt++;
    }
    if (valid_bytes_cnt == 0) {
      throw std::range_error(std::string("dcache read out of range, at: ") + std::to_string(addr));
    } else {
      return {outbytes, valid_bytes_cnt};
    }    
  }

  void write_bytes_to(const unsigned addr, const uint8_t *src, const unsigned size = 8) {
    if (addr + size >= dcache_mem.size()) std::range_error(std::string("dcache write out of range, at: ") + std::to_string(addr));
    for (int i = 0; i < size; ++i) {
      dcache_mem[addr + i] = src[i];
    } 
  }

  unsigned get_bytes_size() {return dcache_mem.size();}
};


// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env) {
    using std::string; using std::cout; using std::endl; using std::ifstream;
    cout << "---------------------------- Simulator configuration -----------------------------" << endl;
    cout << "the arguments are :" << endl;
    for (int i = 0; argv[i]; ++i) {
      cout << argv[i] << " ";
    }
    cout << endl << endl;

    // use the second argument as the name of binary
    string binName{argv[1]};
    cout << "use bin file: " << binName << endl;
    Icache icache(binName);
    cout << "prog content: " << endl;
    for (int i = 0; i < icache.get_mem_size(); ++i) {
      std::printf("%08x ", icache.get_word_from(i));
      if ((i + 1) % 10== 0 && i) std::printf("\n");
    }
    cout << endl;

    // use the third argument as the name of dcache init file
    string InitFile{argv[2]};
    cout << "use init file: " << InitFile << endl;
    Dcache dcache(binName);
    cout << "dcache content: " << endl;
    unsigned i = 0, j = 0;
    for (i = dcache.get_bytes_size(), j = 0; i > 4; i -= 4, j += 4) {
      auto word = dcache.get_bytes_from(j, 4);
      std::printf("%08x ", *(reinterpret_cast<uint32_t *>(word.first)));
      if ((j / 4 + 1) % 10== 0 && i) std::printf("\n");
    }
    auto word = dcache.get_bytes_from(j, i);
    std::printf("%08x ", *(reinterpret_cast<uint32_t *>(word.first)));
    cout << endl;

    cout << "------------------------------- Simulation begin ---------------------------------" << endl;

    std::cout << std::endl;
    // Prevent unused variable warnings
    if (false && argc && argv && env) {}

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // Construct a VerilatedContext to hold simulation time, etc.
    // Multiple modules (made later below with Vtop) may share the same
    // context to share time, or modules may have different contexts if
    // they should be independent from each other.

    // Using unique_ptr is similar to
    // "VerilatedContext* contextp = new VerilatedContext" then deleting at end.
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

    // Construct the Verilated model, from Vtop.h generated from Verilating "core_blank.v".
    const std::unique_ptr<Vcore_blank> core_blank{new Vcore_blank{contextp.get(), "core_blank"}};

    // Set core_blank's input signals
    core_blank->reset = 1;
    core_blank->clock = 0;
    core_blank->icache2core_data = 1;
    core_blank->icache2core_data_valid = 1; // always valid

    core_blank->dcache2core_data = 0xffffffffffffffff;
    core_blank->dcache2core_data_valid = 0;

    // Simulate until $finish
    while (!contextp->gotFinish()) {
        contextp->timeInc(1);  // 1 timeprecision period passes...
        // Historical note, before Verilator 4.200 a sc_time_stamp()
        // function was required instead of using timeInc.  Once timeInc()
        // is called (with non-zero), the Verilated libraries assume the
        // new API, and sc_time_stamp() will no longer work.

        // Toggle a fast (time/2 period) clock
        core_blank->clock = !core_blank->clock;

        // Toggle control signals on an edge that doesn't correspond
        // to where the controls are sampled; in this example we do
        // this only on a negedge of clk, because we know
        // reset is not sampled there.
        if (!core_blank->clock) {
            if (contextp->time() > 1 && contextp->time() < 10) {
                core_blank->reset = 1;  // Assert reset
            } else {
                core_blank->reset = 0;
            }
            try {
              core_blank->icache2core_data = icache.get_word_from(core_blank->core2icache_addr);
            } catch (std::exception &e) {
              cout << "ERROR: " << e.what();
              core_blank->icache2core_data = 0;
            }

            try {
              if (core_blank->core2dcache_data_we) {
                dcache.write_bytes_to(core_blank->core2icache_addr, reinterpret_cast<uint8_t *>(&(core_blank->core2dcache_data)), core_blank->core2dcache_data_size);
              } else {
                core_blank->dcache2core_data = *(reinterpret_cast<uint64_t *> (dcache.get_bytes_from(core_blank->core2dcache_addr).first));
                core_blank->dcache2core_data_valid = 1;
              }
            } catch (std::exception &e) {
              cout << "ERROR: " << e.what();
              core_blank->dcache2core_data = 0;
            }
        }

        core_blank->eval();

        VL_PRINTF("[%" VL_PRI64 "d] clk=%x rst=%x c2i_addr=%" VL_PRI64 "x, "
                  "i2c_data=%" VL_PRI64 "x, i2c_valid=%x\n",
                  contextp->time(), core_blank->clock, core_blank->reset, 
                  core_blank->core2icache_addr, core_blank->icache2core_data,
                  core_blank->icache2core_data_valid
                  );
        VL_PRINTF("[%" VL_PRI64 "d] c2d_addr=%" VL_PRI64 "x, "
                  "d2c_data=%" VL_PRI64 "x, d2c_valid=%x\n",
                  contextp->time(), 
                  core_blank->core2dcache_addr, core_blank->dcache2core_data,
                  core_blank->dcache2core_data_valid
                  );
        VL_PRINTF("[%" VL_PRI64 "d] c2d_data=%" VL_PRI64 "x, "
                  "c2d_data_size=%" VL_PRI64 "x, d2c_we=%x\n",
                  contextp->time(), 
                  core_blank->core2dcache_data, core_blank->core2dcache_data_size,
                  core_blank->core2dcache_data_we
                  );
        if (contextp->time() > 500) break;
    }

    // Final model cleanup
    core_blank->final();

    // Coverage analysis (calling write only after the test is known to pass)
//#if VM_COVERAGE
//    Verilated::mkdir("logs");
//    contextp->coveragep()->write("logs/coverage.dat");
//#endif

    // Return good completion status
    // Don't use exit() or destructor won't get called
    return 0;
}
