// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Pipeline Register (FB -> ID)
// Author:  Li Shi
// Date:    2021/06/21

`include "../common/micro_op.svh"

module regs_fb_id (
  input  clock,
  input  reset,
  input  clear,
  input  stall,

  input  fb_entry_t [`FECTH_WIDTH-1:0]  fb_insts,
  input             [`FECTH_WIDTH-1:0]  fb_insts_valid,
  output fb_entry_t [`FECTH_WIDTH-1:0]  id_insts,
  output logic      [`FECTH_WIDTH-1:0]  id_insts_valid
);

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      id_insts        <= 0;
      id_insts_valid  <= 0;
    end else if (!stall) begin
      id_insts        <= fb_insts;
      id_insts_valid  <= fb_insts_valid;
    end
  end

endmodule
