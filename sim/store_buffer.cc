#include <stdio.h>
#include <string.h>

#include "store_buffer.h"

void StoreBuffer::AddStoreRequest(store_request_t* req) {
  printf("[Store Buffer] incomming store..... addr=0x%x, data=0x%llx\n", req->addr, req->data);
  buffer.push_back(req);
}

int StoreBuffer::CommitStoreRequest(unsigned int num_commit) {
  unsigned char data_size;
  store_request_t* req;

  if (num_commit > buffer.size()) {
    fprintf(stderr, "[Store Buffer] Error: #commit=%d > store buffer size=%ld\n", num_commit, buffer.size());
    FlushStoreBuffer();
    return -1;
  }

  for (unsigned int i = 0; i < num_commit; i++) {
    req = buffer.front();
    data_size = data_size_map[req->size];
    
    if (req->addr == 0xFFFFFFFC) {
    // When we write to [0xFFFFFFFC], halt the simulation
      FlushStoreBuffer();
      return -1;
    } else if (req->addr == 0xFFFFFFF8) {
    // When we write a character to [0xFFFFFFF8], print it to stderr (only 1 character)
      fprintf(stderr, "%c", *(reinterpret_cast<char *>(&(req->data))));
    } else {
      dmem->write_transcation(req->addr, reinterpret_cast<char *>(&(req->data)), data_size);
    }

    delete req;
    buffer.pop_front();
  }
  return 0;
}

void StoreBuffer::FlushStoreBuffer() {
  while (!buffer.empty()) {
    delete buffer.front();
    buffer.pop_front();
  }
}

void StoreBuffer::LoadData(unsigned int load_addr, char* dest) {
  unsigned int addr, size;
  int offset;
  unsigned long long data = 0;
  char* data_ptr = reinterpret_cast<char *>(&data);
  dmem->read_transction(load_addr, dest);
  printf("Loading data: addr=0x%x, dest_data=0x%llx\n", load_addr, *((unsigned long long *)dest));
  for (auto i = buffer.begin(); i != buffer.end(); i++) {
    addr = (*i)->addr;
    data = (*i)->data;
    size = data_size_map[(*i)->size];
    offset = addr - load_addr;
    if (size == 1) { // byte
      if (offset >= 0 && offset <= 7) {
        memcpy(dest + offset, data_ptr, size);
      }
    } else if (size == 2) { // half word
      if (offset >= 0 && offset <= 6) {
        memcpy(dest + offset, data_ptr, size);
      } else if (offset == 7) {
        memcpy(dest + offset, data_ptr, 8 - offset);
      } else if (offset == -1) {
        memcpy(dest, data_ptr - offset, size + offset);
      }
    } else if (size == 4) { // word
      if (offset >= 0 && offset <= 4) {
        memcpy(dest + offset, data_ptr, size);
      } else if (offset > 4 && offset <= 7) {
        memcpy(dest + offset, data_ptr, 8 - offset);
      } else if (offset >= -3 && offset < 0) {
        memcpy(dest, data_ptr - offset, size + offset);
      }
    } else if (size == 8) { // double word
      if (offset == 0) {
        memcpy(dest + offset, data_ptr, size);
      } else if (offset > 0 && offset <= 7) {
        memcpy(dest + offset, data_ptr, 8 - offset);
      } else if (offset >= -7 && offset < 0) {
        memcpy(dest, data_ptr - offset, size + offset);
      }
    }
  }
}
