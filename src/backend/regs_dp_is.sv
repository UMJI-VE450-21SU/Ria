// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Pipeline Register (DP -> IS)
// Author:  Li Shi
// Date:    2021/06/21

`include "../common/micro_op.svh"

module regs_dp_is (
  input  clock,
  input  reset,
  input  clear,
  input  stall,

  input  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_int,
  input  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_mem,
  input  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_fp,
  output micro_op_t [`DISPATCH_WIDTH-1:0] is_uop_to_int,
  output micro_op_t [`DISPATCH_WIDTH-1:0] is_uop_to_mem,
  output micro_op_t [`DISPATCH_WIDTH-1:0] is_uop_to_fp
);

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      is_uop_to_int <= 0;
      is_uop_to_mem <= 0;
      is_uop_to_fp  <= 0;
    end else if (!stall) begin
      is_uop_to_int <= dp_uop_to_int;
      is_uop_to_mem <= dp_uop_to_mem;
      is_uop_to_fp  <= dp_uop_to_fp;
    end
  end

endmodule
