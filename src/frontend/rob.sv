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

  output                                    recover,
  output  micro_op_t                        uop_recover,
  output  reg         [`ARF_INT_SIZE-1:0]   arf_recover,
  output  reg         [`PRF_INT_SIZE-1:0]   prf_recover,

  output  logic                             allocatable,
  output  reg                               ready
);

  micro_op_t                                op_list[`ROB_SIZE-1:0];

  rob_index_t                               rob_head;
  reg           [`ROB_INDEX_SIZE:0]         rob_size;

  rob_index_t                               rob_head_next;
  logic         [`ROB_INDEX_SIZE:0]         rob_size_next;

  micro_op_t    [`COMMIT_WIDTH-1:0]         uop_out_next;
  logic         [`ARF_INT_SIZE-1:0]         arf_recover_next;
  logic         [`PRF_INT_SIZE-1:0]         prf_recover_next;

  reg                                       recover_locker;
  micro_op_t                                uop_recover_locker;
  rob_index_t                               recover_index;

  micro_op_t                                uop_complete_locker [`COMMIT_WIDTH-1:0];
  micro_op_t                                uop_in_locker     [`RENAME_WIDTH-1:0];

  always_comb begin
    rob_head_next     = rob_head;
    rob_size_next     = rob_size;
    allocatable       = 1;
    arf_recover_next  = 1;
    prf_recover_next  = 1;
    recover_index     = uop_recover_locker.rob_index;
    for (int i = 0; i < `COMMIT_WIDTH; ++i )  begin
      update_list[i]  = 0;
      uop_out_next[i] = uop_in_locker[i];
    end
    if (recover_locker) begin
      if (recover_index >= rob_head_next) begin
        rob_size_next = recover_index - rob_head_next + 1;
      end else begin
        rob_size_next = `ROB_SIZE + recover_index - rob_head_next + 1;
      end
      for (int i = 0; i < rob_size_next; ++i )  begin
        if (op_list[rob_head_next + i].rd_valid) begin
          arf_recover_next[op_list[rob_head_next + i].rd_arf_int_index]       = 1;
          prf_recover_next[op_list[rob_head_next + i].rd_prf_int_index]       = 1;
          prf_recover_next[op_list[rob_head_next + i].rd_prf_int_index_prev]  = 1;
        end
      end
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i )  begin
      // A finished Instruction
      if (complete_valid_locker[i]) begin
        // An Instruction to complete
        if (uop_complete_locker[i].rob_index == rob_head_next + i) begin
          complete_ready_next[i] = 1;
          rob_head_next += 1;
          rob_size_next -= 1;
        end else begin
          break;
        end
      end
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i )  begin
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
      for (int i = 0; i < `COMMIT_WIDTH; ++i ) begin
        uop_complete_locker[i]  <= uop_complete[i];
      end
      for (int i = 0; i < `RENAME_WIDTH; ++i ) begin
        uop_in_locker[i]      <= uop_in[i];
      end
      ready <= 0;
    end else begin
      ready <= 1;
    end
    if (ready_next) begin
      for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
        if (out_valid_next[i]) begin
          op_list[update_list[i]] <= uop_out[i];
        end
        uop_out <= uop_out_next;
      end
    end
    arf_recover <= arf_recover_next;
    prf_recover <= prf_recover_next;
  end

endmodule
