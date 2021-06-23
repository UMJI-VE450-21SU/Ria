// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Fetch Buffer
// Author:  Yiqiu Sun
// Date:    2021/06/01

`include "../common/micro_op.svh"

module fetch_buffer (
  input                                 clock,
  input                                 reset,

  input  fb_entry_t [`FECTH_WIDTH-1:0]  insts_in,
  input                                 insts_in_valid,

  output fb_entry_t [`FECTH_WIDTH-1:0]  insts_out,
  output logic [`FECTH_WIDTH-1:0]       valid,

  output logic                          full  // Connect to inst_fetch
);

  logic [`FECTH_WIDTH-1:0] ready_hub;

  fifo #(
    .WIDTH      ($bits(fb_entry_t)),
    .LOGDEPTH   (`IB_ADDR)
  ) fb_fifo [`FECTH_WIDTH-1:0] (
    .clk        (clock),
    .rst        (reset),
    .enq_valid  (insts_in_valid),
    .enq_data   (insts_in),
    .enq_ready  (ready_hub),
    .deq_valid  (valid),
    .deq_data   (insts_out),
    .deq_ready  (insts_in_valid)
  );

  assign full = (~ready_hub != 0);
  // at least one of the fb is not ready
  // Why only one scalar valid signal, not a vector? - solved

endmodule

