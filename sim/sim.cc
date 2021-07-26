#include "sim.h"
#include <iostream>

sim_t::sim_t(const std::vector<std::string> &args, IdeaMemory *ptr) : htif_t(args), mem_ptr(ptr) {
  setup_rom();
}

void sim_t::reset() {}

void sim_t::read_chunk(addr_t taddr, size_t len, void *dst) {
  mem_ptr->read_bytes((char *) dst, taddr, len);
}

void sim_t::write_chunk(addr_t taddr, size_t len, const void *src) {
  mem_ptr->write_bytes((const char *) src, len, taddr);
}

size_t sim_t::chunk_align() {
  return 1;
}

size_t sim_t::chunk_max_size() {
  return 64;
}

void sim_t::setup_rom() {

  const int reset_vec_size = 7;

  auto start_pc =get_entry_point();

  uint32_t reset_vec[reset_vec_size] = {
    0x297,                                      // auipc  t0,0x0
    0x0182a283u,                                // lw     t0,24(t0)
    0x28067,                                    // jr     t0
    0,
    0,
    0,
    (uint32_t) (start_pc & 0xffffffff)
  };

  mem_ptr->write_bytes((const char *) reset_vec, sizeof(reset_vec), 0x1000);
}
