`include "common/micro_op.svh"

module issue_slot_int (
  input             clock,
  input             reset,
  input             clear,

  // ctb = common tag bus
  input  [`ISSUE_WIDTH_INT-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index,
  input  [`ISSUE_WIDTH_INT-1:0]                           ctb_valid,

  input             rs1_from_ctb,
  input             rs2_from_ctb,

  input             load,

  input  micro_op_t uop_in,
  output micro_op_t uop_out,

  output            ready,
  output            free
);

  wire [`ISSUE_WIDTH_INT-1:0] rs1_index_match_ctb;
  wire [`ISSUE_WIDTH_INT-1:0] rs2_index_match_ctb;
  wor                         rs1_from_ctb_valid;
  wor                         rs2_from_ctb_valid;

  logic rs1_ready;
  logic rs2_ready;

  micro_op_t uop;

  for (int i = 0; i < `ISSUE_WIDTH_INT; i++) begin
    assign rs1_index_match_ctb[i] = (uop_in.rs1_prf_int_index == ctb_prf_int_index[i]);
    assign rs2_index_match_ctb[i] = (uop_in.rs2_prf_int_index == ctb_prf_int_index[i]);
    assign rs1_from_ctb_valid     = (~rs1_ready & ctb_valid[i] & rs1_index_match_ctb[i]);
    assign rs2_from_ctb_valid     = (~rs2_ready & ctb_valid[i] & rs2_index_match_ctb[i]);
  end

  always_ff @ (posedge clock) begin
    if (reset | clear) begin
      free      <= 1'b1;
      rs1_ready <= 1'b0;
      rs2_ready <= 1'b0;
      uop       <= 0;
    end else if (load & uop_in.valid) begin
      free      <= 1'b0;
      rs1_ready <= uop_in.rs1_valid ? (rs1_from_ctb ? rs1_from_ctb_valid : 1'b1) : 1'b1;
      rs2_ready <= uop_in.rs2_valid ? (rs2_from_ctb ? rs2_from_ctb_valid : 1'b1) : 1'b1;
      uop       <= uop_in;
    end
    // else: rs1_ready/rs2_ready remain current values
  end

  assign ready = rs1_ready & rs2_ready;
  assign uop_out = ready ? uop : 0;

endmodule


module issue_queue_int (
  input  clock,
  input  reset,

  // ctb = common tag bus
  input  [`ISSUE_WIDTH_INT-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index,
  input  [`ISSUE_WIDTH_INT-1:0]                           ctb_valid,

  // todo: how to set these inputs?
  // todo: how to know whether a dependency is ready or waiting for ctb?
  // input  [`ISSUE_WIDTH_INT-1:0]             rs1_from_ctb,
  // input  [`ISSUE_WIDTH_INT-1:0]             rs2_from_ctb,

  input  micro_op_t [`DISPATCH_WIDTH-1:0]   uop_in,
  output micro_op_t [`ISSUE_WIDTH_INT-1:0]  uop_out,

  output iq_int_full
);

  logic [$clog2(`IQ_INT_SIZE)-1:0]  uop_in_count, uop_out_count;
  logic [$clog2(`IQ_INT_SIZE)-1:0]  free_count;
  reg   [$clog2(`IQ_INT_SIZE)-1:0]  free_count_reg;

  wire  [`DISPATCH_WIDTH-1:0][`IQ_INT_SIZE-1:0] gnt_bus_in, gnt_bus_out;

  logic       [`IQ_INT_SIZE-1:0]    free, load, ready, clear;
  micro_op_t  [`IQ_INT_SIZE-1:0]    uop_to_slot, uop_to_issue;

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
      issue_slot_int (
        .clock              (clock),
        .reset              (reset),
        .ctb_prf_int_index  (ctb_prf_int_index),
        .ctb_valid          (ctb_valid),
        .rs1_from_ctb       (1'b0)
        .rs2_from_ctb       (1'b0),
        .load               (load[k]),
        .uop_in             (uop_to_slot[k]),
        .uop_out            (uop_to_issue[k]),
        .ready              (ready[k]),
        .free               (free[k])
      )
    end
  endgenerate


  // Input selector
  psel_gen input_selector #(
    /*REQS=*/ `DISPATCH_WIDTH,
    /*WIDTH=*/`IQ_INT_SIZE
  ) psel_gen_inst (
    .req      (free),
    .gnt,
    .gnt_bus  (gnt_bus_in),
    .empty
  );

  always_comb begin
    uop_in_count = 0;
    load = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      for (int j = 0; j < `IQ_INT_SIZE; i++) begin
        if (gnt_bus_in[i][j] & uop_in[i].valid) begin
          uop_to_slot[j] = uop_in[i];
          load[j] = 1'b1;
          uop_in_count = uop_in_count + 1;
        end
      end
    end
  end

  // Output selector
  psel_gen input_selector #(
    /*REQS=*/ `ISSUE_WIDTH_INT,
    /*WIDTH=*/`IQ_INT_SIZE
  ) psel_gen_inst (
    .req      (ready),
    .gnt      (clear),
    .gnt_bus  (gnt_bus_out),
    .empty
  );
  
  always_comb begin
    uop_out_count = 0;
    for (int i = 0; i < `ISSUE_WIDTH_INT; i++) begin
      for (int j = 0; j < `IQ_INT_SIZE; i++) begin
        if (gnt_bus_out[i][j]) begin
          uop_out[uop_out_count] = uop_to_issue[j];
          uop_out_count = uop_out_count + 1;
        end
      end
    end
  end

endmodule
