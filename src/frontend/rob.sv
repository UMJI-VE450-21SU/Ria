//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/08
// Contributor: Jian Shi
// Reviewer: 
// Module Name: rob
// Target Devices: reorder buffer
// Description: 
// track the state of all inflight instructions in the pipeline
// Dependencies: 
// src/common/micro_op.svh, src/frontend/rat.sv
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module rob (
  input           clock,
  input           reset,

  input           recover,
  input   [31:0]  recover_pc,
  input   micro_op_t  [`RENAME_WIDTH-1:0]   uop_retire,
  input               [`RENAME_WIDTH-1:0]   retire_valid,
  input   micro_op_t  [`RENAME_WIDTH-1:0]   uop_in,
  input               [`RENAME_WIDTH-1:0]   in_valid,

  output              [`RENAME_WIDTH-1:0]   retire_ready,
  output              [`RENAME_WIDTH-1:0]   in_ready
);
  
endmodule
