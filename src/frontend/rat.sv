//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/05/23
// Contributor: Jian Shi
// Reviewer: 
// Module Name: rat
// Target Devices: register renaming
// Description: 
// Record Mapping Relation between PRF & ARF; SRAM-Based RAT, sRAT
// Dependencies: 
// common/micro_op.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"
`define CP_NUM          2   // amount of check point
`define CP_INDEX_SIZE   1   // log2(CP_NUM)

module free_list_int (
  input   clock,
  input   reset,

  input   check,
  input   recover,

  input       [`CP_INDEX_SIZE-1:0]                            check_idx,
  input       [`CP_INDEX_SIZE-1:0]                            recover_idx,

  input       [`PRF_INT_WAYS-1:0]                             commit_valid,
  input       [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_commit,

  input       [`PRF_INT_WAYS-1:0]                             prf_req,
  output reg  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out,
  output reg                                                  allocatable
);

  // 0 for free; 1 for busy.
  reg     [`PRF_INT_SIZE-1:0]           free_list;
  reg     [`PRF_INT_SIZE-1:0]           free_list_check_point[`CP_NUM-1:0];
  reg     [`PRF_INT_INDEX_SIZE-1:0]     free_num_check_point[`CP_NUM-1:0];

  logic   [`PRF_INT_SIZE-1:0]           free_list_next;
  logic   [`PRF_INT_SIZE-1:0]           free_list_increase;
  logic   [`PRF_INT_SIZE-1:0]           free_list_decrease;

  logic   [`PRF_INT_WAYS_SIZE-1:0]      free_list_decrease_num;
  logic   [`PRF_INT_WAYS_SIZE-1:0]      free_list_decrease_count;

  logic   [`PRF_INT_INDEX_SIZE-1:0]     prf_out_list[`PRF_INT_WAYS-1:0];
  logic   [`PRF_INT_INDEX_SIZE-1:0]     prf_out_next[`PRF_INT_WAYS-1:0];
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
    for (int i = 0; i < `PRF_INT_WAYS; i = i + 1 )  begin
      prf_out_list[i] = 0;
      prf_out_next[i] = 0;
      if (commit_valid[i]) begin
        free_list_increase[prf_commit[i]] = 1'b0;
        free_num_next = free_num_next + 1;
      end
      if (prf_req[i]) begin
        free_list_decrease_num = free_list_decrease_num + 1;
      end
    end
    free_list_decrease = free_list_increase;
    if (free_list_decrease_num <= free_num_next) begin
      allocatable_next = 1;
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
      for (int i = 0; i < `PRF_INT_WAYS; i = i + 1 )  begin
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

  always_ff @(posedge clock) begin
    if (reset) begin
      free_list <= `PRF_INT_SIZE'b1;
      free_num <= `PRF_INT_SIZE-1;
    end else if (recover) begin
      free_list <= free_list_check_point[recover_idx];
      free_num  <= free_num_check_point[recover_idx];
    end else if (allocatable_next) begin
      free_list <= free_list_next;
      free_num <= free_num_next - free_list_decrease_num;
      for (int i = 0; i < `PRF_INT_WAYS; ++i )  begin
        prf_out[i] <= prf_out_next[i];
      end
    end else begin
      free_list <= free_list_next;
      free_num <= free_num_next;
    end
    allocatable <= allocatable_next;
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      // PRF 0 is always not allocatable.
      for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
        free_list_check_point[i] <= `PRF_INT_SIZE'b1;
        free_num_check_point[i] <= `PRF_INT_SIZE - 1;
      end
    end else if (check) begin
      free_list_check_point[check_idx] <= free_list;
      free_num_check_point[check_idx] <= free_num;
    end
  end

endmodule

module check_point_int (
  input   clock,
  input   reset,

  input   check,

  input       [`CP_INDEX_SIZE-1:0]   check_idx,
  input       [`CP_INDEX_SIZE-1:0]   recover_idx,
  input       [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_in,
  input       [`ARF_INT_SIZE-1:0]                             occupy_in,
  output logic[`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_out,
  output logic[`ARF_INT_SIZE-1:0]                             occupy_out
);
  reg         [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint[`CP_NUM-1:0];
  reg         [`ARF_INT_SIZE-1:0]                             occupy_checkpoint[`CP_NUM-1:0];

  initial begin
    for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
      checkpoint[i] = 0;
    end
  end

  assign checkpoint_out = checkpoint[recover_idx];
  assign occupy_out = occupy_checkpoint[recover_idx];

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
        checkpoint[i] <= 0;
        occupy_checkpoint[i] <= 0;
      end
    end if (check) begin
      checkpoint[check_idx] <= checkpoint_in;
      occupy_checkpoint[check_idx] <= occupy_in;
    end
  end

endmodule

module map_table (
  input   clock,
  input   reset,

  input   check,
  input   recover,
  input   pause,

  input   [`CP_INDEX_SIZE-1:0]                                  check_idx,
  input   [`CP_INDEX_SIZE-1:0]                                  recover_idx,

  input   [`PRF_INT_WAYS-1:0]                                   dst_valid,

  input         [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   src_l,
  input         [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   src_r,
  input         [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   dst,

  input         [`PRF_INT_WAYS-1:0]                             retire_req,
  input         [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   retire_arf,

  output logic  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   psrc_l,
  output logic  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   psrc_r,

  output logic                                                  allocatable
);

  // Mapping Table
  reg   [`PRF_INT_INDEX_SIZE-1:0]                       mapping_tb[`ARF_INT_SIZE-1:0];
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb_next;
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb_cp;
  reg   [`ARF_INT_SIZE-1:0]                             occupy;
  logic [`ARF_INT_SIZE-1:0]                             occupy_next;
  logic [`ARF_INT_SIZE-1:0]                             occupy_cp;

  // Free List
  logic [`PRF_INT_WAYS-1:0]                             commit_valid;
  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_commit;
  logic [`PRF_INT_SIZE-1:0]                             prf_req;
  logic [`PRF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out;

check_point_int int_check_point(
  .clock            (clock),
  .reset            (reset),
  .check            (check),
  .check_idx        (check_idx),
  .recover_idx      (recover_idx),
  .checkpoint_in    (mapping_tb),
  .occupy_in        (occupy),
  .checkpoint_out   (mapping_tb_cp),
  .occupy_out       (occupy_cp)
);

free_list_int  int_free_list(
  .clock              (clock),
  .reset              (reset),
  .check              (check),
  .recover            (recover),
  .check_idx          (check_idx),
  .recover_idx        (recover_idx),
  .commit_valid       (commit_valid),
  .prf_commit         (prf_commit),
  .prf_req            (prf_req),
  .prf_out            (prf_out),
  .allocatable        (allocatable)
);

  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i = i + 1) begin
      psrc_l[i] = mapping_tb[src_l[i]];
      psrc_r[i] = mapping_tb[src_r[i]];
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= 0;
      end
      occupy <= 0;
    end
    else if (recover) begin
      mapping_tb <= mapping_tb_cp;
    end
    else begin
      
    end
  end

endmodule

module rat (
  input   clock,
  input   reset,
  input   recover,
  input   pause,
  input   micro_op_t  [`PRF_INT_WAYS-1:0] uop_in,
  output  micro_op_t  [`PRF_INT_WAYS-1:0] uop_out,
  output  allocatable
);
  
endmodule