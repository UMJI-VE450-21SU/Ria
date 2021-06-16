`include "icache_pkg.sv"

module AXI_writer_reader (
    // [NOTE] current interface use a single clock, but
    // by separating this module, I want to support two
    // clocks

    // for cache
    input logic clk,
    // for AXI protocol
    input logic ACLK,

    MPSOC_S_AXI4_HP_bus.master axi_bus,

    
    L1_local_read_channel.slave mem_read_channel

);
    
endmodule