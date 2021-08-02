// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Issue Queue for Approximate Unit
// Author:  Jian Shi
// Date:    2021/08/02

`include "src/common/micro_op.svh"

`define IQ_AP_INDEX_SIZE    $clog2(`IQ_AP_SIZE)

`timescale 1ns / 1ps
module issue_slot_ap (
  input             clock,
  input             reset,
  input             clear,

  input                                       load,
  input  micro_op_t                           uop_in,
  output micro_op_t                           uop,

  output logic      [`PRF_INT_INDEX_SIZE-1:0] rs1_index,
  output logic      [`PRF_INT_INDEX_SIZE-1:0] rs2_index,
  input                                       rs1_busy,
  input                                       rs2_busy,

  output                                      ready,
  output                                      free
);

  wire rs1_ready, rs2_ready;

  always_comb begin
    if (load & uop_in.valid) begin
      rs1_index = (uop_in.rs1_source == RS_FROM_RF) ? uop_in.rs1_prf_int_index : 0;
      rs2_index = (uop_in.rs2_source == RS_FROM_RF) ? uop_in.rs2_prf_int_index : 0;
    end else begin
      rs1_index = (uop.rs1_source == RS_FROM_RF) ? uop.rs1_prf_int_index : 0;
      rs2_index = (uop.rs2_source == RS_FROM_RF) ? uop.rs2_prf_int_index : 0;
    end
  end

  always_ff @ (posedge clock) begin
    if (reset | clear) begin
      uop <= 0;
    end else if (load & uop_in.valid) begin
      uop <= uop_in;
    end
  end

  assign free       = ~uop.valid;
  assign rs1_ready  = ~rs1_busy;
  assign rs2_ready  = ~rs2_busy;
  assign ready      = rs1_ready & rs2_ready & uop.valid;

endmodule

module issue_queue_ap_selector (ready, sel, sel_valid);

  parameter REQS  = `DISPATCH_WIDTH;
  parameter WIDTH = `IQ_AP_SIZE;

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
        32'b???????????????????????????????1: sel[i] = 5'b00000;
        32'b??????????????????????????????10: sel[i] = 5'b00001;
        32'b?????????????????????????????100: sel[i] = 5'b00010;
        32'b????????????????????????????1000: sel[i] = 5'b00011;
        32'b???????????????????????????10000: sel[i] = 5'b00100;
        32'b??????????????????????????100000: sel[i] = 5'b00101;
        32'b?????????????????????????1000000: sel[i] = 5'b00110;
        32'b????????????????????????10000000: sel[i] = 5'b00111;
        32'b???????????????????????100000000: sel[i] = 5'b01000;
        32'b??????????????????????1000000000: sel[i] = 5'b01001;
        32'b?????????????????????10000000000: sel[i] = 5'b01010;
        32'b????????????????????100000000000: sel[i] = 5'b01011;
        32'b???????????????????1000000000000: sel[i] = 5'b01100;
        32'b??????????????????10000000000000: sel[i] = 5'b01101;
        32'b?????????????????100000000000000: sel[i] = 5'b01110;
        32'b????????????????1000000000000000: sel[i] = 5'b01111;
        32'b???????????????10000000000000000: sel[i] = 5'b10000;
        32'b??????????????100000000000000000: sel[i] = 5'b10001;
        32'b?????????????1000000000000000000: sel[i] = 5'b10010;
        32'b????????????10000000000000000000: sel[i] = 5'b10011;
        32'b???????????100000000000000000000: sel[i] = 5'b10100;
        32'b??????????1000000000000000000000: sel[i] = 5'b10101;
        32'b?????????10000000000000000000000: sel[i] = 5'b10110;
        32'b????????100000000000000000000000: sel[i] = 5'b10111;
        32'b???????1000000000000000000000000: sel[i] = 5'b11000;
        32'b??????10000000000000000000000000: sel[i] = 5'b11001;
        32'b?????100000000000000000000000000: sel[i] = 5'b11010;
        32'b????1000000000000000000000000000: sel[i] = 5'b11011;
        32'b???10000000000000000000000000000: sel[i] = 5'b11100;
        32'b??100000000000000000000000000000: sel[i] = 5'b11101;
        32'b?1000000000000000000000000000000: sel[i] = 5'b11110;
        32'b10000000000000000000000000000000: sel[i] = 5'b11111;
        default: begin
          sel[i] = 5'b00000;
          sel_valid[i] = 0;
        end
      endcase
    end
  end

endmodule


// Input:  From dispatch,    width = DISPATCH_WIDTH = 4
// Output: To PRF & Ex Unit, width = ISSUE_WIDTH_AP = 2
`timescale 1ns / 1ps
module issue_queue_ap (
  input  clock,
  input  reset,
  input  clear_en,
  input  load_en,  // global load signal

  output [`IQ_AP_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs1_index,
  output [`IQ_AP_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs2_index,
  input  [`IQ_AP_SIZE-1:0]                          rs1_busy,
  input  [`IQ_AP_SIZE-1:0]                          rs2_busy,

  input  [`ISSUE_WIDTH_AP-1:0]                      ex_busy,

  input  micro_op_t [`DISPATCH_WIDTH-1:0]           uop_in,
  output micro_op_t [`ISSUE_WIDTH_AP-1:0]           uop_out,

  output iq_ap_full
);

  logic [`IQ_AP_INDEX_SIZE:0] uop_in_count, uop_out_count;
  logic [`IQ_AP_INDEX_SIZE:0] free_count;
  reg   [`IQ_AP_INDEX_SIZE:0] free_count_reg;

  logic [`DISPATCH_WIDTH-1:0] [`IQ_AP_INDEX_SIZE-1:0] input_select;
  logic [`DISPATCH_WIDTH-1:0]                         input_select_valid;

  logic [`IQ_AP_SIZE-1:0] free, load;

  logic [`IQ_AP_SIZE-1:0] ready, ready_amul, ready_adiv;
  logic [`IQ_AP_SIZE-1:0] clear;

  logic [1:0][`IQ_AP_INDEX_SIZE-1:0]  clear_amul;       // Pipe 4 for apporximate mul
  logic [1:0]                         clear_amul_valid;
  logic [`IQ_AP_INDEX_SIZE-1:0]       clear_adiv;       // Pipe 5 for approximate div
  logic                               clear_adiv_valid;

  micro_op_t [`IQ_AP_SIZE-1:0] uop_to_slot, uop_to_issue;

  // If #free slots < dispatch width, set the issue queue as full
  assign free_count = free_count_reg - uop_in_count + uop_out_count;
  assign iq_ap_full = free_count < `DISPATCH_WIDTH;

  always_ff @(posedge clock) begin
    if (reset | clear_en) begin
      free_count_reg <= `IQ_AP_SIZE;
    end else begin
      free_count_reg <= free_count;
    end
  end

  generate
    for (genvar k = 0; k < `IQ_AP_SIZE; k++) begin
      issue_slot_int issue_slot_int_inst (
        .clock      (clock),
        .reset      (reset),
        .clear      (clear[k] | clear_en),
        .load       (load[k] & load_en),
        .uop_in     (uop_to_slot[k]),
        .uop        (uop_to_issue[k]),
        .rs1_index  (rs1_index[k]),
        .rs2_index  (rs2_index[k]),
        .rs1_busy   (rs1_busy[k]),
        .rs2_busy   (rs2_busy[k]),
        .ready      (ready[k]),
        .free       (free[k])
      );
      assign ready_amul[k]  = ready[k] & (uop_to_issue[k].fu_code == FU_AMUL);
      assign ready_adiv[k]  = ready[k] & (uop_to_issue[k].fu_code == FU_ADIV);
    end
  endgenerate

  wire iq_ap_print = 0;

  always_ff @(posedge clock) begin
    if (iq_ap_print) begin
      for (integer i = 0; i < `IQ_AP_SIZE; i++) begin
        $display("[IQ_AP] slot %d (ready=%b)", i, ready[i]);
        print_uop(uop_to_issue[i]);
      end
      $display("[IQ_AP] clear=%b, ready_amul=%b", clear, ready_amul);
      $display("[IQ_AP] clear_amul[0]=%h, clear_amul[1]=%h", clear_amul[0], clear_amul[1]);
      $display("[IQ_AP] clear_amul_valid[0]=%h, clear_amul_valid[1]=%h", clear_amul_valid[0], clear_amul_valid[1]);
      $display("[IQ_AP] free_count_reg=%d", free_count_reg);
    end
  end

  // Input selector
  issue_queue_ap_selector #(
    /*REQS=*/ `DISPATCH_WIDTH,
    /*WIDTH=*/`IQ_AP_SIZE
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
      for (int j = 0; j < `IQ_AP_SIZE; j++) begin
        if ((input_select[i] == j) & input_select_valid[i] & uop_in[i].valid) begin
          uop_to_slot[j] = uop_in[i];
          load[j] = 1'b1;
        end
      end
    end
  end

  // Output selector
  issue_queue_ap_selector #(
    /*REQS=*/  2,
    /*WIDTH=*/ `IQ_AP_SIZE
  ) output_selector_amul (
    .ready      (ready_amul),
    .sel        (clear_amul),
    .sel_valid  (clear_amul_valid)
  );

  issue_queue_ap_selector #(
    /*REQS=*/  1,
    /*WIDTH=*/ `IQ_AP_SIZE
  ) output_selector_adiv (
    .ready      (ready_adiv),
    .sel        (clear_adiv),
    .sel_valid  (clear_adiv_valid)
  );

  always_comb begin
    uop_out_count = 0;
    for (int i = 0; i < `IQ_AP_SIZE; i++) begin
      if (clear[i]) begin
        uop_out_count = uop_out_count + 1;
      end
    end
  end

  // Select part of ready instructions to be issued
  always_comb begin
    uop_out = 0;
    clear = 0;
    if (clear_amul_valid[0]) begin
      uop_out[0] = uop_to_issue[clear_amul[0]];
      clear[clear_amul[0]] = 1;
    end
    if (clear_amul_valid[1]) begin
      uop_out[1] = uop_to_issue[clear_amul[1]];
      clear[clear_amul[1]] = 1;
    end
    if (clear_adiv_valid) begin
      uop_out[2] = uop_to_issue[clear_adiv];
      clear[clear_adiv] = 1;
    end
  end

endmodule
