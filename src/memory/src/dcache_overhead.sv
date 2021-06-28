`include "dcache_pkg.sv"
`include "common_pkg.sv"
// [Description]
// Meant to be a N port abstraction of the block ram for cache overhead

import dcache_pkg::laddr_t;
import dcache_pkg::overhead_t;

module dcache_overhead #(
   // default is set to hold cache data with LNUM line WNUM * WDSZ bits per line
   parameter MEMORY_SIZE = dcache_pkg::OVERHEAD_MEMORY_SIZE,
   parameter ADDR_WIDTH = dcache_pkg::OVERHEAD_ADDR_WIDTH,
   parameter DATA_WIDTH = dcache_pkg::OVERHEAD_DATA_WIDTH, 
   parameter MEMORY_INIT_FILE = "none"
) (
   input logic clk, // common clock

   input logic [ADDR_WIDTH-1:0] addra,
   input logic ena,
   input overhead_t dina,

   input logic [ADDR_WIDTH-1:0] addrb,
   input logic enb,
   output overhead_t doutb

);

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

   .addra(addra),
   .wea(1),
   .ena(ena),
   .dina(dina),

   .addrb(addrb),
   .enb(enb),
   .doutb(doutb)
);
    
endmodule