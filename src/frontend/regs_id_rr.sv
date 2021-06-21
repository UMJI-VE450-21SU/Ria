// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Pipeline Register (ID -> RR)
// Author:  Li Shi
// Date:    2021/06/21

`include "../common/micro_op.svh"

module regs_id_rr (
  input  clock,
  input  reset,
  input  clear,
  input  stall,

  input  micro_op_t [`DECODE_WIDTH-1:0] id_uops,
  output micro_op_t [`RENAME_WIDTH-1:0] rr_uops
);

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rr_uops <= 0;
    end else if (!stall) begin
      rr_uops <= id_uops;
    end
  end

endmodule
