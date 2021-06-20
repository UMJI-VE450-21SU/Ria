`include "dcache_pkg.sv"
// [Description]
// cache memory mapped to Xilinx's block ram in SDP mode
// parameterized cache memory. Only support aligned memory access

// Expected memory useage: 
// cache line: BRAM x 16

// [Required] CADDRSZ >= log2(BKSZ * 4)

module cache_mem_data (
    input logic clk,

    // [read]
    input laddr_t laddra, // line address & word address for read
    input waddr_t waddra,
    input logic re,
    output word_t [RBKSZ-1:0] dout,

    // [write]
    input laddr_t laddrb, // line address & word address for write
    input waddr_t waddrb,
    input word_t [WBKSZ-1:0] din,       // data for [write]
    input logic we                      // write enable
);

    //TODO: how to map to SDP in Xilinx

endmodule