//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/05/23
// Contributor: Jian Shi
// Reviewer: 
// Module Name: rat
// Target Devices: register renaming
// Description: 
// rename ARF to PRF
// Dependencies: 
// src/common/micro_op.svh, src/frontend/mappingtable.sv
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module rat (
  input   clock,
  input   reset,
  input   input_valid,

  input   recover,
  input   [`ARF_INT_SIZE-1:0]               arf_recover,
  input   [`RENAME_WIDTH-1:0]               retire_valid,

  input   micro_op_t                        pc_recover,
  input   micro_op_t   [`RENAME_WIDTH-1:0]  pc_retire,
  input   micro_op_t   [`RENAME_WIDTH-1:0]  uop_in,
  output  micro_op_t   [`RENAME_WIDTH-1:0]  uop_out,

  output  logic                             allocatable,
  output  reg                               ready
);

  // Info for check point table
  cp_index_t                      check_head;
  reg   [`RAT_CP_INDEX_SIZE:0]    check_size;

  cp_index_t                      check_head_next;
  logic [`RAT_CP_INDEX_SIZE:0]    check_size_next;

  reg                             recover_locker;
  reg   [`ARF_INT_SIZE-1:0]       arf_recover_locker;
  reg   [`RENAME_WIDTH-1:0]       retire_valid_locker;
  reg   [`RENAME_WIDTH-1:0]       retire_prev_valid_locker;
  cp_index_t                      recover_index_locker;
  cp_index_t                      retire_index_locker   [`RENAME_WIDTH-1:0];
  br_type_t                       retire_br_type_locker [`RENAME_WIDTH-1:0];
  br_type_t                       br_type_locker        [`RENAME_WIDTH-1:0];

  logic                           ready_next;

  // I/O for Mapping Table
  logic                                                 check;
  logic                                                 checkable;
  cp_index_t                                            check_idx;
  logic [`RENAME_WIDTH-1:0]                             check_flag;
  logic                                                 stall;

  reg   [`RENAME_WIDTH-1:0]                             rd_valid;
  reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1;
  reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2;
  reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd;
  logic [`RENAME_WIDTH-1:0]                             replace_req;
  reg   [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   replace_prf;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd;
  logic [`RENAME_WIDTH-1:0]                             prev_rd_valid;
  logic                                                 mp_allocatable;

mappingtable mapping_tb(
  .clock          (clock                ),
  .reset          (reset                ),
  .stall          (stall                ),
  .check          (check                ),
  .recover        (recover_locker       ),
  .check_idx      (check_idx            ),
  .check_flag     (check_flag           ),
  .recover_idx    (recover_index_locker ),
  .arf_recover    (arf_recover_locker   ),
  .rd_valid       (rd_valid             ),
  .rs1            (rs1                  ),
  .rs2            (rs2                  ),
  .rd             (rd                   ),
  .replace_req    (replace_req          ),
  .replace_prf    (replace_prf          ),
  .prs1           (prs1                 ),
  .prs2           (prs2                 ),
  .prd            (prd                  ),
  .prev_rd        (prev_rd              ),
  .prev_rd_valid  (prev_rd_valid        ),
  .allocatable    (mp_allocatable       )
);

  assign allocatable = mp_allocatable & checkable;
  assign stall = ~checkable;

  always_comb begin
    ready_next      = 0;
    check           = 0;
    checkable       = 1;
    check_head_next = check_head;
    check_size_next = check_size;
    check_idx       = 0;
    check_flag      = 0;
    if (recover_locker) begin
      if (recover_index_locker >= check_head_next) begin
        check_size_next = recover_index_locker - check_head_next + 1;
      end else begin
        check_size_next = `RAT_CP_SIZE + recover_index_locker - check_head_next + 1;
      end
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      // Meet Branch Prediction
      if (br_type_locker[i] != BR_X) begin
        // Have empty space for prediction
        if (check_size_next < `RAT_CP_SIZE) begin
          check         = 1;
          check_idx     = check_head_next + check_size_next;
          check_flag[i] = 1;
        end else begin
          checkable = 0;
        end
      end
    end
    ready_next = 1;
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      check_head  <= 0;
      check_size  <= 0;
      ready       <= 1;
    end else begin
      check_head <= check_head_next;
      check_size <= check_size_next;
    end
    if (input_valid) begin
      if (ready) begin
        recover_locker        <= recover;
        arf_recover_locker    <= arf_recover;
        retire_valid_locker   <= retire_valid;
        recover_index_locker  <= pc_recover.cp_index;
        for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
          retire_index_locker[i]    <= pc_retire[i].cp_index;
          retire_br_type_locker[i]  <= pc_retire[i].br_type;
          if (recover) begin
            br_type_locker[i]           <= BR_X;
            rd_valid[i]                 <= 0;
            rs1[i]                      <= 0;
            rs2[i]                      <= 0;
            rd[i]                       <= 0;
            replace_prf[i]              <= 0;
            retire_prev_valid_locker[i] <= 0;
          end else begin
            br_type_locker[i]           <= uop_in[i].br_type;
            rd_valid[i]                 <= uop_in[i].rd_valid;
            rs1[i]                      <= uop_in[i].rs1_arf_int_index;
            rs2[i]                      <= uop_in[i].rs2_arf_int_index;
            rd[i]                       <= uop_in[i].rd_arf_int_index;
            replace_prf[i]              <= uop_in[i].rd_prf_int_index_prev;
            retire_prev_valid_locker[i] <= uop_in[i].rd_prf_int_index_prev_valid;
            uop_out[i]                  <= uop_in[i];
          end
        end
        ready <= 0;
      end else begin
        ready <= ready_next;
      end
    end else begin
      ready <= ready_next;
    end
    if (ready_next & allocatable) begin
      for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
        uop_out[i].rs1_prf_int_index            <= prs1[i];
        uop_out[i].rs2_prf_int_index            <= prs2[i];
        uop_out[i].rd_prf_int_index             <= prd[i];
        uop_out[i].rd_prf_int_index_prev        <= prev_rd[i];
        uop_out[i].rd_prf_int_index_prev_valid  <= prev_rd_valid[i];
      end
    end
  end

endmodule
