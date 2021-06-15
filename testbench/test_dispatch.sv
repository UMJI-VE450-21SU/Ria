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

  // integer i;
  // task print_info;
  //   begin
  //     $display("free: %b", req);
  //     $display("gnts: %b", gnt);

  //     for(i=0; i<REQS; i=i+1) begin
  //       $display("gnt%1d: %b", i, gnt_bus[i]);
  //     end
  //     $display("");
  //   end
  // endtask

  initial begin
    $dumpfile("logs/dump.vcd");
    $dumpvars();
  end

endmodule