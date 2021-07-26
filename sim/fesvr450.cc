#include "sim_memory.h"
#include "sim.h"
#include <iostream>
#include <cstdint>


int main(int argc, char **argv) {
  auto memory = make_BucketMemory();

  auto imem = std::make_unique<IMem>(memory.get());

  auto dmem = std::make_unique<DMem>(memory.get());

  std::vector<std::string> args{std::string(argv[1])};

  sim_t sim(args, memory.get());

  sim.start();
  unsigned i = 0;
  while (!sim.is_signal_exit() && sim.exit_code() == 0) {
//    std::cout << "at time " << i << std::endl;

    if (i > 100) {

      uint32_t myexit = 0x00000011;

      dmem->write_transcation(0x10000000, (char *)&myexit, sizeof myexit);
    }
//    std::cout << "[host move]" << std::endl;

    sim.process_htio();
    i++; 
  }
  memory->print_all();

  std::cout << std::endl << std::endl;
  std::cout << "===================================  [SIMULATION ENDS] ===============================" << std::endl;
  std::cout << "exit code: " << sim.exit_code() << std::endl;

  sim.stop();

  return 0;
}
