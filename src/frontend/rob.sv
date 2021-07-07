// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Re-order Buffer (Track all inflight instructions in the pipeline)
// Author:  Jian Shi
// Date:    2021/06/08

`include "../common/micro_op.svh"

module rob (
  input           clock,
  input           reset,
  input           input_valid,

  input   micro_op_t  [`COMMIT_WIDTH-1:0]   uop_complete,
  input   micro_op_t  [`RENAME_WIDTH-1:0]   uop_in,

  output  micro_op_t  [`RENAME_WIDTH-1:0]   uop_out,

  output  reg                               recover,
  output  micro_op_t                        uop_recover,
  output  micro_op_t  [`COMMIT_WIDTH-1:0]   uop_retire,
  output  reg         [`ARF_INT_SIZE-1:0]   arf_recover,
  output  reg         [`PRF_INT_SIZE-1:0]   prf_recover,
  output  reg                               prediction,
  output  reg                               prediction_hit,

  output  reg                               allocatable,
  output  reg                               ready
);

  micro_op_t    op_list                     [`ROB_SIZE-1:0];
  micro_op_t    op_list_next                [`ROB_SIZE-1:0];

  rob_index_t                               rob_head;
  reg           [`ROB_INDEX_SIZE:0]         rob_size;

  rob_index_t                               rob_head_next;
  logic         [`ROB_INDEX_SIZE:0]         rob_size_next;
  logic         [`RENAME_WIDTH:0]           rob_size_increment;

  micro_op_t    uop_out_next                [`RENAME_WIDTH-1:0];
  logic                                     recover_next;
  micro_op_t    uop_retire_next             [`COMMIT_WIDTH-1:0];
  micro_op_t                                uop_recover_next;
  logic         [`ARF_INT_SIZE-1:0]         arf_recover_next;
  logic         [`PRF_INT_SIZE-1:0]         prf_recover_next;
  logic                                     allocatable_next;
  logic                                     prediction_next;
  logic                                     prediction_hit_next;

  micro_op_t    uop_complete_locker         [`COMMIT_WIDTH-1:0];
  micro_op_t    uop_in_locker               [`RENAME_WIDTH-1:0];

  always_comb begin
    rob_head_next       = rob_head;
    rob_size_next       = rob_size;
    recover_next        = 0;
    uop_recover_next    = 0;
    arf_recover_next    = 1;
    prf_recover_next    = 1;
    allocatable_next    = 1;
    rob_size_increment  = 0;
    prediction_next     = 0;
    prediction_hit_next = 1;
    for (int i = 0; i < `ROB_SIZE; ++i) begin
      op_list_next[i] = op_list[i];
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      uop_out_next[i] = uop_in[i];
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      uop_retire_next[i] = 0;
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      // Update completed uop
      if (uop_complete_locker[i].valid) begin
        uop_complete_locker[i].complete                 = 1;
        op_list_next[uop_complete_locker[i].rob_index]  = uop_complete_locker[i];
        // A branch-type uop
        if (uop_complete_locker[i].br_type != BR_X) begin
          prediction_next = 1;
          // A Mis-Prediction uop
          if (uop_complete_locker[i].exp_br != uop_complete_locker[i].real_br) begin
            recover_next        = 1;
            uop_recover_next    = uop_complete_locker[i];
            prediction_hit_next = 0;
          end
        end
      end
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      // A retirable uop
      if (op_list_next[rob_head + i].complete) begin
        rob_head_next += 1;
        rob_size_next -= 1;
      end else begin
        break;
      end
    end
    if (recover_next) begin
      for (int i = 0; i < rob_size_next; ++i) begin
        arf_recover_next[op_list_next[rob_head_next + i].rd_arf_int_index]      = 1;
        prf_recover_next[op_list_next[rob_head_next + i].rd_prf_int_index]      = 1;
        prf_recover_next[op_list_next[rob_head_next + i].rd_prf_int_index_prev] = 1;
      end
    end else begin
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        if (uop_in_locker[i].valid) begin
          rob_size_increment += 1;
        end
      end
      if (rob_size_increment <= `ROB_SIZE - rob_size_next) begin
        allocatable_next = 1;
      end else begin
        allocatable_next = 0;
      end
      if (allocatable_next) begin
        for (int i = 0; i < `RENAME_WIDTH; ++i) begin
          if (uop_in_locker[i].valid) begin
            op_list_next[rob_head_next + rob_size_next] = uop_in_locker[i];
            rob_size_next += 1;
          end
        end
      end else begin
        for (int i = 0; i < `RENAME_WIDTH; ++i) begin
          uop_out_next[i] = 0;
        end
      end
    end
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
      for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
        uop_complete_locker[i] <= uop_complete[i];
      end
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        uop_in_locker[i] <= uop_in[i];
      end
      ready <= 0;
    end else begin
      ready <= 1;
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      uop_out[i] <= uop_out_next[i];
    end
    recover         <= recover_next;
    uop_recover     <= uop_recover_next;
    arf_recover     <= arf_recover_next;
    prf_recover     <= prf_recover_next;
    allocatable     <= allocatable_next;
    prediction      <= prediction_next;
    prediction_hit  <= prediction_hit_next;
    if (ready) begin
      for (int i = 0; i < `ROB_SIZE; ++i) begin
        op_list[i] <= op_list_next[i];
      end
      for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
        uop_retire[i] <= uop_retire_next[i];
      end
    end
  end

endmodule
