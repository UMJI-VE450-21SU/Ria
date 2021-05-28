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
// common/defines.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/defines.svh"
`define CP_NUM          2   // amount of check point
`define CP_INDEX_SIZE   1   // log2(CP_NUM)

module free_list (
  input   clock,
  input   reset,
  input   recover,
  input   [`PRF_INT_WAYS-1:0]                             inst_req,
  output  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   PRF,
  output  allocatable
);
  reg [`PRF_INT_SIZE-1:0] FREE_LIST;

endmodule

module check_point (
  input   clock,
  input   reset,

  input   check,
  input   request,

  input       [`CP_INDEX_SIZE-1:0]   check_index,
  input       [`CP_INDEX_SIZE-1:0]   request_index,
  input       [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_in,
  output logic[`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_out
);
  reg   [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint[`CP_NUM-1:0];

  initial begin
    for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
      checkpoint[i] = 0;
    end
  end

assign checkpoint_out = checkpoint[request_index];

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
        checkpoint[i] <= 0;
      end
    end else begin
        if (check) begin
          checkpoint[check_index] <= checkpoint_in;
        end
    end
  end

endmodule

module mapping_table (
  input   clock,
  input   reset,

  input   check,
  input   request,

  input   [`CP_INDEX_SIZE-1:0]                              check_index,
  input   [`CP_INDEX_SIZE-1:0]                              request_index,

  input   [`PRF_INT_WAYS-1:0]                               dst_valid,

  input        [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1：0]   src_L,
  input        [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1：0]   src_R,

  output logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1：0]   Psrc_L,
  output logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1：0]   Psrc_R,
);

checkpoint int_check_point(
  .clock        (clock),
  .reset        (reset),
  .check        (check),
  .request      (request),
  .check_index      (check_index),
  .request_index    (request_index),
  .checkpoint_in    (mapping_tb),
  .checkpoint_out   (mapping_tb_next)
);

  // Mapping Table
  reg   [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb[`ARF_INT_SIZE-1:0];
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb_next;

  logic [`PRF_INT_INDEX_SIZE-1:0]   src_L_next[`PRF_INT_WAYS-1:0];
  logic [`PRF_INT_INDEX_SIZE-1:0]   src_R_next[`PRF_INT_WAYS-1:0];

  initial begin
    for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
      mapping_tb[i] = 0;
    end
  end

  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i = i + 1) begin
      Psrc_L[i] = mapping_tb[src_L[i]];
      Psrc_R[i] = mapping_tb[src_R[i]];
    end
  end

  always_ff @(posedge clock) begin
    if (request) begin
      mapping_tb <= mapping_tb_next;
    end
  end

endmodule

module rat (
  input   clock,
  input   reset,
  input   recover,
  input   pause,

  input   [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   SRC_L,
  input   [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   SRC_R,
  input   [`PRF_INT_WAYS-1:0] [`ARF_INT_INDEX_SIZE-1:0]   DST,
  input   [`PRF_INT_WAYS-1:0]                             wr_en,

  input   [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]   FL,
  input   [`PRF_INT_WAYS-1:0]                             fl_n,

  output logic [`PRF_INT_WAYS-1:0]                          fl_used;
);



endmodule