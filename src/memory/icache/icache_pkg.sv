`ifndef ICACHE_PKG
`define ICACHE_PKG

package icache_pkg;

    ////////////////////
    // cache parameters
    ////////////////////

    // cache line parameters
    parameter WDSZ = 32;     // the address size == a word
    parameter LADDRSZ = 8;  // row addr size, defualt to 1K lines, 10 bits (the vivado cannot handle?)
    parameter WADDRSZ = 6;   // column addr size, default to 64 byte line, 6 bit
    parameter BADDRSZ = $clog2(32/4); // bits for word
    // I give up on making the WAYS to be configurable
    // it may result in too many block ram to be used and have poor
    // performance, My main concern is the routing
    // also it take much more effort to get the alignment problem correct
    // parameter WAYS = 1;      // associativity
    parameter TAGSZ = WDSZ - LADDRSZ - WADDRSZ - BADDRSZ; // remaining is the tag
    parameter LNUM = 1 << LADDRSZ;     // # of sets, should at least have two sets
    parameter WNUM = 1 << WADDRSZ;     // # of column (word)


    ////////////////////
    // bus parameters
    ////////////////////
    parameter AXI_WIDTH = 64; // AXI bus width == WBKSZ * WDSZ
    parameter ALLOC_BEATS = WNUM / (AXI_WIDTH/ WDSZ); 
    // cache to cache controller

    ////////////////////
    // cache parameters
    ////////////////////

    // width
    // read block size
    parameter RBKSZ = 4;     
    // write block size, should equals to AXI bus width
    parameter WBKSZ = AXI_WIDTH / WDSZ;     

    ////////////////////
    // types
    ////////////////////

    typedef logic [WDSZ-1:0] word_t; // a word, for addr & data
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
    
endpackage

import icache_pkg::*;

`endif