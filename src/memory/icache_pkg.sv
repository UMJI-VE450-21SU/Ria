`ifndef ICACHE_PKG
`define ICACHE_PKG

package icache_pkg;
    ////////////////////
    // parameters
    ////////////////////

    // cache line parameters
    parameter WDSZ = 32;     // assume the address size == a word
    parameter LADDRSZ = 10;  // row addr size, defualt to 1K lines, 10 bits
    parameter WADDRSZ = 6;   // column addr size, default to 64 byte line, 6 bit
    parameter BADDRSZ = $clog2(32/4); // bits for word
    parameter WAYS = 1;      // associativity
    `define CACHE_DM
    parameter TAGSZ = WDSZ - LADDRSZ - WADDRSZ - BADDRSZ - $clog2(WAYS);
    parameter LNUM = 1 << LADDRSZ;             // # of lines
    parameter WNUM = 1 << WADDRSZ;     // # of column (word)

    // width
    parameter RBKSZ = 4;     // read block size
    parameter WBKSZ = 2;     // write block size


    ////////////////////
    // types
    ////////////////////

    typedef logic [WDSZ-1:0] word_t; // word
    typedef logic [TAGSZ-1:0] tag_t; // tag
    typedef logic [LADDRSZ-1:0] laddr_t; // cache data row idx
    typedef logic [WADDRSZ-1:0] waddr_t; // cache data column type
    typedef logic [BADDRSZ-1:0] baddr_t;

    `ifdef CACHE_DM
    typedef struct packed {
        tag_t tag;
        laddr_t laddr;
        waddr_t waddr;
        baddr_t baddr;
    } addr_t;
    `endif

    `ifdef CACHE_SA
    typedef struct packed {
        tag_t tag;
        logic [$clog2(WAYS)-1:0] pad;
        laddr_t laddr;
        waddr_t waddr;
        baddr_t baddr;
    } addr_t;
    `endif

    typedef struct packed {
        tag_t tag;
        logic valid;
        logic dirty;
        // more bits for coherency protocols
    } overhead_t;
    
endpackage

import icache_pkg::*;

`endif