//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Jian Shi
// Reviewer: 
// Module Name: freelist_tb
// Target Devices: testbench for free list
// Description: 
// testbench for free list
// Dependencies: 
// src/frontend/freelist.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module freelist_tb;
parameter half_clk_cycle = 1;

reg  clock, reset, check, recover;
reg [`CP_INDEX_SIZE-1:0]                            check_idx;
reg [`CP_INDEX_SIZE-1:0]                            recover_idx;

reg [`RENAME_WIDTH-1:0]                             replace_valid;
reg [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_replace;

reg [`RENAME_WIDTH-1:0]                             prf_req;

wire[`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out;
wire                                                allocatable;

freelist_int UTT(
  .clock              (clock            ),
  .reset              (reset            ),
  .check              (check            ),
  .recover            (recover          ),
  .check_idx          (check_idx        ),
  .recover_idx        (recover_idx      ),
  .prf_replace_valid  (replace_valid    ),
  .prf_replace        (prf_replace      ),
  .prf_req            (prf_req          ),
  .prf_out            (prf_out          ),
  .allocatable        (allocatable      )
);

always #half_clk_cycle clock = ~clock;

initial begin
    #0 clock = 0; reset = 1; check = 0; recover = 0; check_idx = 0; recover_idx = 0; prf_replace = 0; prf_req = 0;
    #2 reset = 0;
    #2 prf_req = 3'b010; replace_valid = 3'b000;
    #2 prf_replace = 18'b1; replace_valid = 3'b001;
    #2 prf_req = 3'b0;
    #2 replace_valid = 3'b000;
    #4 prf_req = 3'b011; replace_valid = 3'b000;
    #10 prf_replace = 18'b000000000010000001; replace_valid = 3'b011;
    #4 replace_valid = 3'b000;
    #10 prf_replace = 18'b001100000010000001; replace_valid = 3'b111;
    #2 replace_valid = 3'b000;
    #48 prf_req = 3'b0;
    #6 check = 1; check_idx = 0;
    #2 check = 0;
    #2 prf_replace = 18'b001100000010000001; replace_valid = 3'b111;
    #2 replace_valid = 3'b000;
    #2 prf_replace = 18'b011100010011000001; replace_valid = 3'b111;
    #2 replace_valid = 3'b000;
    #2 prf_req = 3'b011;
    #2 recover = 1; recover_idx = 0;
    #2 prf_req = 3'b010;
    #6 $stop;
end

endmodule
