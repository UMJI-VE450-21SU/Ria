`include "micro_op.svh"

`timescale 1ns / 1ps
module test_issue_queue;
  parameter half_clk_cycle = 1;

  reg  clock, reset;
  reg  [`ISSUE_WIDTH_INT-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index;
  reg  [`ISSUE_WIDTH_INT-1:0]        ctb_valid;
  reg  [`ISSUE_WIDTH_INT-1:0]        ex_busy;
  micro_op_t [`DISPATCH_WIDTH-1:0]   uop_in;
  micro_op_t [`ISSUE_WIDTH_INT-1:0]  uop_out;
  wire  iq_int_full;

  issue_queue_int issue_queue_int_inst (
    .clock              (clock            ),
    .reset              (reset            ),
    .ctb_prf_int_index  (ctb_prf_int_index),
    .ctb_valid          (ctb_valid        ),
    .ex_busy            (ex_busy          ),
    .uop_in             (uop_in           ),
    .uop_out            (uop_out          ),
    .iq_int_full        (iq_int_full      )
  );

  always #half_clk_cycle clock = ~clock;

  initial begin
    #0  clock = 0; reset = 1; ctb_prf_int_index = 0; ctb_valid = 0; ex_busy = 0; uop_in = 0;
    #2  reset = 0;
    #2  for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
          uop_in[i].valid = 1; uop_in[i].iq_code.iq_int = 1; uop_in[i].fu_code.fu_alu = 1;
        end
    #8 $stop;
  end

endmodule
