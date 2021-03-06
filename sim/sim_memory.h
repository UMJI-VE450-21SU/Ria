#ifndef SIM_MEMORY_H
#define SIM_MEMORY_H

#include <string>
#include <memory>

static unsigned char data_size_map[4] = {1, 2, 4, 8};

/*
 * This memory expect to provide 4Gb address space
 *
 * If a location is not write, then the default value is 0
 */

struct IdeaMemory {
  // load <imageFile> to <addr>.
  virtual void load_image_to(const std::string &imageFile, unsigned addr) = 0;

  // store [addr, addr + size - 1] data to <dumpFile>
  virtual void dump_data(const std::string &dumpFile, unsigned addr, unsigned size) = 0;

  // read <size> bytes from <addr> to <dest>, return the # of words
  virtual unsigned read_bytes(char *dest, unsigned addr, unsigned size) = 0;

  // write <size> bytes from <src> to <addr>
  virtual unsigned write_bytes(const char *src, unsigned size, unsigned addr) = 0;

  // print <size> bytes from <addr> to <addr> + <size>
  virtual void print_bytes_up(unsigned addr, unsigned size) const = 0;

  // print <size> bytes from <addr> down to <addr> - <size>
  virtual void print_bytes_down(unsigned addr, unsigned size) const = 0;

  // print all values that is not 0
  virtual void print_all() = 0;

  virtual ~IdeaMemory() {};
};



class BucketMemory;

std::unique_ptr<IdeaMemory> make_BucketMemory(); 

// currently an ideal Memory
class IMem {

  private:
    IdeaMemory *mem;
  public:
    IMem(IdeaMemory *mem): mem(mem) {}

    // read 4 words, 16 bytes from the IMem
    bool read_transction(unsigned addr, char *dest);

};

class DMem {
  private:
    IdeaMemory *mem;
  public:
    DMem(IdeaMemory *mem): mem(mem) {}

    // write <size> bytes to memory
    bool write_transcation(unsigned addr, const char *src, unsigned char size);

    bool read_transction(unsigned addr, char *dest);
    
};

#endif /* SIM_MEMORY_H */
