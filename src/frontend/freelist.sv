//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/02
// Contributor: Jian Shi
// Reviewer: Li Shi, Yiqiu Sun, Yichao Yuan, Zhiyuan Liu
// Module Name: freelist_int, freelist_fp
// Target Devices: free list
// Description: 
// free list for Physical Register File
// Dependencies: 
// src/common/micro_op.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module freelist_int (
  input       clock,
  input       reset,

  input       recover,
  input       [`PRF_INT_SIZE-1:0]                             recover_fl,

  input       [`RENAME_WIDTH-1:0]                             prf_replace_valid,
  input       [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_replace,

  input       [`RENAME_WIDTH-1:0]                             prf_req,
  output reg  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out,
  output reg                                                  allocatable
);

  // 0 for free; 1 for busy.
  reg     [`PRF_INT_SIZE-1:0]           free_list;
  reg     [`PRF_INT_INDEX_SIZE-1:0]     free_num;

  logic   [`PRF_INT_SIZE-1:0]           free_list_next;
  logic   [`PRF_INT_INDEX_SIZE-1:0]     free_num_next;

  logic   [`RENAME_WIDTH-1:0]           req_count;
  logic   [`RENAME_WIDTH-1:0]           req_idx;
  logic   [`RENAME_WIDTH-1:0]           req_idx_next;
  logic   [`PRF_INT_INDEX_SIZE-1:0]     recover_fl_num;

  logic   [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out_next;

  always_comb begin
    recover_fl_num = 0;
    for (int i = 0; i < `PRF_INT_SIZE; ++i )  begin
      if (recover_fl[i] == 0) begin
        recover_fl_num += 1;
      end
    end
  end

  always_comb begin
    free_list_next  = free_list;
    free_num_next   = free_num;
    req_count       = 0;
    req_idx         = 0;
    req_idx_next    = 0;
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      if (prf_replace_valid[i]) begin
        free_num_next += 1;
        free_list_next[prf_replace[i]] = 0;
      end
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      if (prf_req[i]) begin
        req_count += 1;
      end
    end

    if (req_count <= free_num_next) begin
      for (int i = 0; i < `PRF_INT_SIZE; ++i )  begin
        if (free_list_next[i] == 0) begin
          prf_out_next[req_idx] = i;
          req_idx += 1;
        end
        if (req_idx >= req_count) begin
          break;
        end
      end
      for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
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
      free_list <= `PRF_INT_SIZE'b1;
      free_num  <= `PRF_INT_SIZE-1;
    end else if (recover) begin
      free_list <= recover_fl;
      free_num  <= recover_fl_num;
    end else begin
      free_list <= free_list_next;
      free_num  <= free_num_next;
    end
  end

endmodule
