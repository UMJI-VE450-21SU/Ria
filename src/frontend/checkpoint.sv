//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/02
// Contributor: Jian Shi
// Reviewer: 
// Module Name: check_point_int, check_point_fp
// Target Devices: check point table
// Description: 
// check point table for mapping table
// Dependencies: 
// src/common/micro_op.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module check_point_int (
  input       clock,
  input       reset,

  input       check,

  input       [`CP_INDEX_SIZE-1:0]                            check_idx,
  input       [`CP_INDEX_SIZE-1:0]                            recover_idx,
  input       [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_in,
  output reg  [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_out
);

  reg     [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint[`CP_NUM-1:0];
  logic   [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_out_next;

  initial begin
    for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
      checkpoint[i] = 0;
    end
  end

  assign checkpoint_out_next = checkpoint[recover_idx];

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
        checkpoint[i]       <= 0;
      end
    end if (check) begin
      checkpoint[check_idx] <= checkpoint_in;
    end
  end

  always_ff @(negedge clock) begin
    checkpoint_out          <= checkpoint_out_next;
  end

endmodule
