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
  input                                 branch_taken,
  input        [31:0]                   branch_pc,
  // ======= cache related ===================
  input        [127:0]                  icache2core_data,
  input                                 icache2core_data_valid,
  output logic [31:0]                   core2icache_addr,   // one addr is enough
  // ======= inst buffer related =============
  output fb_entry_t [`FETCH_WIDTH-1:0]  insts_out,
  output logic      [`FETCH_WIDTH-1:0]  insts_out_valid
);

  reg   [31:0] pc;
  wire  [31:0] pc_aligned;
  wire  [1:0]  pc_offset;
  logic        pc_enable;
  logic [31:0] pc_predicted;
  logic [`FETCH_WIDTH-1:0] is_jal;

  assign pc_enable = ~reset & ~stall & icache2core_data_valid;
  assign pc_aligned = {pc[31:4], {4'b0000}};
  assign pc_offset = pc[3:2];

  always_ff @(posedge clock) begin
    if (reset)
      pc <= 0;
    else if (branch_taken)
      pc <= branch_pc;
    else if (pc_enable)
      pc <= pc_predicted;
    $display("pc=%h, pc_predicted=%h", pc, pc_predicted);
  end

  assign core2icache_addr = pc_aligned;

  generate
    for (genvar i = 0; i < `FETCH_WIDTH; i++) begin
      assign insts_out[i].inst = icache2core_data[(i+1)*32-1:i*32];
      assign insts_out[i].pc   = pc_aligned + i * 4;
      assign is_jal[i]         = (icache2core_data[(i+1)*32-26:i*32] == `RV32_OP_JAL);
    end
  endgenerate

  always_comb begin
    insts_out_valid[0] = (pc_offset == 2'b00);
    insts_out_valid[1] = ((insts_out_valid[0] && !is_jal[0]) || pc_offset == 2'b01);
    insts_out_valid[2] = ((insts_out_valid[1] && !is_jal[1]) || pc_offset == 2'b10);
    insts_out_valid[3] = ((insts_out_valid[2] && !is_jal[2]) || pc_offset == 2'b11);
  end

  // Branch predictor

  always_comb begin
    pc_predicted = pc + 16;
    for (integer i = 0; i < `FETCH_WIDTH; i++) begin
      if (insts_out_valid[i] && is_jal[i]) begin
        pc_predicted = insts_out[i].pc + `RV32_signext_J_Imm(insts_out[i].inst);
      end
    end
  end

endmodule
