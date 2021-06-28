`include "icache_pkg.sv"
`include "common_pkg.sv"

import icache_pkg::laddr_t;
import icache_pkg::overhead_t;

module icache_overhead #(
   parameter MEMORY_SIZE = icache_pkg::OVERHEAD_MEMORY_SIZE,
   parameter ADDR_WIDTH = icache_pkg::OVERHEAD_ADDR_WIDTH,
   parameter DATA_WIDTH = icache_pkg::OVERHEAD_DATA_WIDTH, 
   parameter MEMORY_INIT_FILE = "none"
) (
   input logic clk, // common clock

   input logic wrap,
   input logic [ADDR_WIDTH-1:0] addra,
   input logic ena,
   input overhead_t dina[2],

   input logic [ADDR_WIDTH-1:0] addrb,
   input logic enb,
   output overhead_t doutb[2]

);
import icache_pkg::*;

logic [ADDR_WIDTH-1:0] word_addra[2];
logic word_ena[2];
logic [DATA_WIDTH-1:0] word_dina[2];

logic [ADDR_WIDTH-1:0] word_addrb[2];
logic word_enb[2];
logic [DATA_WIDTH-1:0] word_doutb[2];

genvar i;
generate
    for (i = 0; i < 2; i = i + 1) begin
        SDP_SYNC_RAM_XPM_wrapper #(
        // default is set to hold cache data with LNUM line WNUM * WDSZ bits per line
        .MEMORY_SIZE(MEMORY_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH), 
        .BYTE_WRITE_WIDTH(DATA_WIDTH),
        .WEA_WIDTH(DATA_WIDTH), 
        .MEMORY_INIT_FILE(MEMORY_INIT_FILE)
        ) mem (
        .clk(clk), // common clock

        .addra(word_addra[i]),
        .wea(1),
        .ena(word_ena[i]),
        .dina(word_dina[i]),

        .addrb(word_addrb[i]),
        .enb(word_enb[i]),
        .doutb(word_doutb[i])
        );
    end
endgenerate

always_comb begin
    for (integer j = 0; j < WNUM; j = j + 1) begin
        word_ena[j] = ena;
        word_addra[j] = addra;
        word_dina[j] = dina[j];

        word_addrb[j] = wrap && (j == 0) ?  addrb + 1: addrb;
        word_enb[j] = enb;
        doutb[j] = word_doutb[j];
    end
end

    
endmodule