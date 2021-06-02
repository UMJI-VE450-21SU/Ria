`include "micro_op.svh"

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
  input  micro_op_t uop_compressed,
  output micro_op_t uop,
  
  output            ready,
  output            free
);

  wire [`ISSUE_WIDTH_INT-1:0] rs1_index_match_ctb;
  wire [`ISSUE_WIDTH_INT-1:0] rs2_index_match_ctb;
  wor                         rs1_from_ctb_valid;
  wor                         rs2_from_ctb_valid;

  logic rs1_ready;
  logic rs2_ready;

  generate
    for (genvar i = 0; i < `ISSUE_WIDTH_INT; i++) begin
      assign rs1_index_match_ctb[i] = (uop_in.rs1_prf_int_index == ctb_prf_int_index[i]);
      assign rs2_index_match_ctb[i] = (uop_in.rs2_prf_int_index == ctb_prf_int_index[i]);
      assign rs1_from_ctb_valid     = (~rs1_ready & ctb_valid[i] & rs1_index_match_ctb[i]);
      assign rs2_from_ctb_valid     = (~rs2_ready & ctb_valid[i] & rs2_index_match_ctb[i]);
    end
  endgenerate

  assign free = ~uop.valid;

  always_ff @ (posedge clock) begin
    if (reset | clear) begin
      uop <= 0;
    end else if (load & uop_in.valid) begin
      uop <= uop_in;
    end else begin
      uop <= uop_compressed;
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
      rs1_ready <= (uop_compressed.rs1_source == RS_FROM_RF) ? (uop_compressed.rs1_from_ctb ? rs1_from_ctb_valid : 1'b1) : 1'b1;
      rs2_ready <= (uop_compressed.rs2_source == RS_FROM_RF) ? (uop_compressed.rs2_from_ctb ? rs2_from_ctb_valid : 1'b1) : 1'b1;
    end
  end

  assign ready = rs1_ready & rs2_ready;

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

  logic [$clog2(`IQ_INT_SIZE)-1:0]  uop_in_count, uop_out_count;
  logic [$clog2(`IQ_INT_SIZE)-1:0]  free_count;
  reg   [$clog2(`IQ_INT_SIZE)-1:0]  free_count_reg;

  wire  [`DISPATCH_WIDTH-1:0] [`IQ_INT_SIZE-1:0] gnt_bus_in;
  wire  [`ISSUE_WIDTH_INT-1:0][`IQ_INT_SIZE-1:0] gnt_bus_out;

  logic       [`IQ_INT_SIZE-1:0]      free, load;

  logic       [`IQ_INT_SIZE-1:0]      ready;
  logic       [`IQ_INT_SIZE-1:0]      clear;

  micro_op_t  [`IQ_INT_SIZE-1:0]      uop_to_slot, uop_to_issue;

  logic [`IQ_INT_SIZE-1:0][$clog2(`IQ_INT_SIZE)-1:0] compressed_offset;

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
    end
  endgenerate


  // Output selector
  // todo: Adjust for different execution pipes
  psel_gen #(
    /*REQS=*/ `ISSUE_WIDTH_INT,
    /*WIDTH=*/`IQ_INT_SIZE
  ) output_selector (
    .req      (ready),
    .gnt      (clear),
    .gnt_bus  (gnt_bus_out),
    .empty
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
    for (int i = 0; i < `ISSUE_WIDTH_INT; i++) begin
      for (int j = 0; j < `IQ_INT_SIZE; j++) begin
        if (gnt_bus_out[i][j]) begin
          uop_out[i] = uop_to_issue[j];
        end
      end
    end
  end





  // Input selector
  psel_gen #(
    /*REQS=*/ `DISPATCH_WIDTH,
    /*WIDTH=*/`IQ_INT_SIZE
  ) input_selector (
    .req      (free),
    .gnt,
    .gnt_bus  (gnt_bus_in),
    .empty
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
        if (gnt_bus_in[i][j] & uop_in[i].valid) begin
          uop_to_slot[j] = uop_in[i];
          load[j] = 1'b1;
        end
      end
    end
  end


endmodule
