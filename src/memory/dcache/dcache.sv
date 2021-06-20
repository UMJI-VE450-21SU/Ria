`include "dcache_pkg.sv"
// [Description]
// At this stage, I will only try to implement a single port cache
// with the AXI unverified I do not want to make the things even 
// harder
//
// [NOTE] Unlike the icache, the dcache do not support unaligned read/
// write

module dcache (
    input logic clk,
    input logic rst,

    // interface to the processor
    input addr_t addr,
    input logic addr_valid,
    output logic addr_ready,

    output word_t [1:0] result, 
    // read for two word because of double
    output logic result_valid,
    input logic resutl_ready,

    input logic we, 
    // if we then write else read
    input logic [7:0] wstrobe,
    input word_t [1:0] data_in,
    input logic data_in_valid,
    input logic data_in_ready
);






    
endmodule