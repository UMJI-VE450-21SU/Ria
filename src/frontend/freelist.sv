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

  input       check,
  input       recover,

  input       cp_index_t                                      check_idx,
  input       cp_index_t                                      recover_idx,

  input       [`RENAME_WIDTH-1:0]                             prf_replace_valid,
  input       [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_replace,

  input       [`RENAME_WIDTH-1:0]                             prf_req,
  output reg  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out,
  output reg                                                  allocatable
);

  // 0 for free; 1 for busy.
  reg     [`PRF_INT_SIZE-1:0]           free_list;
  reg     [`PRF_INT_SIZE-1:0]           free_list_check_point[`RAT_CP_SIZE-1:0];
  reg     [`PRF_INT_INDEX_SIZE-1:0]     free_num_check_point[`RAT_CP_SIZE-1:0];

  logic   [`PRF_INT_SIZE-1:0]           free_list_next;
  logic   [`PRF_INT_SIZE-1:0]           free_list_increase;
  logic   [`PRF_INT_SIZE-1:0]           free_list_decrease;

  logic   [`PRF_INT_WAYS_SIZE:0]        free_list_decrease_num;
  logic   [`PRF_INT_WAYS_SIZE:0]        free_list_decrease_count;

  logic   [`PRF_INT_INDEX_SIZE-1:0]     prf_out_list[`RENAME_WIDTH-1:0];
  logic   [`PRF_INT_INDEX_SIZE-1:0]     prf_out_next[`RENAME_WIDTH-1:0];
  logic   [`PRF_INT_WAYS_SIZE-1:0]      prf_out_count;

  reg     [`PRF_INT_INDEX_SIZE-1:0]     free_num;
  logic   [`PRF_INT_INDEX_SIZE-1:0]     free_num_next;

  logic                                 allocatable_next;

  always_comb begin
    free_num_next             = free_num;
    free_list_increase        = free_list;
    free_list_decrease_num    = 0;
    free_list_decrease_count  = 0;
    prf_out_count             = 0;

    // Calculate Free List after `replace`
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
      prf_out_list[i] = 0;
      prf_out_next[i] = 0;
      if (prf_replace_valid[i]) begin
        free_list_increase[prf_replace[i]] = 1'b0;
        free_num_next = free_num_next + 1;
      end
      if (prf_req[i]) begin
        free_list_decrease_num = free_list_decrease_num + 1;
      end
    end

    // Take replaced PRF into consideration
    free_list_decrease = free_list_increase;
    
    // Check allocatable
    if (free_list_decrease_num <= free_num_next) begin
      allocatable_next = 1;

      // Allocate & Compress free PRF list
      for (int i = 0; i < `PRF_INT_SIZE; i = i + 1 )  begin
        if (free_list_increase[i] == 1'b0) begin
          free_list_decrease[i] = 1'b1;
          prf_out_list[free_list_decrease_count] = i;
          free_list_decrease_count = free_list_decrease_count + 1;
        end
        if (free_list_decrease_count >= free_list_decrease_num) begin
          break;
        end
      end
      free_list_next = free_list_decrease;

      // Decompress free PRF list
      for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
        if (prf_req[i]) begin
          prf_out_next[i] = prf_out_list[prf_out_count];
          prf_out_count = prf_out_count + 1;
        end
      end
    end else begin
      allocatable_next = 0;
      free_list_next = free_list_increase;
    end
  end

  // Store calculation result & output final result
  always_ff @(posedge clock) begin
    if (reset) begin
      free_list <= `PRF_INT_SIZE'b1;
      free_num  <= `PRF_INT_SIZE-1;
    end else if (recover) begin
      free_list <= free_list_check_point[recover_idx];
      free_num  <= free_num_check_point[recover_idx];
    end else if (allocatable_next) begin
      free_list <= free_list_next;
      free_num  <= free_num_next - free_list_decrease_num;
      for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
        prf_out[i] <= prf_out_next[i];
      end
    end else begin
      free_list <= free_list_next;
      free_num  <= free_num_next;
    end
    allocatable <= allocatable_next;
  end

  // Check point & Recover
  always_ff @(posedge clock) begin
    if (reset) begin
      // PRF 0 is always not allocatable.
      for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
        free_list_check_point[i]        <= `PRF_INT_SIZE'b1;
        free_num_check_point[i]         <= `PRF_INT_SIZE - 1;
      end
    end else if (check) begin
      free_list_check_point[check_idx]  <= free_list;
      free_num_check_point[check_idx]   <= free_num;
    end
  end

endmodule
