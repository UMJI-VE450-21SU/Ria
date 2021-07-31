#include "sim_memory.h"

#include <unordered_map>
#include <array>
#include <fstream>
#include <cstdio>
#include <memory>
#include <cstring>
#include <functional>

inline unsigned smaller(unsigned a, unsigned b) { return a < b ? a : b; }
inline unsigned bigger(unsigned a, unsigned b) { return a > b ? a : b; }

class BucketMemory final: public IdeaMemory {
  private:
    static constexpr unsigned bucketBits = 10;
    static constexpr unsigned bucketSize = 1 << bucketBits;
    static constexpr unsigned line_bytes = 32;
    static constexpr unsigned byte_group = 4;
    std::unordered_map<unsigned, std::array<char, bucketSize>> buckets;

    unsigned which_bucket(unsigned addr) const { return addr >> bucketBits; }
    
    unsigned pos_in_bucket(unsigned addr) const { return addr % bucketSize; }

    unsigned make_addr(unsigned bucket_pos, unsigned bucket_addr) {
      return (bucket_pos << bucketBits) + bucket_addr;
    }

    void print_non_zero_line(unsigned addr, char *data, unsigned st) {
      bool zero = 1;
      for (unsigned j = st; j < st + line_bytes; ++j) {
        if (data[j]) zero = 0;
      }
      if (zero) return;

      std::printf("0x%08x     :  ", addr);
      for (unsigned j = st; j < st + line_bytes; ++j) {
        std::printf("%02x", (unsigned char) data[j]);
        if ((j + 1) % byte_group == 0) std::printf(" ");
      }
      std::printf("\n");
    }

    void print_non_zero_lines(unsigned bucket_pos) {
      char *data = buckets[bucket_pos].data();
      for (unsigned i = 0; i < bucketSize; i += line_bytes) {
        print_non_zero_line(make_addr(bucket_pos, i), data, i);
      }
    }

    // walk_through a block of memory <addr, size>, f will have access to them
    void walk_through(unsigned addr, unsigned size, std::function<void (char *, unsigned)> f) {
      unsigned bucket_pos = which_bucket(addr), bucket_st = pos_in_bucket(addr);
      while (size) {
        unsigned p_sz = smaller(bucketSize - bucket_st, size);
        char *bucketData = buckets[bucket_pos].data(); // value-initialized array;
        f(bucketData + bucket_st, p_sz);

        bucket_pos = which_bucket((addr += p_sz));
        bucket_st = pos_in_bucket((size -= p_sz));
      }
    }

  public:
    void load_image_to(const std::string &imageFile, unsigned addr) override {
      std::ifstream imageBin{imageFile, std::ios::binary};

      imageBin.seekg(0, std::ios::end);
      auto imageSize = imageBin.tellg();
      imageBin.seekg(0, std::ios::beg);

      walk_through(addr, imageSize, [&] (char *st, unsigned sz){imageBin.read(st, sz);});
    }

    void dump_data(const std::string &dumpFile, unsigned addr, unsigned size) override {
      std::ofstream dumpBin{dumpFile, std::ios::binary};

      walk_through(addr, size, [&] (char *st, unsigned sz){dumpBin.write(st, sz);});
    }

    unsigned read_bytes(char *dest, unsigned addr, unsigned size) override {
      walk_through(addr, size, [&](char *st, unsigned sz){ std::memcpy(dest, st, sz); dest += sz; });
      return size;
    } 

    unsigned write_bytes(char *src, unsigned size, unsigned addr) override {
      walk_through(addr, size, [&](char *st, unsigned sz){ std::memcpy(st, src, sz); src += sz; });
      return size;
    }

    void print_bytes_up(unsigned addr, unsigned size) const override { }

    void print_bytes_down(unsigned addr, unsigned size) const override { }

    // print all values that is not 0
    void print_all() override {
      printf("The memory holds: 1        2        3        4        5        6        7        8\n");
      printf("----------------------------------------------------------------------------------\n");
      for (auto &b: buckets) {
        print_non_zero_lines(b.first);
      }
    }

    ~BucketMemory() override {}
};

std::unique_ptr<IdeaMemory> make_BucketMemory() {
  return std::make_unique<BucketMemory>();
}

bool IMem::read_transction(unsigned addr, char *dest) {
  this->mem->read_bytes(dest, addr, 16);
  return true;
}

bool DMem::write_transcation(unsigned addr, char *src, unsigned char size) {
  this->mem->write_bytes(src, size, addr);
  return true;
}

bool DMem::read_transction(unsigned addr, char *dest) {
  this->mem->read_bytes(dest, addr, 8);
  return true;
}
