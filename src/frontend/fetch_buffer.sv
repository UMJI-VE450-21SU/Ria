// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Fetch Buffer
// Author:  Yiqiu Sun
// Date:    2021/06/01

`include "src/common/micro_op.svh"

module fetch_buffer (
  input                                 clock,
  input                                 reset,

  input  fb_entry_t [`FETCH_WIDTH-1:0]  insts_in,
  input                                 insts_in_valid,

  output fb_entry_t [`FETCH_WIDTH-1:0]  insts_out,
  output            [`FETCH_WIDTH-1:0]  insts_out_valid,

  output logic                          full  // Connect to inst_fetch
);

  logic [`FETCH_WIDTH-1:0] ready_hub;
  logic [`FETCH_WIDTH-1:0] insts_out_valid_tmp;

  fifo #(
    .WIDTH      ($bits(fb_entry_t)),
    .LOGDEPTH   (`FB_ADDR)
  ) fb_fifo [`FETCH_WIDTH-1:0] (
    .clk        (clock),
    .rst        (reset),
    .enq_valid  (insts_in_valid),
    .enq_data   (insts_in),
    .enq_ready  (ready_hub),
    .deq_valid  (insts_out_valid_tmp),
    .deq_data   (insts_out),
    .deq_ready  (insts_in_valid)
  );

  assign full = (~ready_hub == 0);

  generate
    for (genvar i = 0; i < `FETCH_WIDTH; i++)
      assign insts_out_valid[i] = insts_out_valid_tmp[i] & insts_out[i].valid;
  endgenerate

endmodule
