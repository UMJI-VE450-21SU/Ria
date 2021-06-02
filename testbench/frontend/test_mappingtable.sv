//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Jian Shi
// Reviewer: 
// Module Name: mappingtable_tb
// Target Devices: testbench for mapping table
// Description: 
// testbench for mapping table
// Dependencies: 
// src/frontend/rat.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mappingtable_tb;
parameter half_clk_cycle = 1;

reg  clock, reset, check, recover;

always #half_clk_cycle clock = ~clock;

initial begin
    #0 clock = 0; reset = 1;
end

endmodule
