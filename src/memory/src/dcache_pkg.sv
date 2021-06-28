`ifndef DCACHE_PKG
`define DCACHE_PKG

`include "AXI_bus_pkg.sv"
`include "common_pkg.sv"

package dcache_pkg;
    import AXI_bus_pkg::AXI_WIDTH;
    import common_pkg::WDSZ;

    ////////////////////
    // cache parameters
    ////////////////////

    // cache line parameters
    parameter LADDRSZ = 10;  // row addr size, defualt to 1K lines, 10 bits (the vivado cannot handle?)
    parameter WADDRSZ = 4;   // column addr size, default to 64 byte line (16 words), 4 bit
    parameter BADDRSZ = $clog2(32/8); // bits for word, should be 2
    parameter TAGSZ = WDSZ - LADDRSZ - WADDRSZ - BADDRSZ; // remaining is the tag
    parameter LNUM = 1 << LADDRSZ;     // # of sets, should at least have two sets
    parameter WNUM = 1 << WADDRSZ;     // # of column (word)

    parameter LINEBYTES = WNUM * (WDSZ/8);
    parameter LINEBITS = WNUM * WDSZ;
    ////////////////////
    // for cache data memory
    ////////////////////
    parameter DATA_MEMORY_SIZE = LNUM * WNUM * WDSZ;
    parameter DATA_ADDR_WIDTH = LADDRSZ;
    parameter DATA_DATA_WIDTH = WNUM * WDSZ; 
    parameter DATA_WEA_WIDTH = DATA_DATA_WIDTH / 8; 

    parameter ALLOC_BEATS = WNUM / (AXI_WIDTH/ WDSZ); 

    ////////////////////
    // types
    ////////////////////

    typedef logic [TAGSZ-1:0] tag_t; // tag
    typedef logic [LADDRSZ-1:0] laddr_t; // cache data row idx
    typedef logic [WADDRSZ-1:0] waddr_t; // cache data column type
    typedef logic [BADDRSZ-1:0] baddr_t;

    typedef struct packed {
        tag_t tag;
        laddr_t laddr;
        waddr_t waddr;
        baddr_t baddr;
    } addr_t;

    typedef struct packed {
        tag_t tag;
        logic valid;
        logic dirty; // will not be used in 
        // more bits for coherency protocols
    } overhead_t;

    ////////////////////
    // for cache overhead memory
    ////////////////////
    parameter OVERHEAD_MEMORY_SIZE = LNUM * WNUM * $bits(overhead_t);
    parameter OVERHEAD_ADDR_WIDTH = LADDRSZ;
    parameter OVERHEAD_DATA_WIDTH = $bits(overhead_t); 

endpackage

`endif