// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  RAT (Register Renaming from ARF to PRF)
// Author:  Jian Shi
// Date:    2021/05/23

`include "src/common/micro_op.svh"

module rat (
  input   clock,
  input   reset,

  input                                     recover,
  input   micro_op_t                        uop_recover,

  input   micro_op_t  [`COMMIT_WIDTH-1:0]   uop_retire,
  input   micro_op_t  [`RENAME_WIDTH-1:0]   uop_in,

  output  micro_op_t  [`RENAME_WIDTH-1:0]   uop_out,

  output  reg                               allocatable
);

  // Info for check point table
  cp_index_t                              check_head;
  reg           [`RAT_CP_INDEX_SIZE:0]    check_size;

  cp_index_t                              check_head_next;
  logic         [`RAT_CP_INDEX_SIZE:0]    check_size_next;

  micro_op_t    uop_buffer                [`RENAME_WIDTH-1:0];
  micro_op_t    uop_buffer_next           [`RENAME_WIDTH-1:0];

  logic                                                 checkable;

  // I/O for Mapping Table
  logic                                                 check;
  cp_index_t                                            check_idx;
  logic [`RENAME_WIDTH-1:0]                             check_flag;
  cp_index_t                                            recover_idx;

  logic [`RENAME_WIDTH-1:0]                             rd_valid;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd;

  logic [`COMMIT_WIDTH-1:0]                             pre_prf_valid;
  logic [`COMMIT_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   pre_prf;
  logic [`COMMIT_WIDTH-1:0]                             retire_prf_valid;
  logic [`COMMIT_WIDTH-1:0][`PRF_INT_INDEX_SIZE-1:0]    retire_prf;
  logic [`COMMIT_WIDTH-1:0][`ARF_INT_INDEX_SIZE-1:0]    retire_arf;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd;
  logic [`RENAME_WIDTH-1:0]                             prev_rd_valid;
  logic                                                 mp_stall;
  logic                                                 mp_allocatable;

  mapping_table mapping_table (
    .clock            (clock            ),
    .reset            (reset            ),
    .stall            (mp_stall         ),
    .check            (check            ),
    .recover          (recover          ),
    .check_idx        (check_idx        ),
    .check_flag       (check_flag       ),
    .recover_idx      (recover_idx      ),
    .rd_valid         (rd_valid         ),
    .rs1              (rs1              ),
    .rs2              (rs2              ),
    .rd               (rd               ),
    .pre_prf_valid    (pre_prf_valid    ),
    .pre_prf          (pre_prf          ),
    .retire_prf_valid (retire_prf_valid ),
    .retire_prf       (retire_prf       ),
    .retire_arf       (retire_arf       ),
    .prs1             (prs1             ),
    .prs2             (prs2             ),
    .prd              (prd              ),
    .prev_rd          (prev_rd          ),
    .prev_rd_valid    (prev_rd_valid    ),
    .allocatable      (mp_allocatable   )
  );

  assign mp_stall = ~checkable;

  assign allocatable = mp_allocatable & checkable;

  always_comb begin
    pre_prf_valid     = 0;
    pre_prf           = 0;
    retire_prf_valid  = 0;
    retire_prf        = 0;
    retire_arf        = 0;
    check_head_next   = check_head;
    check_size_next   = check_size;
    check             = 0;
    checkable         = 1;
    check_idx         = 0;
    check_flag        = 0;
    rd_valid          = 0;
    rs1               = 0;
    rs2               = 0;
    rd                = 0;
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      if (uop_retire[i].valid) begin
        pre_prf_valid[i]    = uop_retire[i].rd_prf_int_index_prev_valid;
        pre_prf[i]          = uop_retire[i].rd_prf_int_index_prev;
        retire_prf_valid[i] = uop_retire[i].rd_valid;
        retire_prf[i]       = uop_retire[i].rd_prf_int_index;
        retire_arf[i]       = uop_retire[i].rd_arf_int_index;
        if (uop_retire[i].br_type != BR_X & uop_retire[i].br_type != BR_JAL) begin
          check_head_next += 1;
          check_size_next -= 1;
        end
      end
    end
    if (recover) begin
      if (recover_idx >= check_head_next) begin
        check_size_next = recover_idx - check_head_next + 1;
      end else begin
        check_size_next = `RAT_CP_SIZE + recover_idx - check_head_next + 1;
      end
    end else begin
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        if (uop_in[i].valid) begin
          // Meet Branch Prediction
          if (uop_in[i].br_type != BR_X) begin
            // Have empty space for prediction
            if (check_size_next < `RAT_CP_SIZE) begin
              check         = 1;
              check_idx     = check_head_next + check_size_next;
              check_flag[i] = 1;
            end else begin
              checkable = 0;
            end
          end
          rd_valid[i] = uop_in[i].rd_valid;
          rs1[i]      = uop_in[i].rs1_arf_int_index;
          rs2[i]      = uop_in[i].rs2_arf_int_index;
          rd[i]       = uop_in[i].rd_arf_int_index;
        end
      end
    end
  end

  always_comb begin
    if (recover | (~allocatable)) begin
      uop_out = 0;
    end else begin
      uop_out = uop_in;
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        uop_out[i].rs1_prf_int_index            = prs1[i];
        uop_out[i].rs2_prf_int_index            = prs2[i];
        uop_out[i].rd_prf_int_index             = prd[i];
        uop_out[i].rd_prf_int_index_prev        = prev_rd[i];
        uop_out[i].rd_prf_int_index_prev_valid  = prev_rd_valid[i];
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      check_head  <= 0;
      check_size  <= 0;
    end else if (recover) begin
      check_head <= check_head_next;
      check_size <= check_size_next;
    end else if (allocatable) begin
      // allocatable = 1;
      check_head <= check_head_next;
      check_size <= check_size_next;
    end
  end

endmodule
