//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Jian Shi
// Reviewer: 
// Module Name: mapping_table_tb
// Target Devices: testbench for mapping table
// Description: 
// testbench for mapping table
// Dependencies: 
// src/frontend/mapping_table.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mapping_table_tb;
  parameter half_clk_cycle = 1;

  reg  clock, reset, check, recover, stall;

  always #half_clk_cycle clock = ~clock;

  mapping_table UTT(
  );

  initial begin
    #10 $stop;
  end

endmodule
