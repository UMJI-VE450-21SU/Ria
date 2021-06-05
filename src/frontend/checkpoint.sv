//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/02
// Contributor: Jian Shi
// Reviewer: Li Shi, Yiqiu Sun, Yichao Yuan, Zhiyuan Liu
// Module Name: checkpoint_int, checkpoint_fp
// Target Devices: check point table
// Description: 
// check point table for mapping table
// Dependencies: 
// src/common/micro_op.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module checkpoint_int (
  input       clock,
  input       reset,

  input       check,

  input       [`RAT_CP_INDEX_SIZE-1:0]                        check_idx,
  input       [`RAT_CP_INDEX_SIZE-1:0]                        recover_idx,

  input       [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_in,
  output logic[`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_out,

  input       [`PRF_INT_SIZE-1:0]                             valid_in,
  output logic[`PRF_INT_SIZE-1:0]                             valid_out
);

  reg     [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint[`RAT_CP_SIZE-1:0];
  reg     [`PRF_INT_SIZE-1:0]                             valid_cp[`RAT_CP_SIZE-1:0];


  initial begin
    for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
      checkpoint[i] = 0;
    end
  end

  assign checkpoint_out = checkpoint[recover_idx];
  assign valid_out      = valid_cp[recover_idx];

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
        checkpoint[i]       <= 0;
        valid_cp[i]         <= 0;
      end
    end if (check) begin
      checkpoint[check_idx] <= checkpoint_in;
      valid_cp[check_idx]   <= valid_in;
    end
  end

endmodule
