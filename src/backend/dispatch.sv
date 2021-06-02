`include "common/micro_op.svh"

module dispatch (
  input  micro_op_t [`DISPATCH_WIDTH-1:0] uop_in,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_int,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_mem,
  output micro_op_t [`DISPATCH_WIDTH-1:0] uop_to_fp
);

  generate
    for (genvar i = 0; i < `DISPATCH_WIDTH; i++) begin
      assign uop_to_int[i] = (uop_in[i].iq_code == IQ_INT) ? uop_in[i] : 0;
      assign uop_to_mem[i] = (uop_in[i].iq_code == IQ_MEM) ? uop_in[i] : 0;
      assign uop_to_fp[i]  = (uop_in[i].iq_code == IQ_FP)  ? uop_in[i] : 0;
    end
  endgenerate

endmodule
