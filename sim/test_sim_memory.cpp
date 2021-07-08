#include "sim_memory.h"

#include <iostream>
#include <string>
#include <array>
#include <cstdio>
#include <cassert>


void read_print_16bytes(IdeaMemory *mem, unsigned addr) {
    printf("//////////// TASK: %s ////////////\n", __func__);
    std::array<char, 16> bytes;
    char *bytes_data = bytes.data();
    mem->read_bytes(bytes_data, addr, 16);
    unsigned j = 0;
    printf("read at 0x%x: ", addr);
    for(auto i : bytes) {
      printf("%02x", (unsigned char) i); 
      if ((++j) % 4 == 0) printf(" ");
    }
    std::cout << std::endl;
}

void load_print_image(IdeaMemory *mem, const std::string &name, unsigned addr) {
  printf("//////////// TASK: %s ////////////\n", __func__);
  printf("load image %s at 0x%x\n", name.c_str(), addr);
  printf("[BEFORE]\n");
  mem->print_all();

  mem->load_image_to(name, addr);

  printf("[AFTER]\n");
  mem->print_all();
}

void store_print_bytes(IdeaMemory *mem, unsigned addr, unsigned size) {
    static const unsigned char vals[4] = {0x13, 0x57, 0x9a, 0xce};
    assert(size <= 16);
    printf("//////////// TASK: %s ////////////\n", __func__);
    char bytes[16];
    for (unsigned i = 0; i < size; ++i) {
      bytes[i] = vals[i % 4];
    }
    printf("write at 0x%x with %d bytes magic values\n", addr, size);
    mem->write_bytes(bytes, 16, addr);
}

void print_all(IdeaMemory *mem){
    printf("//////////// TASK: %s ////////////\n", __func__);
    mem->print_all();
}



int main(int argc, char** argv, char** env) {
    using std::string; using std::cout; using std::endl; using std::ifstream;
    std::ios_base::sync_with_stdio(true);
    cout << "---------------------------- init/ dump test -----------------------------" << endl;
    cout << "the arguments are :" << endl;
    for (int i = 0; argv[i]; ++i) {
      cout << argv[i] << " ";
    }
    cout << endl << endl;

    // use the second argument as the name of binary
    string binName{argv[1]};
    auto bucket_memory = make_BucketMemory();

    load_print_image(bucket_memory.get(), binName, 0);

    load_print_image(bucket_memory.get(), binName, 0x100);

    load_print_image(bucket_memory.get(), binName, 0x1000);

    read_print_16bytes(bucket_memory.get(), 0);
    read_print_16bytes(bucket_memory.get(), 4);
    read_print_16bytes(bucket_memory.get(), 28);
    read_print_16bytes(bucket_memory.get(), 0x19f);
    read_print_16bytes(bucket_memory.get(), 0x210);
    read_print_16bytes(bucket_memory.get(), 0x1010);

    print_all(bucket_memory.get());

    store_print_bytes(bucket_memory.get(), 0x20, 8);
    store_print_bytes(bucket_memory.get(), 0x40, 16);
    store_print_bytes(bucket_memory.get(), 0x19f, 16);
    
    print_all(bucket_memory.get());

    read_print_16bytes(bucket_memory.get(), 0x20);
    read_print_16bytes(bucket_memory.get(), 0x40);
    read_print_16bytes(bucket_memory.get(), 0x19f);
    
}
