module alu (
  input               clock,
  input               reset,
  input  micro_op_t   uop,
  input  [31:0]       in1,
  input  [31:0]       in2,
  output logic [31:0] out
);

  logic signed [31:0] signed_in1, signed_in2;
  logic        [31:0] add, sub, slt, sltu, lxor, lor, land, sll, srl, sra;
  alu_type_t          fn;
  logic        [31:0] result;

  assign signed_in1 = opa;
  assign signed_in2 = opb;

  assign add  = in1 + in2;
  assign sub  = in1 - in2;
  assign slt  = signed_in1 < signed_in2;
  assign sltu = in1 < in2;
  assign lxor = in1 ^ in2;
  assign lor  = in1 | in2;
  assign land = in1 & in2;
  assign sll  = in1 << in2[4:0];
  assign srl  = in1 >> in2[4:0];
  assign sra  = signed_in1 >>> in2[4:0];

  assign fn = uop.alu_type;

  assign result = ({32{fn.fn_add}}  & add [31:0]) |
                  ({32{fn.fn_sub}}  & sub [31:0]) |
                  ({32{fn.fn_slt}}  & slt [31:0]) |
                  ({32{fn.fn_sltu}} & sltu[31:0]) |
                  ({32{fn.fn_xor}}  & lxor[31:0]) |
                  ({32{fn.fn_or}}   & lor [31:0]) |
                  ({32{fn.fn_and}}  & land[31:0]) |
                  ({32{fn.fn_sll}}  & sll [31:0]) |
                  ({32{fn.fn_srl}}  & srl [31:0]) |
                  ({32{fn.fn_sra}}  & sra [31:0]);

  always_ff @(posedge clock) begin
    if (reset)
      out <= 0;
    else
      out <= result;
  end

endmodule


module branch (
  input               clock,
  input               reset,
  input  micro_op_t   uop,
  input  [31:0]       in1,
  input  [31:0]       in2,
  output logic        out
);

  logic signed [31:0] signed_in1, signed_in2;
  logic               eq, ne, lt, ge, ltu, geu;
  br_type_t           fn;
  logic               result;

  assign signed_in1 = opa;
  assign signed_in2 = opb;

  assign eq   = in1 == in2;
  assign ne   = in1 != in2;
  assign lt   = signed_in1 < signed_in2;
  assign ge   = signed_in1 > signed_in2;
  assign ltu  = in1 < in2;
  assign geu  = in1 > in2;

  assign fn = uop.br_type;

  assign result = (fn.br_eq  & eq)  |
                  (fn.br_ne  & ne)  |
                  (fn.br_lt  & lt)  |
                  (fn.br_ge  & ge)  |
                  (fn.br_ltu & ltu) |
                  (fn.br_geu & geu);

  always_ff @(posedge clock) begin
    if (reset)
      out <= 0;
    else
      out <= result;
  end

endmodule
