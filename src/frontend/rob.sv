// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Re-order Buffer (Track all inflight instructions in the pipeline)
// Author:  Jian Shi
// Date:    2021/06/08

`include "src/common/micro_op.svh"

module rob (
  input           clock,
  input           reset,

  input   micro_op_t  [`COMMIT_WIDTH-1:0] uop_complete,
  input   micro_op_t  [`RENAME_WIDTH-1:0] uop_in,

  output  micro_op_t  [`RENAME_WIDTH-1:0] uop_out,

  output  reg                             recover,
  output  micro_op_t                      uop_recover,
  output  micro_op_t  [`COMMIT_WIDTH-1:0] uop_retire,

  output  reg                             allocatable
);

  micro_op_t    op_list                   [`ROB_SIZE-1:0];
  micro_op_t    op_list_next              [`ROB_SIZE-1:0];

  rob_index_t                             rob_head;
  reg           [`ROB_INDEX_SIZE:0]       rob_size;

  rob_index_t                             rob_head_next;
  logic         [`ROB_INDEX_SIZE:0]       rob_size_next;

  logic                                   uop_valid;

  always_comb begin
    rob_head_next = rob_head;
    rob_size_next = rob_size;
    uop_valid     = 0;
    recover       = 0;
    uop_recover   = 0;
    allocatable   = 1;
    for (int i = 0; i < `ROB_SIZE; ++i) begin
      op_list_next[i] = op_list[i];
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      uop_out[i] = 0;
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      uop_retire[i] = 0;
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      uop_valid = uop_complete[i].valid;
      if (uop_valid) begin
        // Update completed uop
        op_list_next[uop_complete[i].rob_index]          = uop_complete[i];
        op_list_next[uop_complete[i].rob_index].complete = 1;
      end
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      if (i >= rob_size_next) begin
        // Not enough uop to retire
        break;
      end
      if (op_list_next[rob_head + i].complete) begin
        // A retirable uop
        rob_head_next += 1;
        rob_size_next -= 1;
        uop_retire[i] = op_list_next[rob_head + i];
        if (uop_retire[i].br_type != BR_X) begin
          // Branch-type uop
          // Jump-type uop
          if (uop_retire[i].pred_taken != uop_retire[i].br_taken) begin
            // A Mis-Prediction uop
            recover       = 1;
            uop_recover   = uop_retire[i];
            rob_head_next = 0;
            rob_size_next = 0;
            break;
          end
          if ((uop_retire[i].br_addr != uop_retire[i].pred_addr) && uop_retire[i].pred_taken) begin
            // A Mis-Prediction uop
            recover       = 1;
            uop_recover   = uop_retire[i];
            rob_head_next = 0;
            rob_size_next = 0;
            break;
          end
        end
      end else begin
        break;
      end
    end
    if (~recover) begin
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        if (rob_size_next < `ROB_SIZE) begin
          // Have enough rob space to store uop
          if (uop_in[i].valid) begin
            // A valid uop to store
            op_list_next[rob_head_next + rob_size_next]           = uop_in[i];
            op_list_next[rob_head_next + rob_size_next].rob_index = rob_head_next + rob_size_next;

            uop_out[i]    = op_list_next[rob_head_next + rob_size_next];
            rob_size_next += 1;
          end
        end else begin
          allocatable = 0;
        end
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      rob_head <= 0;
      rob_size <= 0;
      for (int i = 0; i < `ROB_SIZE; ++i) begin
        op_list[i] <= 0;
      end
    end else begin
      rob_head <= rob_head_next;
      rob_size <= rob_size_next;
      for (int i = 0; i < `ROB_SIZE; ++i) begin
        op_list[i] <= op_list_next[i];
      end
    end
  end

  wire rob_print = 0;

  always_ff @(posedge clock) begin
    if (rob_print) begin
      for (integer i = 0; i < `ROB_SIZE; i++) begin
        $display("[ROB] slot %d", i);
        print_uop(op_list[i]);
      end
      $display("[ROB] head=%d, size=%d, recover=%d", rob_head, rob_size, recover);
    end
  end

endmodule
