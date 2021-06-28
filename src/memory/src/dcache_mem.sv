`include "dcache_pkg.sv"
`include "common_pkg.sv"

module dcache_mem #(
   // default is set to hold cache data with LNUM line WNUM * WDSZ bits per line
   parameter MEMORY_SIZE = dcache_pkg::DATA_MEMORY_SIZE,
   parameter ADDR_WIDTH = dcache_pkg::DATA_ADDR_WIDTH,
   parameter DATA_WIDTH = dcache_pkg::DATA_DATA_WIDTH, 
   parameter WEA_WIDTH = dcache_pkg::DATA_WEA_WIDTH, 
   parameter MEMORY_INIT_FILE = "none"
) (
   input logic clk, // common clock

   input logic [ADDR_WIDTH-1:0] addra,
   input logic [WEA_WIDTH-1:0] wea,
   input logic ena,
   input logic [DATA_WIDTH-1:0] dina,

   input logic [ADDR_WIDTH-1:0] addrb,
   input logic enb,
   output logic [DATA_WIDTH-1:0] doutb
);


SDP_SYNC_RAM_XPM_wrapper #(
   // default is set to hold cache data with LNUM line WNUM * WDSZ bits per line
   .MEMORY_SIZE(MEMORY_SIZE),
   .ADDR_WIDTH(ADDR_WIDTH),
   .DATA_WIDTH(DATA_WIDTH), 
   .WEA_WIDTH(WEA_WIDTH), 
   .MEMORY_INIT_FILE(MEMORY_INIT_FILE)
) mem (
   .clk(clk), // common clock

   .addra(addra),
   .wea(wea),
   .ena(ena),
   .dina(dina),

   .addrb(addrb),
   .enb(enb),
   .doutb(doutb)
);

endmodule