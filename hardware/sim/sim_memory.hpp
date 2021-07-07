#ifndef SIM_MEMORY_HPP
#define SIM_MEMORY_HPP

#include <vector>
#include <cstdint>
#include <fstream>
#include <string>
#include <cassert>
#include <utility>
#include <array>

class BytesArray {
  using byte_t = std::uint8_t;
  
  std::vector<byte_t> bytes;
  public:
  BytesArray() = default;
  BytesArray(const std::string &initFile) {this->init_from_file(initFile);}

  void init_from_file(const std::string &initFile) {
    // stupid implementation, should know how to use iterator for stream
    std::ifstream bin_in{initFile, std::ios::binary};
    uint8_t byte;
    while(bin_in) {
      byte = 0;
      bin_in.read(reinterpret_cast<char *>(&byte), 1);
      bytes.push_back(byte);
    } 
  }


  unsigned get_bytes_from(const unsigned addr, char *dest, const unsigned size = 8) const {
    unsigned valid_bytes_cnt = 0;
    for(int i = 0; i < size; ++i) {
      if (addr + i >= this->size()) break;
      dest[i] = bytes[addr + i]; 
      valid_bytes_cnt++;
    }
    return valid_bytes_cnt;
  }

  void write_bytes_to(const unsigned addr, const uint8_t *src, const unsigned size = 8) {
    if (addr + size >= this->size()) {
      this->bytes.reserve(addr + size);
    }
    for (int i = 0; i < size; ++i) {
      bytes[addr + i] = src[i];
    } 
  }
  
  void dump_to_file(const std::string &dumpFile) {
    std::ofstream dump_out{dumpFile, std::ios::binary};
    for(const auto &i: bytes) {
      dump_out.put(i);
    }
  }

  unsigned size() const {return bytes.size();}
  void print() const {
    unsigned i = 0;
    for (auto &b: this->bytes) {
      std::printf("%02x", b);
      if ((i + 1) % 4== 0 && i) std::printf(" ");
      if ((i + 1) % 32== 0 && i) std::printf("\n");
      ++i;
    }
  }
};

template<unsigned WIDTH = 4>
struct IMem: public BytesArray {
  public:
    using result_t = std::array<std::pair<uint32_t, bool>, WIDTH>; 
    IMem() = default;
    IMem(const std::string &InitFile): BytesArray(InitFile) {}

    result_t read_req(const unsigned addr) {
      
    }
};

struct DMem: public BytesArray { 
  DMem(const std::string &InitFile): BytesArray(InitFile) {}
};


#endif /* SIM_MEMORY_H */
