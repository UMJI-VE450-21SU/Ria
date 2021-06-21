//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/05
// Contributor: Jian Shi
// Reviewer: 
// Module Name: mappingtable
// Target Devices: mapping table
// Description: 
// Record Mapping Relation between PRF & ARF; SRAM-Based RAT;
// Dependencies: 
// src/common/micro_op.svh, src/frontend/freelist.sv, src/frontend/checkpoint.sv
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module mappingtable (
  input         clock,
  input         reset,
  input         stall,

  input         check,
  input         recover,

  input         cp_index_t                                      check_idx,
  input         [`RENAME_WIDTH-1:0]                             check_flag,
  input         cp_index_t                                      recover_idx,
  input         [`ARF_INT_SIZE-1:0]                             arf_recover,

  input         [`RENAME_WIDTH-1:0]                             rd_valid,

  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1,
  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2,
  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd,

  input         [`RENAME_WIDTH-1:0]                             replace_req,
  input         [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   replace_prf,

  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1,
  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2,
  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd,

  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd,
  output logic  [`RENAME_WIDTH-1:0]                             prev_rd_valid,

  output logic                                                  allocatable
);

  // I/O for Mapping Table
  reg   [`PRF_INT_INDEX_SIZE-1:0]                       mapping_tb      [`ARF_INT_SIZE-1:0];
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb_cp_in;
  logic [`PRF_INT_INDEX_SIZE-1:0]                       mapping_tb_next [`ARF_INT_SIZE-1:0];
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb_cp;

  // I/O for Free List
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out;

  // ARF Valid
  reg   [`ARF_INT_SIZE-1:0]                             arf_valid;
  logic [`ARF_INT_SIZE-1:0]                             arf_valid_next;

checkpoint_int int_checkpoint(
  .clock              (clock            ),
  .reset              (reset            ),
  .check              (check            ),
  .check_idx          (check_idx        ),
  .recover_idx        (recover_idx      ),
  .checkpoint_in      (mapping_tb_cp_in ),
  .checkpoint_out     (mapping_tb_cp    )
);

freelist_int  int_freelist(
  .clock              (clock            ),
  .reset              (reset            ),
  .stall              (stall            ),
  .recover            (recover          ),
  .recover_fl         (recover_fl       ),
  .prf_replace_valid  (replace_req      ),
  .prf_replace        (replace_prf      ),
  .prf_req            (rd_valid         ),
  .prf_out            (prf_out          ),
  .allocatable        (allocatable      )
);

  always_comb begin
    // Prepare input for Free List
    arf_valid_next    = arf_valid;
    prev_rd           = 0;
    prev_rd_valid     = 0;
    mapping_tb_cp_in  = 0;
    for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
      mapping_tb_next[i]  = mapping_tb[i];
    end
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1) begin
      prd[i]              = 0;
      if (check_flag[i]) begin
        for (int j = 0; j < `ARF_INT_SIZE; j = j + 1 ) begin
          mapping_tb_cp_in[j] = mapping_tb_next[j];
        end
      end
      if (rd_valid[i]) begin
        // WAW: Return Previous PRF
        prev_rd[i] = mapping_tb_next[rd[i]];
        if (arf_valid_next[prev_rd[i]]) begin
          prev_rd_valid[i] = 1;
        end
        mapping_tb_next[rd[i]]      = prf_out[i];
        prd[i]                      = prf_out[i];
        arf_valid_next[prf_out[i]]  = 1;
      end
      prs1[i] = mapping_tb_next[rs1[i]];
      prs2[i] = mapping_tb_next[rs2[i]];
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= 0;
      end
      arf_valid <= 1;
    end else if (recover) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= mapping_tb_cp[i];
      end
      arf_valid <= arf_recover;
    end else if (!stall) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= mapping_tb_next[i];
      end
      arf_valid <= arf_valid_next;
    end
  end

endmodule
