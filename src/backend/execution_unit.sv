module pipe_0 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input             request,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output [31:0]     out,
  output            busy,
)

  logic [31:0]  alu_out;
  logic         br_out;

  alu alu_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (alu_out)
  );

  branch branch_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (br_out)
  );

  assign out = ({32{uop.fu_code == FU_ALU}} & alu_out) |
               ({32{uop.fu_code == FU_BR}} & {32{br_out}});

  assign busy = 1'b0;

endmodule


