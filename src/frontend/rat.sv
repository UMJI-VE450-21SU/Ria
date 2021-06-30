// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  RAT (Register Renaming from ARF to PRF)
// Author:  Jian Shi
// Date:    2021/05/23

`include "../common/micro_op.svh"

module rat (
  input   clock,
  input   reset,
  input   input_valid,

  input                                     recover,
  input   [`ARF_INT_SIZE-1:0]               arf_recover,
  input   [`PRF_INT_SIZE-1:0]               prf_recover,

  input   micro_op_t                        uop_recover,
  input   micro_op_t   [`COMMIT_WIDTH-1:0]  uop_retire,
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
  reg   [`PRF_INT_SIZE-1:0]       prf_recover_locker;

  micro_op_t                      uop_recover_locker;
  micro_op_t                      uop_retire_locker [`COMMIT_WIDTH-1:0];

  micro_op_t                      uop_in_locker     [`RENAME_WIDTH-1:0];

  micro_op_t                      uop_buffer        [`RENAME_WIDTH-1:0];
  micro_op_t                      uop_buffer_next   [`RENAME_WIDTH-1:0];

  logic                                                 checkable;

  // I/O for Mapping Table
  logic                                                 stall;
  logic                                                 check;
  cp_index_t                                            check_idx;
  logic [`RENAME_WIDTH-1:0]                             check_flag;
  cp_index_t                                            recover_idx;

  reg   [`RENAME_WIDTH-1:0]                             rd_valid;
  reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1;
  reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2;
  reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd;

  logic [`RENAME_WIDTH-1:0]                             retire_req;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   retire_prf;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2;
  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd;

  logic [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd;
  logic [`RENAME_WIDTH-1:0]                             prev_rd_valid;
  logic                                                 mp_allocatable;

  mapping_table mapping_tb(
    .clock          (clock                ),
    .reset          (reset                ),
    .stall          (stall                ),
    .check          (check                ),
    .recover        (recover_locker       ),
    .check_idx      (check_idx            ),
    .check_flag     (check_flag           ),
    .recover_idx    (recover_idx          ),
    .arf_recover    (arf_recover_locker   ),
    .prf_recover    (prf_recover_locker   ),
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
    end else begin
      for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
        // Meet Branch Prediction
        if (in_br_type_locker[i] != BR_X) begin
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
    end
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
        recover_locker      <= recover;
        arf_recover_locker  <= arf_recover;
        prf_recover_locker  <= prf_recover;
        for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
          uop_buffer[i] <= uop_in[i];
        end
        for (int i = 0; i < `COMMIT_WIDTH; ++i )  begin
          uop_retire_locker[i] <= uop_retire[i];
        end
        ready <= 0;
      end else begin
        ready <= 1;
      end
    end else begin
      ready <= 1;
    end
    for (int i = 0; i < `RENAME_WIDTH; ++i )  begin
      uop_out[i] <= uop_buffer_next[i];
    end
  end

endmodule
