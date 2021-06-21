// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Pipeline Register (IF -> FB)
// Author:  Li Shi
// Date:    2021/06/21

`include "../common/micro_op.svh"

module regs_if_fb (
  input  clock,
  input  reset,
  input  clear,
  input  stall,

  input  fb_entry_t [`FECTH_WIDTH-1:0]  if_insts,
  input                                 if_insts_valid,
  output fb_entry_t [`FECTH_WIDTH-1:0]  fb_insts,
  output logic                          fb_insts_valid
);

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      fb_insts        <= 0;
      fb_insts_valid  <= 0;
    end else if (!stall) begin
      fb_insts        <= if_insts;
      fb_insts_valid  <= if_insts_valid;
    end
  end

endmodule
