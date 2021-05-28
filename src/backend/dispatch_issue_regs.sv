`include "common/micro_op.svh"

module dispatch_issue_regs(
  input  clock,
  input  reset,
  input  flush,
  input  iq_int_full, iq_mem_full, iq_fp_full,

  input  micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_int,
  input  micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_mem,
  input  micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_fp,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_int_next,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_mem_next,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_fp_next
);

  wire stall;
  assign stall = iq_int_full | iq_mem_full | iq_fp_full;

  always_ff @(posedge clock) begin
    if (reset | flush | stall) begin
      uop_to_int_next <= 0;
      uop_to_mem_next <= 0;
      uop_to_fp_next  <= 0;
    end else if (stall) begin
      uop_to_int_next <= uop_to_int;
      uop_to_mem_next <= uop_to_mem;
      uop_to_fp_next  <= uop_to_fp;
  end

endmodule
