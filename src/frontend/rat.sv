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

  input   recover,
  input   [`RENAME_WIDTH-1:0]               retire_valid,

  input   micro_op_t                        pc_recover,
  input   micro_op_t   [`RENAME_WIDTH-1:0]  pc_retire,
  input   micro_op_t   [`RENAME_WIDTH-1:0]  uop_in,
  output  micro_op_t   [`RENAME_WIDTH-1:0]  uop_out,

  output  logic                             allocatable,
  output  reg                               checkable,

  output  logic                             ready
);

  // Info for check point table
  reg   [`RAT_CP_INDEX_SIZE-1:0]  check_head;
  reg   [`RAT_CP_INDEX_SIZE:0]    check_size;

  cp_index_t                      check_head_next;
  logic [`RAT_CP_INDEX_SIZE:0]    check_size_next;
  logic [`RAT_CP_INDEX_SIZE:0]    check_size_next_bk;
  logic                           check;
  logic                           checkable_next;

  logic                           mappingtable_ready;

  reg                             recover_locker;
  reg   [`RENAME_WIDTH-1:0]       retire_valid_locker;

  cp_index_t                      recover_index_locker;
  cp_index_t                      retire_index_locker[`RENAME_WIDTH-1:0];
  br_type_t                       br_type_locker[`RENAME_WIDTH-1:0];

  cp_index_t                      cp_index_next[`RENAME_WIDTH-1:0];

  // I/O for Mapping Table
  cp_index_t                                            check_idx;
  cp_index_t                                            recover_idx;
  logic [`RENAME_WIDTH-1:0]                             rd_valid;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   replace_prf;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd;
  logic [`RENAME_WIDTH-1:0]                             prev_rd_valid;

mappingtable mapping_tb(
  .clock          (clock              ),
  .reset          (reset              ),
  .check          (check              ),
  .recover        (recover            ),
  .check_idx      (check_idx          ),
  .recover_idx    (recover_idx        ),
  .rd_valid       (rd_valid           ),
  .rs1            (rs1                ),
  .rs2            (rs2                ),
  .rd             (rd                 ),
  .replace_req    (retire_valid       ),
  .replace_prf    (replace_prf        ),
  .prs1           (prs1               ),
  .prs2           (prs2               ),
  .prd            (prd                ),
  .prev_rd        (prev_rd            ),
  .prev_rd_valid  (prev_rd_valid      ),
  .allocatable    (allocatable        ),
  .ready          (ready              )
);

  always_comb begin
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
      rd_valid[i]     = op_in[i].rd_valid;
      rs1[i]          = op_in[i].rs1_arf_int_index;
      rs2[i]          = op_in[i].rs2_arf_int_index;
      rd[i]           = op_in[i].rd_arf_int_index;
      replace_prf[i]  = op_in[i].rd_prf_int_index_prev;
    end
  end

  always_comb begin
    uop_out = uop_in;
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
      uop_out[i].cp_index               = cp_index_next[i];
      uop_out[i].rs1_prf_int_index      = prs1[i];
      uop_out[i].rs2_prf_int_index      = prs2[i];
      uop_out[i].rd_prf_int_index       = prd[i];
      if (prev_rd_valid[i]) begin
        uop_out[i].rd_prf_int_index_prev  = prev_rd[i];
      end else begin
        uop_out[i].rd_prf_int_index_prev  = 0;
      end
    end
  end

  always_comb begin
    check_head_next = check_head;
    check_size_next = check_size;
    check_tail_next = 0;
    checkable_next  = 1;

    // Mis-predict
    if (recover_locker) begin
      recover_idx = recover_index_locker;
      if (recover_index_locker >= check_head_next) begin
        check_size_next = recover_index_locker - check_head_next + 1;
      end else begin
        check_size_next = `RAT_CP_SIZE + recover_index_locker - check_head_next + 1;
      end
    end

    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      // Retire PC
      if (retire_valid_locker[i]) begin
        check_head_next = retire_index_locker + 1;
        check_size_next = check_size_next - 1;
      end
    end

    check_size_next_bk = check_size_next;

    for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
      cp_index_next[i] = 0;
      // Meet Branch Prediction
      if (br_type_locker[i] != BR_X) begin
        // Have empty space for prediction
        if (check_size_next < `RAT_CP_SIZE) begin
          cp_index_next[i]  = check_head_next + check_size_next;
          check_idx         = check_head_next + check_size_next;
          check_size_next   = check_size_next + 1;
        end else begin
          checkable_next = 0;
        end
      end
    end
    if (checkable_next) begin
      check = 1;
    end else begin
      check_size_next = check_size_next_bk;
      check = 0;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      check_head <= 0;
      check_size <= 0;
    end else if (retire) begin
      check_head <= check_head_next;
      check_size <= check_size_next;
    end
    recover_index_locker  <= pc_recover.cp_index;
    recover_locker        <= recover;
    retire_valid_locker   <= retire_valid;
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
      br_type_locker[i]         <= uop_in[i].br_type;
      retire_index_locker[i]    <= pc_retire[i].cp_index;
    end
  end

endmodule
