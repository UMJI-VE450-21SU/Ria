// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Mapping Table (Mapping Relation between PRF & ARF; SRAM-Based RAT)
// Author:  Jian Shi
// Date:    2021/06/05

`include "src/common/micro_op.svh"

module mapping_table (
  input         clock,
  input         reset,
  input         stall,
  input         recover,

  input         [`RENAME_WIDTH-1:0]                           rd_int_valid,

  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] rs1_int,
  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] rs2_int,
  input         [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] rd,

  input         [`COMMIT_WIDTH-1:0]                           pre_prf_i_valid,
  input         [`COMMIT_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] pre_prf_i,

  input         [`COMMIT_WIDTH-1:0]                           retire_int_valid,
  input         [`COMMIT_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] retire_prf_int,
  input         [`COMMIT_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0] retire_arf_int,

  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prs1_int,
  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prs2_int,
  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prd_int,

  output logic  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prev_rd,
  output logic  [`RENAME_WIDTH-1:0]                           prev_rd_int_valid,

  output logic                                                allocatable
);

  // I/O for Mapping Table
  reg   [`PRF_INT_INDEX_SIZE-1:0]                     mp_tb       [`ARF_INT_SIZE-1:0];
  logic [`PRF_INT_INDEX_SIZE-1:0]                     mp_tb_next  [`ARF_INT_SIZE-1:0];

  reg   [`PRF_INT_INDEX_SIZE-1:0]                     r_rat       [`ARF_INT_SIZE-1:0];
  logic [`PRF_INT_INDEX_SIZE-1:0]                     r_rat_next  [`ARF_INT_SIZE-1:0];

  // I/O for Free List
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0] prf_out;

  // ARF Valid
  reg   [`ARF_INT_SIZE-1:0]                           arf_valid;
  logic [`ARF_INT_SIZE-1:0]                           arf_valid_next;
  reg   [`ARF_INT_SIZE-1:0]                           arf_recover;
  logic [`ARF_INT_SIZE-1:0]                           arf_recover_next;

  free_list free_list (
    .clock            (clock            ),
    .reset            (reset            ),
    .stall            (stall            ),
    .recover          (recover          ),
    .pre_prf_i_valid  (pre_prf_i_valid  ),
    .pre_prf_i        (pre_prf_i        ),
    .retire_int_valid (retire_int_valid ),
    .retire_prf_int   (retire_prf_int   ),
    .prf_req          (rd_int_valid     ),
    .prf_out          (prf_out          ),
    .allocatable      (allocatable      )
  );

  always_comb begin
    // Prepare input for Free List
    arf_valid_next    = arf_valid;
    arf_recover_next  = arf_recover;
    prev_rd           = 0;
    prev_rd_int_valid = 0;
    for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
      mp_tb_next[i] = mp_tb[i];
      r_rat_next[i] = r_rat[i];
    end
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1) begin
      prd_int[i]  = 0;
      prs1_int[i] = 0;
      prs2_int[i] = 0;
    end

    for (int i = 0; i < `COMMIT_WIDTH; ++i) begin
      // Retire PRF
      if (retire_int_valid[i]) begin
        arf_recover_next[retire_arf_int[i]] = 1;
        r_rat_next[retire_arf_int[i]]       = retire_prf_int[i];
      end
    end

    if (allocatable) begin
      for (int i = 0; i < `RENAME_WIDTH; i = i + 1) begin
        prd_int[i]  = 0;
        prs1_int[i] = (rs1_int[i] == 0) ? 0 : mp_tb_next[rs1_int[i]];
        prs2_int[i] = (rs2_int[i] == 0) ? 0 : mp_tb_next[rs2_int[i]];
        if (rd_int_valid[i]) begin
          // WAW: Return Previous PRF
          prev_rd[i] = mp_tb_next[rd[i]];
          if (arf_valid_next[rd[i]]) begin
            prev_rd_int_valid[i] = 1;
          end
          prd_int[i]                = prf_out[i];
          mp_tb_next[rd[i]]     = prf_out[i];
          arf_valid_next[rd[i]] = 1;
        end
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mp_tb[i] <= 0;
        r_rat[i] <= 0;
      end
      arf_valid   <= 1;
      arf_recover <= 1;
    end else if (recover) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mp_tb[i] <= r_rat_next[i];
        r_rat[i] <= r_rat_next[i];
      end
      arf_valid   <= arf_recover_next;
      arf_recover <= arf_recover_next;
    end else if (!stall) begin
      for (int i = 0; i < `ARF_INT_SIZE; i = i + 1 )  begin
        mp_tb[i] <= mp_tb_next[i];
        r_rat[i] <= r_rat_next[i];
      end
      arf_valid   <= arf_valid_next;
      arf_recover <= arf_recover_next;
    end
  end

endmodule
