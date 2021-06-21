// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Pipeline Register (IS -> RF)
// Author:  Li Shi
// Date:    2021/06/21

`include "../common/micro_op.svh"

module regs_is_rf (
  input  clock,
  input  reset,
  input  clear,
  input  stall,

  input  micro_op_t [`ISSUE_WIDTH_INT-1:0]  is_uop_int,
  input  micro_op_t [`ISSUE_WIDTH_MEM-1:0]  is_uop_mem,
  // input  micro_op_t [`ISSUE_WIDTH_FP -1:0]  is_uop_fp,
  output micro_op_t [`ISSUE_WIDTH_INT-1:0]  rf_uop_int,
  output micro_op_t [`ISSUE_WIDTH_MEM-1:0]  rf_uop_mem
  // output micro_op_t [`ISSUE_WIDTH_FP -1:0]  rf_uop_fp
);

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rf_uop_int <= 0;
      rf_uop_mem <= 0;
      // rf_uop_fp  <= 0;
    end else if (!stall) begin
      rf_uop_int <= is_uop_int;
      rf_uop_mem <= is_uop_mem;
      // rf_uop_fp  <= is_uop_fp;
    end
  end

endmodule
