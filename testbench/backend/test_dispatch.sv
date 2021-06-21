`include "micro_op.svh"

`timescale 1ns/100ps
module test_dispatch;

  micro_op_t [`DISPATCH_WIDTH-1:0] uop_in;
  micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_int;
  micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_mem;
  micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_fp;

  micro_op_t [3:0] uop;

  dispatch dispatch_inst (
    .uop_in(uop_in),
    .uop_to_int(uop_to_int),
    .uop_to_mem(uop_to_mem),
    .uop_to_fp(uop_to_fp)
  );

  integer i;
  initial begin
    for (i = 0; i < 15; i++) begin
      uop_in[i] = 0;
    end
    #1;
    $finish;
  end

  initial begin
    $dumpfile("logs/dump.vcd");
    $dumpvars();
  end

endmodule