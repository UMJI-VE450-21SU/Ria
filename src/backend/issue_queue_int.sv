// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Issue Queue for Integer
// Author:  Li Shi
// Date:    2021/05/28

`include "src/common/micro_op.svh"

`timescale 1ns / 1ps
module issue_slot_int (
  input             clock,
  input             reset,
  input             clear,

  // ctb = common tag bus
  input  [`ISSUE_WIDTH_INT-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index,
  input  [`ISSUE_WIDTH_INT-1:0]                           ctb_valid,

  input             load,

  input  micro_op_t uop_in,
  output micro_op_t uop,

  output            ready,
  output            free
);

  wire [`ISSUE_WIDTH_INT-1:0] rs1_index_match_ctb;
  wire [`ISSUE_WIDTH_INT-1:0] rs2_index_match_ctb;
  wire [`ISSUE_WIDTH_INT-1:0] rs1_from_ctb;
  wire [`ISSUE_WIDTH_INT-1:0] rs2_from_ctb;
  wire                        rs1_from_ctb_valid;
  wire                        rs2_from_ctb_valid;

  logic rs1_ready;
  logic rs2_ready;

  generate
    for (genvar i = 0; i < `ISSUE_WIDTH_INT; i++) begin
      assign rs1_index_match_ctb[i] = (uop_in.rs1_prf_int_index == ctb_prf_int_index[i]);
      assign rs2_index_match_ctb[i] = (uop_in.rs2_prf_int_index == ctb_prf_int_index[i]);
      assign rs1_from_ctb[i]         = (~rs1_ready & ctb_valid[i] & rs1_index_match_ctb[i]);
      assign rs2_from_ctb[i]        = (~rs2_ready & ctb_valid[i] & rs2_index_match_ctb[i]);
    end
  endgenerate

  assign rs1_from_ctb_valid = |rs1_from_ctb;
  assign rs2_from_ctb_valid = |rs2_from_ctb;

  always_ff @ (posedge clock) begin
    if (reset | clear) begin
      uop <= 0;
    end else if (load & uop_in.valid) begin
      uop <= uop_in;
    end
  end

  always_ff @ (posedge clock) begin
    if (reset | clear) begin
      rs1_ready <= 1'b0;
      rs2_ready <= 1'b0;
    end else if (load & uop_in.valid) begin
      rs1_ready <= (uop_in.rs1_source == RS_FROM_RF) ? (uop_in.rs1_from_ctb ? rs1_from_ctb_valid : 1'b1) : 1'b1;
      rs2_ready <= (uop_in.rs2_source == RS_FROM_RF) ? (uop_in.rs2_from_ctb ? rs2_from_ctb_valid : 1'b1) : 1'b1;
    end else begin
      rs1_ready <= (uop.rs1_source == RS_FROM_RF) ? (uop.rs1_from_ctb ? rs1_from_ctb_valid : 1'b1) : 1'b1;
      rs2_ready <= (uop.rs2_source == RS_FROM_RF) ? (uop.rs2_from_ctb ? rs2_from_ctb_valid : 1'b1) : 1'b1;
    end
  end

  assign free = uop.valid;
  assign ready = rs1_ready & rs2_ready;

endmodule


module issue_queue_int_selector (ready, sel, sel_valid);

  parameter REQS  = `DISPATCH_WIDTH;
  parameter WIDTH = `IQ_INT_SIZE;

  input      [WIDTH-1:0]                    ready;
  output reg [REQS-1:0] [$clog2(WIDTH)-1:0] sel;
  output reg [REQS-1:0]                     sel_valid;

  logic [REQS-1:0] [WIDTH-1:0] readys;

  assign readys[0] = ready;

  generate
    for (genvar i = 1; i < REQS; i++) begin
      assign readys[i] = readys[i-1] & ~(sel_valid[i-1] << sel[i-1]);
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < REQS; i++) begin
      sel_valid[i] = 1;
      casez (readys[i])
        16'b???????????????1: sel[i] = 4'b0000;
        16'b??????????????10: sel[i] = 4'b0001;
        16'b?????????????100: sel[i] = 4'b0010;
        16'b????????????1000: sel[i] = 4'b0011;
        16'b???????????10000: sel[i] = 4'b0100;
        16'b??????????100000: sel[i] = 4'b0101;
        16'b?????????1000000: sel[i] = 4'b0110;
        16'b????????10000000: sel[i] = 4'b0111;
        16'b???????100000000: sel[i] = 4'b1000;
        16'b??????1000000000: sel[i] = 4'b1001;
        16'b?????10000000000: sel[i] = 4'b1010;
        16'b????100000000000: sel[i] = 4'b1011;
        16'b???1000000000000: sel[i] = 4'b1100;
        16'b??10000000000000: sel[i] = 4'b1101;
        16'b?100000000000000: sel[i] = 4'b1110;
        16'b1000000000000000: sel[i] = 4'b1111;
        default: begin
          sel[i] = 4'b0000;
          sel_valid[i] = 0;
        end
      endcase
    end
  end

endmodule


// Input:  From dispatch,    width = DISPATCH_WIDTH  = 4
// Output: To PRF & Ex Unit, width = ISSUE_WIDTH_INT = 3
`timescale 1ns / 1ps
module issue_queue_int (
  input  clock,
  input  reset,

  // ctb = common tag bus
  input  [`ISSUE_WIDTH_INT-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index,
  input  [`ISSUE_WIDTH_INT-1:0]             ctb_valid,

  input  [`ISSUE_WIDTH_INT-1:0]             ex_busy,

  input  micro_op_t [`DISPATCH_WIDTH-1:0]   uop_in,
  output micro_op_t [`ISSUE_WIDTH_INT-1:0]  uop_out,

  output iq_int_full
);

  logic [$clog2(`IQ_INT_SIZE):0] uop_in_count, uop_out_count;
  logic [$clog2(`IQ_INT_SIZE):0] free_count;
  reg   [$clog2(`IQ_INT_SIZE):0] free_count_reg;

  logic [`DISPATCH_WIDTH-1:0] [$clog2(`IQ_INT_SIZE)-1:0] input_select;
  logic [`DISPATCH_WIDTH-1:0]                            input_select_valid;

  logic [`IQ_INT_SIZE-1:0] free, load;

  logic [`IQ_INT_SIZE-1:0] ready, ready_alu, ready_br, ready_imul, ready_idiv;
  logic [`IQ_INT_SIZE-1:0] clear;

  logic [$clog2(`IQ_INT_SIZE)-1:0] clear_br, clear_imul, clear_idiv;
  logic                            clear_br_valid, clear_imul_valid, clear_idiv_valid;

  logic [`ISSUE_WIDTH_INT-1:0][$clog2(`IQ_INT_SIZE)-1:0] clear_alu;
  logic [`ISSUE_WIDTH_INT-1:0]                           clear_alu_valid;

  micro_op_t [`IQ_INT_SIZE-1:0] uop_to_slot, uop_to_issue;

  // If #free slots < dispatch width, set the issue queue as full
  assign free_count = free_count_reg - uop_in_count + uop_out_count;
  assign iq_int_full = free_count < `DISPATCH_WIDTH;

  always_ff @(posedge clock) begin
    if (reset) begin
      free_count_reg <= `IQ_INT_SIZE;
    end else begin
      free_count_reg <= free_count;
    end
  end

  generate
    for (genvar k = 0; k < `IQ_INT_SIZE; k++) begin
      issue_slot_int issue_slot_int_inst (
        .clock              (clock),
        .reset              (reset),
        .clear              (clear[k]),
        .ctb_prf_int_index  (ctb_prf_int_index),
        .ctb_valid          (ctb_valid),
        .load               (load[k]),
        .uop_in             (uop_to_slot[k]),
        .uop                (uop_to_issue[k]),
        .ready              (ready[k]),
        .free               (free[k])
      );
      assign ready_alu[k]  = ready[k] & (uop_to_issue[k].fu_code == FU_ALU);
      assign ready_br[k]   = ready[k] & (uop_to_issue[k].fu_code == FU_BR);
      assign ready_imul[k] = ready[k] & (uop_to_issue[k].fu_code == FU_IMUL);
      assign ready_idiv[k] = ready[k] & (uop_to_issue[k].fu_code == FU_IDIV);
    end
  endgenerate

  // Input selector
  issue_queue_int_selector #(
    /*REQS=*/ `DISPATCH_WIDTH,
    /*WIDTH=*/`IQ_INT_SIZE
  ) input_selector (
    .ready      (free),
    .sel        (input_select),
    .sel_valid  (input_select_valid)
  );

  always_comb begin
    uop_in_count = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      if (uop_in[i].valid) begin
        uop_in_count = uop_in_count + 1;
      end
    end
  end

  // Allocate input uops to each free issue slots
  always_comb begin
    uop_to_slot = 0;
    load = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      for (int j = 0; j < `IQ_INT_SIZE; j++) begin
        if ((input_select[i] == j) & input_select_valid[i] & uop_in[i].valid) begin
          uop_to_slot[j] = uop_in[i];
          load[j] = 1'b1;
        end
      end
    end
  end

  // Output selector
  // todo: Adjust for different execution pipes
  issue_queue_int_selector #(
    /*REQS=*/ 1,
    /*WIDTH=*/`IQ_INT_SIZE
  ) output_selector_br (
    .ready      (ready_br),
    .sel        (clear_br),
    .sel_valid  (clear_br_valid)
  );

  issue_queue_int_selector #(
    /*REQS=*/ 1,
    /*WIDTH=*/`IQ_INT_SIZE
  ) output_selector_imul (
    .ready      (ready_imul),
    .sel        (clear_imul),
    .sel_valid  (clear_imul_valid)
  );

  issue_queue_int_selector #(
    /*REQS=*/ 1,
    /*WIDTH=*/`IQ_INT_SIZE
  ) output_selector_idiv (
    .ready      (ready_idiv),
    .sel        (clear_idiv),
    .sel_valid  (clear_idiv_valid)
  );

  issue_queue_int_selector #(
    /*REQS=*/ `ISSUE_WIDTH_INT,
    /*WIDTH=*/`IQ_INT_SIZE
  ) output_selector_alu (
    .ready      (ready_alu),
    .sel        (clear_alu),
    .sel_valid  (clear_alu_valid)
  );
  
  always_comb begin
    uop_out_count = 0;
    for (int i = 0; i < `IQ_INT_SIZE; i++) begin
      if (clear[i]) begin
        uop_out_count = uop_out_count + 1;
      end
    end
  end

  // Select part of ready instructions to be issued
  always_comb begin
    uop_out[0] = 0;
    uop_out[1] = 0;
    uop_out[2] = 0;
    clear = 0;
    // Execution pipe 0 (ALU+Branch): Branch > ALU
    for (int j = 0; j < `IQ_INT_SIZE; j++) begin
      if ((clear_br == j) & clear_br_valid) begin
        uop_out[0] = uop_to_issue[j];
        clear[j] = 1;
        break;
      end else if ((clear_alu[0] == j) & clear_alu_valid[0]) begin
        uop_out[0] = uop_to_issue[j];
        clear[j] = 1;
      end
    end
    // Execution pipe 1 (ALU+IntMult): IntMult > ALU
    for (int j = 0; j < `IQ_INT_SIZE; j++) begin
      if ((clear_imul == j) & clear_imul_valid) begin
        uop_out[1] = uop_to_issue[j];
        clear[j] = 1;
        break;
      end else if ((clear_alu[1] == j) & clear_alu_valid[1]) begin
        uop_out[1] = uop_to_issue[j];
        clear[j] = 1;
      end
    end
    // Execution pipe 1 (ALU+IntDiv): IntDiv > ALU
    for (int j = 0; j < `IQ_INT_SIZE; j++) begin
      if ((clear_idiv == j) & clear_idiv_valid) begin
        uop_out[2] = uop_to_issue[j];
        clear[j] = 1;
        break;
      end else if ((clear_alu[2] == j) & clear_alu_valid[2]) begin
        uop_out[2] = uop_to_issue[j];
        clear[j] = 1;
      end
    end
  end

endmodule
