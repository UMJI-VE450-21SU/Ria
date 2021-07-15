// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Free List for Physical Register File
// Author:  Jian Shi
// Date:    2021/06/02

`include "src/common/micro_op.svh"

module free_list (
  input       clock,
  input       reset,
  input       stall,

  input       recover,

  input         [`COMMIT_WIDTH-1:0]                           pre_prf_valid,
  input         [`COMMIT_WIDTH-1:0][`PRF_INT_INDEX_SIZE-1:0]  pre_prf,

  input         [`COMMIT_WIDTH-1:0]                           retire_prf_valid,
  input         [`COMMIT_WIDTH-1:0][`PRF_INT_INDEX_SIZE-1:0]  retire_prf,

  input         [`RENAME_WIDTH-1:0]                           prf_req,
  output logic  [`RENAME_WIDTH-1:0][`PRF_INT_INDEX_SIZE-1:0]  prf_out,
  output logic                                                allocatable
);

  // 0 for free; 1 for busy.
  reg     [`PRF_INT_SIZE-1:0]           free_list;
  reg     [`PRF_INT_INDEX_SIZE-1:0]     free_num;

  logic   [`PRF_INT_SIZE-1:0]           free_list_next;
  logic   [`PRF_INT_INDEX_SIZE-1:0]     free_num_next;

  logic   [`RENAME_WIDTH-1:0]           req_count;
  logic   [`RENAME_WIDTH-1:0]           req_idx;
  logic   [`RENAME_WIDTH-1:0]           req_idx_next;

  reg     [`PRF_INT_SIZE-1:0]           prf_recover;
  reg     [`PRF_INT_INDEX_SIZE-1:0]     prf_recover_num;

  logic   [`PRF_INT_SIZE-1:0]           prf_recover_next;
  logic   [`PRF_INT_INDEX_SIZE-1:0]     prf_recover_num_next;

  logic   [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out_next;

  always_comb begin
    free_list_next        = free_list;
    free_num_next         = free_num;
    prf_recover_next      = prf_recover;
    prf_recover_num_next  = prf_recover_num;
    req_count             = 0;
    req_idx               = 0;
    req_idx_next          = 0;
    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      prf_out[i] = 0;
      prf_out_next[i] = 0;
    end
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      if (pre_prf_valid[i]) begin
        free_num_next                 += 1;
        free_list_next[pre_prf[i]]    = 0;
        prf_recover_num_next          += 1;
        prf_recover_next[pre_prf[i]]  = 0;
      end
      if (retire_prf_valid[i]) begin
        prf_recover_num_next            -= 1;
        prf_recover_next[retire_prf[i]] = 1;
      end
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      if (prf_req[i]) begin
        req_count += 1;
      end
    end

    if (req_count <= free_num_next) begin
      for (int i = 0; i < `PRF_INT_SIZE; ++i) begin
        if (free_list_next[i] == 0) begin
          prf_out_next[req_idx] = i;
          req_idx += 1;
        end
        if (req_idx >= req_count) begin
          break;
        end
      end
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        if (prf_req[i]) begin
          prf_out[i] = prf_out_next[req_idx_next];
          free_list_next[prf_out_next[req_idx_next]] = 1;
          req_idx_next += 1;
        end
      end
      allocatable = 1;
    end else begin
      allocatable = 0;
    end
    if (allocatable) begin
      free_num_next = free_num_next - req_count;
    end
  end

  // Store calculation result & output final result
  always_ff @(posedge clock) begin
    if (reset) begin
      free_list       <= `PRF_INT_SIZE'b1;
      free_num        <= `PRF_INT_SIZE-1;
      prf_recover     <= `PRF_INT_SIZE'b1;
      prf_recover_num <= `PRF_INT_SIZE-1;
    end else if (recover) begin
      free_list       <= prf_recover_next;
      free_num        <= prf_recover_num_next;
      prf_recover     <= prf_recover_next;
      prf_recover_num <= prf_recover_num_next;
    end else if (!stall) begin
      free_list       <= free_list_next;
      free_num        <= free_num_next;
      prf_recover     <= prf_recover_next;
      prf_recover_num <= prf_recover_num_next;
    end
  end

endmodule
