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

  input         check,
  input         recover,
  input         pause,

  input         [`RAT_CP_INDEX_SIZE-1:0]                        check_idx,
  input         [`RAT_CP_INDEX_SIZE-1:0]                        recover_idx,

  input         [`RENAME_WIDTH-1:0]                             rd_valid,

  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1,
  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2,
  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd,

  input         [`RENAME_WIDTH-1:0]                             retire_req,
  input         [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   retire_prf,

  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1,
  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2,
  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd,

  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd,
  output logic  [`RENAME_WIDTH-1:0]                             prev_rd_valid,

  output logic                                                  allocatable
);

  // I/O for Mapping Table
  reg   [`PRF_INT_INDEX_SIZE-1:0]                       mapping_tb[`ARF_INT_SIZE-1:0];
  logic [`PRF_INT_INDEX_SIZE-1:0]                       mapping_tb_next[`ARF_INT_SIZE-1:0];
  logic [`ARF_INT_SIZE-1:0] [`PRF_INT_INDEX_SIZE-1:0]   mapping_tb_cp;

  reg   [`PRF_INT_SIZE-1:0]                             tb_valid;
  logic [`PRF_INT_SIZE-1:0]                             tb_valid_next;
  logic [`PRF_INT_SIZE-1:0]                             tb_valid_cp;

  // I/O for Free List
  logic [`RENAME_WIDTH-1:0]                             prf_replace_valid;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_replace;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prf_out;

checkpoint_int int_checkpoint(
  .clock              (clock            ),
  .reset              (reset            ),
  .check              (check            ),
  .check_idx          (check_idx        ),
  .recover_idx        (recover_idx      ),
  .checkpoint_in      (mapping_tb       ),
  .checkpoint_out     (mapping_tb_cp    ),
  .valid_in           (tb_valid         ),
  .valid_out          (tb_valid_cp      )
);

freelist_int  int_freelist(
  .clock              (clock            ),
  .reset              (reset            ),
  .check              (check            ),
  .recover            (recover          ),
  .check_idx          (check_idx        ),
  .recover_idx        (recover_idx      ),
  .prf_replace_valid  (prf_replace_valid),
  .prf_replace        (prf_replace      ),
  .prf_req            (rd_valid         ),
  .prf_out            (prf_out          ),
  .allocatable        (allocatable      )
);

  always_comb begin
    // Prepare input for Free List
    prf_replace_valid   = retire_req;
    prf_replace         = retire_prf;
    tb_valid_next       = tb_valid;
    prev_rd             = 0;
    prev_rd_valid       = 0;
    for (int i = 0; i < `PRF_INT_SIZE; i = i + 1 )  begin
      mapping_tb_next[i]   = mapping_tb[i];
    end
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1) begin
      for (int j = 0; j < i; j = j + 1 )  begin
        if (rd_valid[i]) begin
          // WAW
          if (tb_valid_next[rd[i]]) begin
            prev_rd[i]             = mapping_tb_next[rd[i]];
            prev_rd_valid[i]       = 1;
          end
          mapping_tb_next[rd[i]]        = prf_out[i];
          prd[i]                        = prf_out[i];
          tb_valid_next[rd[i]]          = 1;
        end
        prs1[i] = mapping_tb_next[rs1[i]];
        prs2[i] = mapping_tb_next[rs2[i]];
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= 0;
      end
      tb_valid <= 0;
    end
    else if (recover) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= mapping_tb_cp[i];
      end
      tb_valid <= tb_valid_cp;
    end
    else begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mapping_tb[i] <= mapping_tb_next[i];
      end
      tb_valid <= tb_valid_next;
    end
  end

endmodule
