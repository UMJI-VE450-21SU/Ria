#ifndef SIM_H
#define SIM_H
#include<memory>

#include "sim_memory.h"
#include "htif.h"

class sim_t : public htif_t {
  IdeaMemory *mem_ptr;

  public:
  sim_t(const std::vector<std::string> &args, IdeaMemory *ptr);

  virtual void reset();

  virtual void read_chunk(addr_t taddr, size_t len, void* dst);
  virtual void write_chunk(addr_t taddr, size_t len, const void* src);

  virtual size_t chunk_align();
  virtual size_t chunk_max_size();
};

#endif /* SIM_H */
