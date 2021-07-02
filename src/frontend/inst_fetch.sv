// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Instruction Fetch
// Author:  Yiqiu Sun
// Date:    2021/06/01

`include "src/common/micro_op.svh"

module inst_fetch (
  // ======= basic ===========================
  input                                 clock,
  input                                 reset,
  input                                 stall,              // stall is effective in the next clock cycle
  // ======= branch predictor related ========
  input        [31:0]                   pc_predicted,
  input                                 branch_taken,
  input        [31:0]                   branch_pc,
  // ======= cache related ===================
  input        [31:0]                   icache2core_data,
  input                                 icache2core_data_valid,
  output logic [31:0]                   core2icache_addr,   // one addr is enough
  // ======= inst buffer related =============
  output fb_entry_t [`FETCH_WIDTH-1:0]  insts_out,
  output logic                          insts_out_valid
);

  reg [31:0]  pc_reg;
  logic       pc_enable;

  assign pc_enable = ~stall & icache2core_data_valid;

  always_ff @(posedge clock) begin
    if (reset)
      pc_reg <= 0;
    else if (branch_taken)
      pc_reg <= branch_pc;
    else if (pc_enable)
      pc_reg <= pc_predicted;
  end

  assign core2icache_addr = pc_reg;
  assign insts_out_valid = icache2core_data_valid & ~stall;

  generate
    for (genvar i = 0; i < `FETCH_WIDTH; i++) begin
      assign insts_out[i].inst = icache2core_data[(i+1)*32-1:i*32];
      assign insts_out[i].pc   = pc_reg + i * 4;
    end
  endgenerate

endmodule
