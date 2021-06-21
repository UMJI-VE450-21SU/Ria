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
  .clock        (clock          ),
  .reset        (reset          ),
  .recover      (recover        ),
  .input_valid  (input_valid    ),
  .arf_recover  (arf_recover    ),
  .retire_valid (retire_valid   ),
  .pc_recover   (pc_recover     ),
  .pc_retire    (pc_retire      ),
  .uop_in       (uop_in         ),
  .uop_out      (uop_out        ),
  .allocatable  (allocatable    ),
  .ready        (ready          )
);

initial begin
  #0 clock = 0; reset = 1; recover = 0; retire_valid = 0; input_valid = 1;
  pc_recover = 0; pc_retire = 0; uop_in = 0; arf_recover = 0;
  #2 reset = 0;
  uop_in[0].rd_arf_int_index = 1;
  uop_in[1].rd_arf_int_index = 2;
  uop_in[2].rd_arf_int_index = 3;
  uop_in[3].rd_arf_int_index = 4;
  uop_in[0].rd_valid = 1;
  uop_in[1].rd_valid = 1;
  uop_in[2].rd_valid = 1;
  uop_in[3].rd_valid = 1;
  # 2
  uop_in[0].rs1_arf_int_index = 1;
  uop_in[1].rs1_arf_int_index = 2;
  uop_in[2].rs1_arf_int_index = 3;
  uop_in[3].rs1_arf_int_index = 4;
  uop_in[0].rs2_arf_int_index = 1;
  uop_in[1].rs2_arf_int_index = 2;
  uop_in[2].rs2_arf_int_index = 3;
  uop_in[3].rs2_arf_int_index = 4;
  uop_in[0].rd_arf_int_index  = 5;
  uop_in[1].rd_arf_int_index  = 6;
  uop_in[2].rd_arf_int_index  = 7;
  uop_in[3].rd_arf_int_index  = 8;
  uop_in[0].rd_valid = 1;
  uop_in[1].rd_valid = 1;
  uop_in[2].rd_valid = 1;
  uop_in[3].rd_valid = 1;
  # 4
  uop_in[0].rs1_arf_int_index = 5;
  uop_in[1].rs1_arf_int_index = 6;
  uop_in[2].rs1_arf_int_index = 7;
  uop_in[3].rs1_arf_int_index = 8;
  uop_in[0].rs2_arf_int_index = 1;
  uop_in[1].rs2_arf_int_index = 2;
  uop_in[2].rs2_arf_int_index = 3;
  uop_in[3].rs2_arf_int_index = 4;
  uop_in[0].rd_arf_int_index  = 5;
  uop_in[1].rd_arf_int_index  = 6;
  uop_in[2].rd_arf_int_index  = 7;
  uop_in[3].rd_arf_int_index  = 8;
  uop_in[0].rd_valid = 1;
  uop_in[1].rd_valid = 1;
  uop_in[2].rd_valid = 1;
  uop_in[3].rd_valid = 1;
  # 4
  uop_in[0].rs1_arf_int_index = 0;
  uop_in[0].br_type           = BR_EQ;
  uop_in[1].rs1_arf_int_index = 0;
  uop_in[2].rs1_arf_int_index = 0;
  uop_in[3].rs1_arf_int_index = 0;
  uop_in[0].rs2_arf_int_index = 0;
  uop_in[1].rs2_arf_int_index = 0;
  uop_in[2].rs2_arf_int_index = 0;
  uop_in[3].rs2_arf_int_index = 0;
  uop_in[0].rd_arf_int_index  = 0;
  uop_in[1].rd_arf_int_index  = 0;
  uop_in[2].rd_arf_int_index  = 0;
  uop_in[3].rd_arf_int_index  = 0;
  uop_in[0].rd_valid          = 0;
  uop_in[1].rd_valid          = 0;
  uop_in[2].rd_valid          = 0;
  uop_in[3].rd_valid          = 0;
  # 6
  uop_in[0].br_type           = BR_X;
  pc_retire[0].cp_index          = 1;
  pc_retire[1].cp_index          = 1;
  #10 $stop;
end

endmodule
