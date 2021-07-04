// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Issue Queue for Memory Access
// Author:  Li Shi
// Date:    2021/06/14

`include "src/common/micro_op.svh"

`timescale 1ns / 1ps
module issue_slot_mem (
  input             clock,
  input             reset,

  // ctb = common tag bus
  input  [`ISSUE_WIDTH_MEM-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index,
  input  [`ISSUE_WIDTH_MEM-1:0]                           ctb_valid,

  input             load,

  input  micro_op_t uop_in,
  input  micro_op_t uop_new,
  output micro_op_t uop,

  output            ready,
  output            free
);

  wire [`ISSUE_WIDTH_MEM-1:0] rs1_index_match_ctb;
  wire [`ISSUE_WIDTH_MEM-1:0] rs2_index_match_ctb;
  wire [`ISSUE_WIDTH_MEM-1:0] rs1_from_ctb;
  wire [`ISSUE_WIDTH_MEM-1:0] rs2_from_ctb;
  wire                        rs1_from_ctb_valid;
  wire                        rs2_from_ctb_valid;

  logic rs1_ready;
  logic rs2_ready;

  generate
    for (genvar i = 0; i < `ISSUE_WIDTH_MEM; i++) begin
      assign rs1_index_match_ctb[i] = (uop_in.rs1_prf_int_index == ctb_prf_int_index[i]);
      assign rs2_index_match_ctb[i] = (uop_in.rs2_prf_int_index == ctb_prf_int_index[i]);
      assign rs1_from_ctb[i]        = (~rs1_ready & ctb_valid[i] & rs1_index_match_ctb[i]);
      assign rs2_from_ctb[i]        = (~rs2_ready & ctb_valid[i] & rs2_index_match_ctb[i]);
    end
  endgenerate
  
  assign rs1_from_ctb_valid = |rs1_from_ctb;
  assign rs2_from_ctb_valid = |rs2_from_ctb;

  always_ff @ (posedge clock) begin
    if (reset) begin
      uop <= 0;
    end else if (load & uop_in.valid) begin
      uop <= uop_in;
    end else begin
      uop <= uop_new;
    end
  end

  always_ff @ (posedge clock) begin
    if (reset) begin
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


module issue_queue_mem_output_selector (
  input       [`IQ_MEM_SIZE-1:0]     ready,
  input       [`IQ_MEM_SIZE-1:0]     is_store,
  output reg  [`ISSUE_WIDTH_MEM-1:0] [$clog2(`IQ_MEM_SIZE)-1:0] sel,
  output reg  [`ISSUE_WIDTH_MEM-1:0] sel_valid
);

  logic [`ISSUE_WIDTH_MEM-1:0] [`IQ_MEM_SIZE-1:0] readys;

  always_comb begin
    readys[0] = ready;
    for (int i = `ISSUE_WIDTH_MEM; i < `IQ_MEM_SIZE; i++) begin
      if (is_store[i]) begin
        readys[0][i] = 0;
      end
    end
  end

  generate
    for (genvar i = 1; i < `ISSUE_WIDTH_MEM; i++) begin
      assign readys[i] = readys[i-1] & ~(sel_valid[i-1] << sel[i-1]);
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `ISSUE_WIDTH_MEM; i++) begin
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


// Input:  From dispatch, width = DISPATCH_WIDTH  = 4
// Output: To PRF & Mem,  width = ISSUE_WIDTH_MEM = 1
`timescale 1ns / 1ps
module issue_queue_mem (
  input  clock,
  input  reset,

  // ctb = common tag bus
  input  [`ISSUE_WIDTH_MEM-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index,
  input  [`ISSUE_WIDTH_MEM-1:0]             ctb_valid,

  input  [`ISSUE_WIDTH_MEM-1:0]             ex_busy,

  input  micro_op_t [`DISPATCH_WIDTH-1:0]   uop_in,
  output micro_op_t [`ISSUE_WIDTH_MEM-1:0]  uop_out,

  output iq_mem_full
);

  logic [$clog2(`IQ_MEM_SIZE):0]  uop_in_count, uop_out_count;
  logic [$clog2(`IQ_MEM_SIZE):0]  free_count, tail;
  reg   [$clog2(`IQ_MEM_SIZE):0]  free_count_reg, tail_reg;
  logic [$clog2(`IQ_MEM_SIZE):0]  compress_offset;

  logic       [`IQ_MEM_SIZE-1:0]    free, load;
  logic       [`IQ_MEM_SIZE-1:0]    ready, is_store, clear;
  micro_op_t  [`IQ_MEM_SIZE-1:0]    uop_to_slot, uop_to_issue;

  logic [`ISSUE_WIDTH_MEM-1:0] [$clog2(`IQ_MEM_SIZE)-1:0] output_sel;
  logic [`ISSUE_WIDTH_MEM-1:0]                            output_sel_valid;

  // If #free slots < dispatch width, set the issue queue as full
  assign free_count = free_count_reg - uop_in_count + uop_out_count;
  assign iq_mem_full = free_count < `DISPATCH_WIDTH;
  assign compress_offset = uop_out_count;

  always_ff @(posedge clock) begin
    if (reset) begin
      free_count_reg <= `IQ_MEM_SIZE;
      tail_reg <= 0;
    end else begin
      free_count_reg <= free_count;
      tail_reg <= tail;
    end
  end

  generate
    for (genvar k = 0; k < `IQ_MEM_SIZE; k++) begin
      issue_slot_mem issue_slot_mem_inst (
        .clock              (clock),
        .reset              (reset),
        .ctb_prf_int_index  (ctb_prf_int_index),
        .ctb_valid          (ctb_valid),
        .load               (load[k]),
        .uop_in             (uop_to_slot[k]),
        .uop_new            (uop_to_issue[k + compress_offset]),
        .uop                (uop_to_issue[k]),
        .ready              (ready[k]),
        .free               (free[k])
      );
    end
  endgenerate

  // Allocate input uops from tail - compress_offset
  always_comb begin
    uop_to_slot = 0;
    load = 0;
    uop_in_count = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      uop_to_slot[i + tail_reg - compress_offset] = uop_in[i];
      load[i + tail_reg - compress_offset] = 1;
      if (uop_in[i].valid) begin
        uop_in_count = uop_in_count + 1;
      end
    end
    tail = tail_reg + uop_in_count - compress_offset;
  end
  
  // Output selector
  issue_queue_mem_output_selector issue_queue_mem_output_selector (
    .ready      (ready),
    .is_store   (is_store),
    .sel        (output_sel),
    .sel_valid  (output_sel_valid)
  );

  always_comb begin
    for (int i = 0; i < `IQ_MEM_SIZE; i++) begin
      is_store[i] = (uop_to_issue[i].mem_type == MEM_ST);
    end
  end

  always_comb begin
    clear = 0;
    for (int i = 0; i < `ISSUE_WIDTH_MEM; i++) begin
      clear[output_sel[i]] = output_sel_valid[i];
    end
  end

  // Select part of ready instructions to be issued
  always_comb begin
    uop_out = 0;
    uop_out_count = 0;
    for (int i = 0; i < `ISSUE_WIDTH_MEM; i++) begin
      for (int j = 0; j < `IQ_MEM_SIZE; j++) begin
        if (clear[j]) begin
          uop_out[i] = uop_to_issue[j];
          uop_out_count = uop_out_count + 1;
        end
      end
    end
  end

endmodule
