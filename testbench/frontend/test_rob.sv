//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/22
// Contributor: Jian Shi
// Reviewer: 
// Module Name: rob_tb
// Target Devices: testbench for reorder buffer
// Description: 
// testbench for reorder buffer
// Dependencies: 
// src/front/rob.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module rob_tb;
parameter half_clk_cycle = 1;

reg  clock, reset, recover, input_valid;
micro_op_t                          uop_recover;
micro_op_t    [`RENAME_WIDTH-1:0]   uop_retire;
reg           [`RENAME_WIDTH-1:0]   retire_valid;
micro_op_t    [`RENAME_WIDTH-1:0]   uop_in;
reg           [`RENAME_WIDTH-1:0]   in_valid;

micro_op_t    [`RENAME_WIDTH-1:0]   uop_out;
wire          [`RENAME_WIDTH-1:0]   retire_ready;
wire          [`RENAME_WIDTH-1:0]   out_valid;
wire                                ready;
wire                                allocatable;

rob UTT(
  .clock          (clock          ),
  .reset          (reset          ),
  .input_valid    (input_valid    ),
  .recover        (recover        ),
  .uop_recover    (uop_recover    ),
  .uop_retire     (uop_retire     ),
  .retire_valid   (retire_valid   ),
  .uop_in         (uop_in         ),
  .in_valid       (in_valid       ),
  .uop_out        (uop_out        ),
  .retire_ready   (retire_ready   ),
  .out_valid      (out_valid      ),
  .ready          (ready          ),
  .allocatable    (allocatable    )
);

always #half_clk_cycle clock = ~clock;

initial begin
  #0 clock = 0; reset = 1; recover = 0; input_valid = 0;
  retire_valid = 0; in_valid = 0;
  #2 reset = 0;
  #6 $stop;
end

endmodule
