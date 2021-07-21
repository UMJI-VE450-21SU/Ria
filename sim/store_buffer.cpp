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
    fprintf(stderr, "[Store Buffer] Error: #commit > store buffer size\n");
    return -1;
  }

  printf("[Store Buffer] num_commit=%d\n", num_commit);

  for (unsigned int i = 0; i < num_commit; i++) {
    req = buffer.front();
    data_size = data_size_map[req->size];
    printf("[Store Buffer] store to memory... addr=0x%x, data=0x%llx\n", req->addr, req->data);
    if (req->addr == 0xFFFFFFFC) {
    // When we write a non-zero value to [0xFFFFFFFC], halt the simulation
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

void StoreBuffer::LoadData(unsigned int addr, char* dest) {
  unsigned long long data;
  unsigned char size;
  bool in_buffer = false;
  for (auto i = buffer.rbegin(); i != buffer.rend(); i++) {
    if ((*i)->addr == addr) {
      data = (*i)->data;
      size = (*i)->size;
      in_buffer = true;
      break;
    }
  }
  dmem->read_transction(addr, dest);
  if (in_buffer) {
    memcpy(dest, &data, data_size_map[size]);
  }
}
