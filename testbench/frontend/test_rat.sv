//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Jian Shi
// Reviewer: 
// Module Name: rat_tb
// Target Devices: testbench for rat
// Description: 
// testbench for rat
// Dependencies: 
// src/frontend/rat.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module rat_tb;
parameter half_clk_cycle = 1;

reg   clock, reset, recover, input_valid;
reg         [`ARF_INT_SIZE-1:0]   arf_recover;
reg         [`RENAME_WIDTH-1:0]   retire_valid;

micro_op_t                        pc_recover;
micro_op_t  [`RENAME_WIDTH-1:0]   pc_retire;
micro_op_t  [`RENAME_WIDTH-1:0]   uop_in;
micro_op_t  [`RENAME_WIDTH-1:0]   uop_out;

wire                              allocatable;
wire                              ready;

always #half_clk_cycle clock = ~clock;

rat UTT(
);

initial begin
  pc_retire[1].cp_index          = 1;
  #10 $stop;
end

endmodule
