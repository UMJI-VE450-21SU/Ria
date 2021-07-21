#ifndef STORE_BUFFER_H
#define STORE_BUFFER_H

#include <list>
#include <memory>

#include "sim_memory.h"

typedef struct store_request {
  unsigned int addr;
  unsigned long long data;
  unsigned char size;
  store_request(unsigned int a, unsigned long long d, unsigned char s) {
    addr = a;
    data = d;
    size = s;
  }
} store_request_t;

class StoreBuffer {
public:
  StoreBuffer(std::unique_ptr<DMem> dm) : dmem(std::move(dm)) { }

  ~StoreBuffer() { FlushStoreBuffer(); }

  void AddStoreRequest(store_request_t* req);

  // return 0 for normal store
  // return 1 for halt
  int CommitStoreRequest(unsigned int num_commit);

  void FlushStoreBuffer();

  void LoadData(unsigned int load_addr, char* dest);

private:
  std::unique_ptr<DMem> dmem;

  std::list<store_request_t*> buffer;
};

#endif /* STORE_BUFFER_H */
