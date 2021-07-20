// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Instruction Fetch
// Author:  Yiqiu Sun
// Date:    2021/06/01

`include "src/common/micro_op.svh"

module inst_fetch (
  // ======= basic ===========================
  input                                     clock,
  input                                     reset,
  input                                     stall,              // stall is effective in the next clock cycle
  // ======= branch predictor related ========
  input   micro_op_t  [`COMMIT_WIDTH-1:0]   uop_retire,
  // ======= cache related ===================
  input        [127:0]                      icache2core_data,
  input                                     icache2core_data_valid,
  output logic [31:0]                       core2icache_addr,   // one addr is enough
  // ======= inst buffer related =============
  output fb_entry_t [`FETCH_WIDTH-1:0]      insts_out,
  output logic                              insts_out_valid
);

  /* todo: Debug purpose - Add hash to PC */
  reg   [15:0] counter;
  always_ff @(posedge clock) begin
    if (reset)
      counter <= 0;
    else
      counter <= counter + 1;
  end
  /*       Debug purpose - Add hash to PC */

  reg   [31:0] pc;
  wire  [31:0] pc_aligned;
  wire  [1:0]  pc_offset;
  logic        pc_enable;
  logic [31:0] next_PC;

  logic [`FETCH_WIDTH-1:0]  is_branch,is_valid;
  logic                     mispredict;
  logic [`FETCH_WIDTH-1:0]  predictions;

  branch_pred br_pred(
    .clock      (clock),
    .reset      (reset),
    .PC         (pc),
    .is_branch  (is_branch),
    .is_valid   (is_valid),
    .uop_retire (uop_retire),
    .mispredict (mispredict),
    .next_PC    (next_PC),
    .predictions(predictions)
  );

  assign pc_enable = ~reset & ~stall;
  assign pc_aligned = {pc[31:4], {4'b0000}};
  assign pc_offset = pc[3:2];

  assign insts_out_valid = (pc_enable | mispredict) & icache2core_data_valid;

  always_ff @(posedge clock) begin
    if (reset)
      pc <= 0;
    else if (insts_out_valid)
      pc <= {16'b0, next_PC[15:0]};  // todo: Debug purpose
  end

  assign core2icache_addr = pc_aligned;

  generate
    for (genvar i = 0; i < `FETCH_WIDTH; i++) begin
      assign insts_out[i].inst        = icache2core_data[(i+1)*32-1:i*32];
      // assign insts_out[i].pc   = pc_aligned + i * 4;
      assign insts_out[i].pc          = pc_aligned + i * 4 + (counter << 16);  // todo: Debug purpose - Add hash to PC
      assign is_branch[i]             = (icache2core_data[(i+1)*32-26:i*32] == `RV32_OP_BRANCH) || (icache2core_data[(i+1)*32-26:i*32] == `RV32_OP_JALR) || (icache2core_data[(i+1)*32-26:i*32] == `RV32_OP_JAL);
      assign insts_out[i].pred_taken  = predictions[i];
      assign insts_out[i].pred_addr   = predictions[i]? next_PC:0;
    end
  endgenerate

  always_comb begin
    insts_out[0].valid = insts_out_valid && (pc_offset == 2'b00);
    insts_out[1].valid = insts_out_valid && ((insts_out[0].valid && !predictions[0]) || pc_offset == 2'b01);
    insts_out[2].valid = insts_out_valid && ((insts_out[1].valid && !predictions[1]) || pc_offset == 2'b10);
    insts_out[3].valid = insts_out_valid && ((insts_out[2].valid && !predictions[2]) || pc_offset == 2'b11);
  end

endmodule
