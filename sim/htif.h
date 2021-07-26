// See LICENSE for license details.

#ifndef __HTIF_H
#define __HTIF_H

#include "memif.h"
#include "syscall.h"
#include "device.h"
#include "byteorder.h"
#include <string.h>
#include <map>
#include <vector>
#include <assert.h>

class htif_t : public chunked_memif_t
{
 public:
  htif_t();
  htif_t(int argc, char** argv);
  htif_t(const std::vector<std::string>& args);
  virtual ~htif_t();

  virtual void start(); // just load the programs
  virtual void stop();  // under single thread, just set the stopped flag

  // CHANGE: for a single thread version, cannot use the structure here, so no run()
  // int run();
  void process_htio(); // CHANGE: use a function to process the host target io
  bool done(); // just return the stopped flag
  int exit_code(); // the exit code
  bool is_signal_exit();

  virtual memif_t& memif() { return mem; }

  template<typename T> inline T from_target(target_endian<T> n) const
  {
#ifdef RISCV_ENABLE_DUAL_ENDIAN
    memif_endianness_t endianness = get_target_endianness();
    assert(endianness == memif_endianness_little || endianness == memif_endianness_big);

    return endianness == memif_endianness_big? n.from_be() : n.from_le();
#else
    return n.from_le();
#endif
  }

  template<typename T> inline target_endian<T> to_target(T n) const
  {
#ifdef RISCV_ENABLE_DUAL_ENDIAN
    memif_endianness_t endianness = get_target_endianness();
    assert(endianness == memif_endianness_little || endianness == memif_endianness_big);

    return endianness == memif_endianness_big? target_endian<T>::to_be(n) : target_endian<T>::to_le(n);
#else
    return target_endian<T>::to_le(n);
#endif
  }

 protected:
  virtual void reset() = 0; // being used in start, override to do nothing

  virtual void read_chunk(addr_t taddr, size_t len, void* dst) = 0;
  virtual void write_chunk(addr_t taddr, size_t len, const void* src) = 0;
  virtual void clear_chunk(addr_t taddr, size_t len);

  virtual size_t chunk_align() = 0;
  virtual size_t chunk_max_size() = 0;

  virtual std::map<std::string, uint64_t> load_payload(const std::string& payload, reg_t* entry);
  virtual void load_program(); // READNOTE: being called in the start()
  virtual void idle() {}

  const std::vector<std::string>& host_args() { return hargs; }

  reg_t get_entry_point() { return entry; }

  // indicates that the initial program load can skip writing this address
  // range to memory, because it has already been loaded through a sideband
  virtual bool is_address_preloaded(addr_t taddr, size_t len) { return false; }

  // Given an address, return symbol from addr2symbol map
  const char* get_symbol(uint64_t addr);

 private:
  void parse_arguments(int argc, char ** argv);
  void register_devices();
  void usage(const char * program_name); // READNOTE: only about print the usage help message

  memif_t mem;
  reg_t entry;
  bool writezeros;
  std::vector<std::string> hargs; // host_args, (never used?)
  std::vector<std::string> targs; // target_args
  std::string sig_file;
  unsigned int line_size;
  addr_t sig_addr; // torture
  addr_t sig_len; // torture
  addr_t tohost_addr;
  addr_t fromhost_addr;
  int exitcode;
  bool stopped;

  std::queue<reg_t> fromhost_queue;
  // CHANGE: default initialized fromhost_queue for process_htio

  // READNOTE: following three devices are registered when the htif is initialized
  device_list_t device_list; // the target to register devices
  syscall_t syscall_proxy;
  std::vector<device_t*> dynamic_devices;


  std::vector<std::string> payloads;

  const std::vector<std::string>& target_args() { return targs; }

  std::map<uint64_t, std::string> addr2symbol;

  friend class memif_t;
  friend class syscall_t;
};

/* Alignment guide for emulator.cc options:
  -x, --long-option        Description with max 80 characters --------------->\n\
       +plus-arg-equivalent\n\
 */
#define HTIF_USAGE_OPTIONS \
"HOST OPTIONS\n\
  -h, --help               Display this help and exit\n\
  +h,  +help\n\
      --payload=PATH       Load PATH memory as an additional ELF payload\n\
       +payload=PATH\n\
"

// CHANGE: delete most of the argument because we do not need
#define HTIF_LONG_OPTIONS_OPTIND 1024
#define HTIF_LONG_OPTIONS                                               \
{"help",      no_argument,       0, 'h'                          },     \
{"payload",   required_argument, 0, HTIF_LONG_OPTIONS_OPTIND + 4 },     \
{0, 0, 0, 0}

#endif // __HTIF_H
