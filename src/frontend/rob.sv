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
// src/common/micro_op.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module rob (
  input           clock,
  input           reset,
  input           input_valid,

  input                                     recover,
  input   micro_op_t                        uop_recover,
  input   micro_op_t  [`RENAME_WIDTH-1:0]   uop_retire,
  input               [`RENAME_WIDTH-1:0]   retire_valid,
  input   micro_op_t  [`RENAME_WIDTH-1:0]   uop_in,
  input               [`RENAME_WIDTH-1:0]   in_valid,

  output  micro_op_t  [`RENAME_WIDTH-1:0]   uop_out,
  output  reg         [`ARF_INT_SIZE-1:0]   arf_recover,
  output  reg         [`PRF_INT_SIZE-1:0]   prf_recover,
  output  reg         [`RENAME_WIDTH-1:0]   retire_ready,
  output  reg         [`RENAME_WIDTH-1:0]   out_valid,
  output  reg                               ready,
  output  logic                             allocatable
);

  micro_op_t                                op_list[`ROB_SIZE-1:0];

  rob_index_t                               rob_head;
  reg           [`ROB_INDEX_SIZE:0]         rob_size;

  rob_index_t                               rob_head_next;
  logic         [`ROB_INDEX_SIZE:0]         rob_size_next;

  logic                                     ready_next;
  logic         [`RENAME_WIDTH-1:0]         retire_ready_next;
  logic         [`RENAME_WIDTH-1:0]         out_valid_next;
  micro_op_t    [`RENAME_WIDTH-1:0]         uop_out_next;
  logic         [`ARF_INT_SIZE-1:0]         arf_recover_next;
  logic         [`PRF_INT_SIZE-1:0]         prf_recover_next;

  logic                                     recover_locker;
  micro_op_t                                uop_recover_locker;
  rob_index_t                               recover_index;

  micro_op_t                                uop_retire_locker [`RENAME_WIDTH-1:0];
  micro_op_t                                uop_in_locker     [`RENAME_WIDTH-1:0];
  reg           [`RENAME_WIDTH-1:0]         retire_valid_locker;
  reg           [`RENAME_WIDTH-1:0]         in_valid_locker;

  rob_index_t                               update_list       [`RENAME_WIDTH-1:0];

  always_comb begin
    rob_head_next     = rob_head;
    rob_size_next     = rob_size;
    ready_next        = 0;
    retire_ready_next = 0;
    out_valid_next    = 0;
    allocatable       = 1;
    arf_recover_next  = 1;
    prf_recover_next  = 1;
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      update_list[i]  = 0;
      uop_out_next[i] = uop_in_locker[i];
    end
    if (recover_locker) begin
      recover_index = uop_recover_locker.rob_index;
      if (recover_index >= rob_head_next) begin
        rob_size_next = recover_index - rob_head_next + 1;
      end else begin
        rob_size_next = `ROB_SIZE + recover_index - rob_head_next + 1;
      end
      for (int i = 0; i < MAX; ++i )  begin
        if (op_list[rob_head_next + i].rd_valid) begin
          arf_recover_next[op_list[rob_head_next + i].rd_arf_int_index]       = 1;
          prf_recover_next[op_list[rob_head_next + i].rd_prf_int_index]       = 1;
          prf_recover_next[op_list[rob_head_next + i].rd_prf_int_index_prev]  = 1;
        end
      end
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      // A finished Instruction
      if (retire_valid_locker[i]) begin
        // An Instruction to retire
        if (uop_retire_locker[i].rob_index == rob_head_next + i) begin
          retire_ready_next[i] = 1;
          rob_head_next += 1;
          rob_size_next -= 1;
        end else begin
          break;
        end
      end
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      // An Instrcution to store
      if (in_valid_locker[i]) begin
        // Have empty space to store
        if (rob_size_next < `ROB_SIZE) begin
          out_valid_next[i] = 1;
        end else begin
          out_valid_next  = 0;
          allocatable     = 0;
          break;
        end
        if (out_valid_next[i]) begin
          uop_out_next[i].rob_index = rob_head_next + rob_size_next;
          rob_size_next += 1;
        end
      end
    end
    ready_next = 1;
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      rob_head <= 0;
      rob_size <= 0;
    end else begin
      rob_head <= rob_head_next;
      rob_size <= rob_size_next;
    end
    if (input_valid & ready) begin
      recover_locker        <= recover;
      uop_recover_locker    <= uop_recover;
      retire_valid_locker   <= retire_valid;
      in_valid_locker       <= in_valid;
      ready                 <= 0;
      for (int i = 0; i < `RENAME_WIDTH; ++i ) begin
        uop_retire_locker[i]  <= uop_retire[i];
        uop_in_locker[i]      <= uop_in[i];
      end
    end else begin
      ready <= ready_next;
    end
    if (ready_next) begin
      retire_ready        <= retire_ready_next;
      out_valid           <= out_valid_next;
      for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
        if (out_valid_next[i]) begin
          op_list[update_list[i]] <= uop_out[i];
        end
        uop_out <= uop_out_next;
      end
    end
    if (recover) begin
      arf_recover <= arf_recover_next;
      prf_recover <= prf_recover_next;
    end
  end

endmodule
