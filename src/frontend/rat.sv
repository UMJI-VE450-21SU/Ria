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
`define CP_NUM          4
`define CP_INDEX_SIZE   2   // log2(CP_NUM)

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

  input   recover,
  input   check,
  input   request,

  input         [`CP_INDEX_SIZE-1:0]   target_index,
  input         [`CP_INDEX_SIZE-1:0]   request_index,
  input         [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_in,
  output  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_out
);
  reg   [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint[`CP_NUM-1:0];
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   checkpoint_next;

  initial begin
    for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
      checkpoint[i] = 0;
    end
  end

assign checkpoint_next = checkpoint[request_index];

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `CP_NUM; i = i + 1 )  begin
        checkpoint[i] <= 0;
      end
    end else begin
        if (check) begin
          checkpoint[target_index] <= checkpoint_in;
        end
        if (request) begin
          checkpoint_out <= checkpoint_next;
        end
    end
  end

endmodule

module mapping_table (
  input   clock,
  input   reset,
  input   recover,
  input   recover_index,
  input   
  input   [`PRF_INT_WAYS-1:0]                               dst_valid,

  output logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1：0]   RSRC_L,
  output logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1：0]   RSRC_R,
);

  // Mapping Table
  reg [`PRF_INT_INDEX_SIZE-1:0]                   MP_TB   [`ARF_INT_SIZE-1:0];

  initial begin
    for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
      for (int j = 0; j < `PRF_INT_INDEX_SIZE; j = j + 1 )  begin
        MP_TB[i][j] = 0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i = i + 1) begin
      RSRC_L[i] = MP_TB[RSRC_L[i]];
      RSRC_R[i] = MP_TB[RSRC_R[i]];
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