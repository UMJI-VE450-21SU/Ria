`include "icache_pkg.sv"
`include "MPSOC_S_AXI4_HP_bus.sv"

module AXI_writer_reader (
    // [NOTE] current interface use a single clock, but
    // by separating this module, I want to support two
    // clocks
    input logic clk,

    MPSOC_S_AXI4_HP_bus.master bus


    
    
);
    
endmodule