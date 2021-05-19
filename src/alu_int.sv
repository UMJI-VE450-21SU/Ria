module alu_int (
  alu_pkt_t             alu_op,
  input   [31:0]        op_a,
  input   [31:0]        op_b,
  output logic [31:0]   out
);

  logic signed [31:0]   signed_op_a, signed_op_b;
  logic                 eq, ne, lt, ge, ltu, geu;
  logic        [31:0]   add, sub, slt, sltu, lxor, lor, land, sll, srl, sra;

  assign signed_op_a = opa;
  assign signed_op_b = opb;

  assign eq   = op_a == op_b;
  assign ne   = op_a != op_b;
  assign lt   = signed_op_a < signed_op_b;
  assign ge   = signed_op_a > signed_op_b;
  assign ltu  = op_a < op_b;
  assign geu  = op_a > op_b;

  assign add  = op_a + op_b;
  assign sub  = op_a - op_b;
  assign slt  = signed_op_a < signed_op_b;
  assign sltu = op_a < op_b;
  assign lxor = op_a ^ op_b;
  assign lor  = op_a | op_b;
  assign land = op_a & op_b;
  assign sll  = op_a << op_b[4:0];
  assign srl  = op_a >> op_b[4:0];
  assign sra  = signed_op_a >>> op_b[4:0];

  assign out  = ({32{alu_op.beq}}   & {32{eq}})   | ({32{alu_op.bne}}   & {32{ne}})   |
                ({32{alu_op.blt}}   & {32{lt}})   | ({32{alu_op.bge}}   & {32{ge}})   |
                ({32{alu_op.bltu}}  & {32{ltu}})  | ({32{alu_op.bgeu}}  & {32{geu}})  |
                ({32{alu_op.add}}   & add[31:0])  | ({32{alu_op.sub}}   & sub[31:0])  |
                ({32{alu_op.slt}}   & slt[31:0])  | ({32{alu_op.sltu}}  & sltu[31:0]) |
                ({32{alu_op.lxor}}  & lxor[31:0]) | ({32{alu_op.lor}}   & lor[31:0])  |
                ({32{alu_op.ladd}}  & ladd[31:0]) | ({32{alu_op.sll}}   & sll[31:0])  |
                ({32{alu_op.srl}}   & srl[31:0])  | ({32{alu_op.sra}}   & sra[31:0]);

endmodule