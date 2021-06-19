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

reg  clock, reset, recover, stall;

reg  [`PRF_INT_SIZE-1:0]                         recover_fl;

reg  [`RENAME_WIDTH-1:0]                              replace_valid;
reg  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    prf_replace;

reg  [`RENAME_WIDTH-1:0]                              prf_req;

wire [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    prf_out;
wire                                                  allocatable;

freelist_int UTT(
  .clock              (clock            ),
  .reset              (reset            ),
  .stall              (stall            ),
  .recover            (recover          ),
  .recover_fl         (recover_fl       ),
  .prf_replace_valid  (replace_valid    ),
  .prf_replace        (prf_replace      ),
  .prf_req            (prf_req          ),
  .prf_out            (prf_out          ),
  .allocatable        (allocatable      )
);

always #half_clk_cycle clock = ~clock;

initial begin
  #0 clock = 0; reset = 1; recover = 0; recover_fl = 0;
  replace_valid = 0; prf_replace = 0; prf_req = 0; stall = 0;
  #2 reset = 0;
  #2 prf_req = 4'b1111; replace_valid = 4'b0;
  #2 prf_replace = 18'b1; replace_valid = 4'b0001;
  #2 prf_req = 4'b0;
  #2 replace_valid = 4'b0;
  #4 prf_req = 4'b0011; replace_valid = 4'b0;
  #10 prf_replace = 18'b000000000010000001; replace_valid = 4'b0011; stall = 1;
  #4 replace_valid = 4'b0; stall = 0;
  #10 prf_replace = 18'b001100000010000001; replace_valid = 4'b0111;
  #2 replace_valid = 4'b0;
  #48 prf_req = 4'b0;
  #2 prf_replace = 18'b001100000010000001; replace_valid = 4'b0111;
  #2 replace_valid = 4'b0;
  #2 prf_replace = 18'b011100010011000001; replace_valid = 4'b0110;
  #2 replace_valid = 4'b0;
  #2 recover = 1; recover_fl = 1;
  #2 recover = 0; recover_fl = 0;
  #2 prf_req = 4'b0011;
  #2 prf_req = 4'b0010;
  #6 $stop;
end

endmodule
