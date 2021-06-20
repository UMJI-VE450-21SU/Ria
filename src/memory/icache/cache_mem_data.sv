`include "icache_pkg.sv"
// [Description]
// cache memory mapped to Xilinx's block ram in SDP mode
// parameterized cache memory and support (limited) unaligned,
// cross cache line boundary access.

// The idea is similar to R10K's icache memory design

// Expected memory useage: 
// cache line: BRAM x 16

// [Required] CADDRSZ >= log2(BKSZ * 4)

module cache_mem_data (
    input logic clk,

    // [read]
    input laddr_t laddra, // line address & word address for read
    input waddr_t waddra,
    input logic wrap,   // will the column wrap around? (WNUM - waddra < RBKSZ)
    input logic re,
    output word_t [RBKSZ-1:0] dout,

    // [write]
    input laddr_t laddrb, // line address & word address for write
    input waddr_t waddrb,
    input word_t [WBKSZ-1:0] din,       // data for [write]
    input logic we                               // write enable
);


    // key points for read: 1) do proper row access 2) reorder read out data
    // key points for write: generate correct enable signals

    // read target address
    laddr_t [WNUM-1:0] laddra_target; // row address target
    always_comb begin : rtarget
       for (int i = 0; i < WNUM; i++) begin
           laddra_target[i] = laddra + 10'(wrap && (i < waddra));
       end 
    end

    // memory, should be mapped to SDP BRAM
    (* ram_style = "block" *) word_t [LNUM-1:0] dataram[WNUM];

    // read logic
    always_ff @( posedge clk ) begin : line_read
        for (int i = 0; i < WNUM; i++) begin
            if (re)
                dout[i] <= dataram[i + 32'(waddra)][laddra_target[i]];
        end
    end

    always_ff @( posedge clk ) begin : line_write
       for (int i = 0; i < WNUM; i++) begin
           if (we && (i - 32'(waddrb)) > 0 && (i - 32'(waddrb)) < WBKSZ) begin
               dataram[i][laddrb] <= din[i % (WDSZ / 8)];
           end
       end 
    end
endmodule