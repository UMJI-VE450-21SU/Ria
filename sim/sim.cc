#include "sim.h"
#include <iostream>

sim_t::sim_t(const std::vector<std::string> &args, IdeaMemory *ptr) : htif_t(args), mem_ptr(ptr) {}

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
