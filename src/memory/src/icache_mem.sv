`include "icache_pkg.sv"
`include "common_pkg.sv"

import icache_pkg::laddr_t;
import icache_pkg::waddr_t;

import common_pkg::word_t;

module icache_mem #(
   // default is set to hold cache data with LNUM line WNUM * WDSZ bits per line
   parameter MEMORY_SIZE = icache_pkg::DATA_MEMORY_SIZE,
   parameter ADDR_WIDTH = icache_pkg::DATA_ADDR_WIDTH,
   parameter DATA_WIDTH = icache_pkg::DATA_DATA_WIDTH, 
   parameter WEA_WIDTH = icache_pkg::DATA_WEA_WIDTH, 
   parameter MEMORY_INIT_FILE = "none"
)  (
    input logic clk,


    // [write]
    input laddr_t laddra,
    input waddr_t waddra,
    input logic [icache_pkg::DATA_DATA_WIDTH-1:0] dina[icache_pkg::WNUM],
    input logic ena,

    // [read]
    input laddr_t laddrb,
    input waddr_t waddrb,
    input logic wrap,
    input logic enb,
    output word_t [icache_pkg::RBKSZ-1:0] doutb
);
import icache_pkg::*;

logic [ADDR_WIDTH-1:0] word_addra[WNUM];
logic word_ena[WNUM];
logic [DATA_WIDTH-1:0] word_dina[WNUM];

logic [ADDR_WIDTH-1:0] word_addrb[WNUM];
logic word_enb[WNUM];
logic [DATA_WIDTH-1:0] word_doutb[WNUM];

genvar i;
generate
    for (i = 0; i < WNUM; i = i + 1) begin
        SDP_SYNC_RAM_XPM_wrapper #(
        // default is set to hold cache data with LNUM line WNUM * WDSZ bits per line
        .MEMORY_SIZE(MEMORY_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH), 
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
        word_addra[j] = laddra;
        word_dina[j] = dina[j];

        word_addrb[j] = (WADDRSZ'(j) < waddrb && wrap) ? 
            laddrb + 1: laddrb;
        word_enb[j] = enb;
    end
end

always_comb begin
    for (integer j = 0; j < RBKSZ; j = j + 1) begin
        doutb[j] = word_doutb[4'(j) + waddrb];    
    end
end
    
endmodule