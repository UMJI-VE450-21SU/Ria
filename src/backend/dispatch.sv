// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Dispatch
// Author:  Li Shi
// Date:    2021/06/01

`include "src/common/micro_op.svh"

module dispatch_selector (
  input       [`DISPATCH_WIDTH-1:0] ready,
  output reg  [`DISPATCH_WIDTH-1:0] [$clog2(`DISPATCH_WIDTH)-1:0] sel,
  output reg  [`DISPATCH_WIDTH-1:0] sel_valid
);

  wire [`DISPATCH_WIDTH-1:0] [`DISPATCH_WIDTH-1:0] readys;

  assign readys[0] = ready;
  generate
    for (genvar i = 1; i < `DISPATCH_WIDTH; i++) begin
      assign readys[i] = readys[i-1] & ~(sel_valid[i-1] << sel[i-1]);
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      sel_valid[i] = 1;
      casez (readys[i])
        4'b???1: sel[i] = 2'b00;
        4'b??10: sel[i] = 2'b01;
        4'b?100: sel[i] = 2'b10;
        4'b1000: sel[i] = 2'b11;
        default: begin
          sel[i] = 2'b00;
          sel_valid[i] = 0;
        end
      endcase
    end
  end

endmodule


module dispatch (
  input  micro_op_t [`DISPATCH_WIDTH-1:0] uop_in,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_int,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_mem,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_ap
);

  logic [`DISPATCH_WIDTH-1:0] uop_to_int_valid, uop_to_int_sel_valid;
  logic [`DISPATCH_WIDTH-1:0] uop_to_mem_valid, uop_to_mem_sel_valid;
  logic [`DISPATCH_WIDTH-1:0] uop_to_ap_valid,  uop_to_ap_sel_valid;

  wire [`DISPATCH_WIDTH-1:0] [$clog2(`DISPATCH_WIDTH)-1:0] uop_to_int_sel;
  wire [`DISPATCH_WIDTH-1:0] [$clog2(`DISPATCH_WIDTH)-1:0] uop_to_mem_sel;
  wire [`DISPATCH_WIDTH-1:0] [$clog2(`DISPATCH_WIDTH)-1:0] uop_to_ap_sel;

  // Valid signals for input micro-ops
  generate
    for (genvar i = 0; i < `DISPATCH_WIDTH; i++) begin
      assign uop_to_int_valid[i] = uop_in[i].valid & (uop_in[i].iq_code == IQ_INT);
      assign uop_to_mem_valid[i] = uop_in[i].valid & (uop_in[i].iq_code == IQ_MEM);
      assign uop_to_ap_valid[i]  = uop_in[i].valid & (uop_in[i].iq_code == IQ_AP);
    end
  endgenerate

  dispatch_selector uop_to_int_selector (
    .ready      (uop_to_int_valid),
    .sel        (uop_to_int_sel),
    .sel_valid  (uop_to_int_sel_valid)
  );

  dispatch_selector uop_to_mem_selector (
    .ready      (uop_to_mem_valid),
    .sel        (uop_to_mem_sel),
    .sel_valid  (uop_to_mem_sel_valid)
  );

  dispatch_selector uop_to_ap_selector (
    .ready      (uop_to_ap_valid),
    .sel        (uop_to_ap_sel),
    .sel_valid  (uop_to_ap_sel_valid)
  );

  // Send selected micro-ops to output
  generate
    for (genvar i = 0; i < `DISPATCH_WIDTH; i++) begin
      assign uop_to_int[i] = uop_to_int_sel_valid[i] ? uop_in[uop_to_int_sel[i]] : 0;
      assign uop_to_mem[i] = uop_to_mem_sel_valid[i] ? uop_in[uop_to_mem_sel[i]] : 0;
      assign uop_to_ap[i]  = uop_to_ap_sel_valid[i]  ? uop_in[uop_to_ap_sel[i]]  : 0;
    end
  endgenerate

endmodule
