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

  // I/O for Mapping Table
  logic                                           mp_stall;
  logic [`RENAME_WIDTH-1:0]                       rd_valid;
  logic [`RENAME_WIDTH-1:0] [`ARF_INDEX_SIZE-1:0] rs1;
  logic [`RENAME_WIDTH-1:0] [`ARF_INDEX_SIZE-1:0] rs2;
  logic [`RENAME_WIDTH-1:0] [`ARF_INDEX_SIZE-1:0] rs3;
  logic [`RENAME_WIDTH-1:0] [`ARF_INDEX_SIZE-1:0] rd;
  logic [`COMMIT_WIDTH-1:0]                       pre_prf_valid;
  logic [`COMMIT_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] pre_prf;
  logic [`COMMIT_WIDTH-1:0]                       retire_valid;
  logic [`COMMIT_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] retire_prf;
  logic [`COMMIT_WIDTH-1:0] [`ARF_INDEX_SIZE-1:0] retire_arf;
  logic [`RENAME_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] prs1;
  logic [`RENAME_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] prs2;
  logic [`RENAME_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] prs3;
  logic [`RENAME_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] prd;
  logic [`RENAME_WIDTH-1:0] [`PRF_INDEX_SIZE-1:0] prev_rd;
  logic [`RENAME_WIDTH-1:0]                       prev_rd_valid;

  mapping_table mapping_table (
    .clock            (clock            ),
    .reset            (reset            ),
    .stall            (mp_stall         ),
    .recover          (recover          ),
    .rd_valid         (rd_valid         ),
    .rs1              (rs1              ),
    .rs2              (rs2              ),
    .rs3              (rs3              ),
    .rd               (rd               ),
    .pre_prf_valid    (pre_prf_valid    ),
    .pre_prf          (pre_prf          ),
    .retire_valid     (retire_valid     ),
    .retire_prf       (retire_prf       ),
    .retire_arf       (retire_arf       ),
    .prs1             (prs1             ),
    .prs2             (prs2             ),
    .prs3             (prs3             ),
    .prd              (prd              ),
    .prev_rd          (prev_rd          ),
    .prev_rd_valid    (prev_rd_valid    ),
    .allocatable      (allocatable      )
  );

  always_comb begin
    pre_prf_valid = 0;
    pre_prf       = 0;
    retire_valid  = 0;
    retire_prf    = 0;
    retire_arf    = 0;
    rd_valid      = 0;
    rs1           = 0;
    rs2           = 0;
    rs3           = 0;
    rd            = 0;
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      // Assign ports to calculate retire PRF
      if (uop_retire[i].valid) begin
        pre_prf_valid[i]  = uop_retire[i].rd_prf_index_prev_valid;
        pre_prf[i]        = uop_retire[i].rd_prf_index_prev;
        retire_valid[i]   = uop_retire[i].rd_valid;
        retire_prf[i]     = uop_retire[i].rd_prf_index;
        retire_arf[i]     = uop_retire[i].rd_arf_index;
      end
    end

    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      // When recover = 1, uop_in = 0;
      // Therefore, the circuit logic is simplified
      if (uop_in[i].valid) begin
        rd_valid[i] = uop_in[i].rd_valid;
        rs1[i]      = uop_in[i].rs1_arf_index;
        rs2[i]      = uop_in[i].rs2_arf_index;
        rs3[i]      = uop_in[i].rs3_arf_index;
        rd[i]       = uop_in[i].rd_arf_index;
      end
    end
  end

  always_comb begin
    if (recover) begin
      uop_out = 0;
    end else if (~allocatable) begin
      uop_out = 0;
    end else begin
      uop_out = uop_in;
      for (int i = 0; i < `RENAME_WIDTH; ++i) begin
        uop_out[i].rs1_prf_index            = prs1[i];
        uop_out[i].rs2_prf_index            = prs2[i];
        uop_out[i].rs3_prf_index            = prs3[i];
        uop_out[i].rd_prf_index             = prd[i];
        uop_out[i].rd_prf_index_prev        = prev_rd[i];
        uop_out[i].rd_prf_index_prev_valid  = prev_rd_valid[i];
      end
    end
  end

endmodule
