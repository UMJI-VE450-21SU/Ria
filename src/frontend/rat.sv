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
  logic                                               mp_stall;
  logic [`RENAME_WIDTH-1:0]                           rd_int_valid;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] rs1_int;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] rs2_int;
  logic [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] rd;
  logic [`COMMIT_WIDTH-1:0]                           pre_prf_i_valid;
  logic [`COMMIT_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] pre_prf_i;
  logic [`COMMIT_WIDTH-1:0]                           retire_int_valid;
  logic [`COMMIT_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] retire_prf_int;
  logic [`COMMIT_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] retire_arf_int;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prs1_int;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prs2_int;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prd_int;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prev_rd;
  logic [`RENAME_WIDTH-1:0]                           prev_rd_int_valid;

  mapping_table mapping_table (
    .clock              (clock              ),
    .reset              (reset              ),
    .stall              (mp_stall           ),
    .recover            (recover            ),
    .rd_int_valid       (rd_int_valid       ),
    .rs1_int            (rs1_int            ),
    .rs2_int            (rs2_int            ),
    .rd                 (rd                 ),
    .pre_prf_i_valid    (pre_prf_i_valid    ),
    .pre_prf_i          (pre_prf_i          ),
    .retire_int_valid   (retire_int_valid   ),
    .retire_prf_int     (retire_prf_int     ),
    .retire_arf_int     (retire_arf_int     ),
    .prs1_int           (prs1_int           ),
    .prs2_int           (prs2_int           ),
    .prd_int            (prd_int            ),
    .prev_rd            (prev_rd            ),
    .prev_rd_int_valid  (prev_rd_int_valid  ),
    .allocatable        (allocatable        )
  );

  always_comb begin
    pre_prf_i_valid = 0;
    pre_prf_i       = 0;
    retire_int_valid    = 0;
    retire_prf_int      = 0;
    retire_arf_int      = 0;
    rd_int_valid    = 0;
    rs1_int             = 0;
    rs2             = 0;
    rd              = 0;
    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      // Assign ports to calculate retire PRF
      if (uop_retire[i].valid) begin
        pre_prf_i_valid[i]  = uop_retire[i].rd_prf_int_index_prev_valid;
        pre_prf_i[i]        = uop_retire[i].rd_prf_int_index_prev;
        retire_int_valid[i] = uop_retire[i].rd_int_valid;
        retire_prf_int[i]   = uop_retire[i].rd_prf_int_index;
        retire_arf_int[i]   = uop_retire[i].rd_arf_int_index;
      end
    end

    for (int i = 0; i < `RENAME_WIDTH; ++i) begin
      // When recover = 1, uop_in = 0;
      // Therefore, the circuit logic is simplified
      if (uop_in[i].valid) begin
        rd_int_valid[i] = uop_in[i].rd_int_valid;
        rs1_int[i]      = uop_in[i].rs1_arf_int_index;
        rs2_int[i]      = uop_in[i].rs2_arf_int_index;
        rd[i]       = uop_in[i].rd_arf_int_index;
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
        uop_out[i].rs1_prf_int_index            = prs1_int[i];
        uop_out[i].rs2_prf_int_index            = prs2_int[i];
        uop_out[i].rd_prf_int_index             = prd_int[i];
        uop_out[i].rd_prf_int_index_prev        = prev_rd[i];
        uop_out[i].rd_prf_int_index_prev_valid  = prev_rd_int_valid[i];
      end
    end
  end

endmodule
