module alu (
  input                 clock;
  input  op_type_t      op_type,
  input  [31:0]         op_1,
  input  [31:0]         op_2,
  output logic [31:0]   alu_out
);

  logic signed  [31:0]  signed_op_1, signed_op_2;
  logic         [31:0]  add_out, sub_out, slt_out, sltu_out, arith_out;
  logic         [31:0]  xor_out, or_out, and_out, logic_out;
  logic         [31:0]  sll_out, srl_out, sra_out, shift_out;
  logic                 is_arith, is_logic, is_shift;
  logic         [31:0]  current_out;  // 1 clock cycle latency for alu

  assign signed_op_1 = opa;
  assign signed_op_2 = opb;

  assign add_out  = op_1 + op_2;
  assign sub_out  = op_1 - op_2;
  assign slt_out  = signed_op_1 < signed_op_2;
  assign sltu_out = op_1 < op_2;

  assign arith_out = (op_type.fn_add  & add_out[31:0]) | 
                     (op_type.fn_sub  & sub_out[31:0]) |
                     (op_type.fn_slt  & slt_out[31:0]) | 
                     (op_type.fn_sltu & sltu_out[31:0]);
  assign is_arith = op_type.fn_add | op_type.fn_sub | 
                    op_type.fn_slt | op_type.fn_sltu;

  assign xor_out  = op_1 ^ op_2;
  assign or_out   = op_1 | op_2;
  assign and_out  = op_1 & op_2;

  assign logic_out = (op_type.fn_xor  & xor_out[31:0]) | 
                     (op_type.fn_or   & or_out[31:0])  |
                     (op_type.fn_and  & and_out[31:0]);
  assign is_logic = op_type.fn_xor | op_type.fn_or | op_type.fn_and;

  assign sll_out  = op_1 << op_2[4:0];
  assign srl_out  = op_1 >> op_2[4:0];
  assign sra_out  = signed_op_1 >>> op_2[4:0];

  assign shift_out = (op_type.fn_sll  & sll_out[31:0]) | 
                     (op_type.fn_srl  & srl_out[31:0]) |
                     (op_type.fn_sra  & sra_out[31:0]);
  assign is_shift = op_type.fn_sll | op_type.fn_srl | op_type.fn_sra;

  assign current_out = is_arith ? arith_out :
                       is_logic ? logic_out :
                       is_shift ? shift_out : 
                       32{1'b0};              // Unreachable

  always_ff @(posedge clock) begin
    alu_out <= current_out;
  end

endmodule


module branch (
  input                 clock;
  input  br_type_t      br_type,
  input  [31:0]         op_1,
  input  [31:0]         op_2,
  output logic          br_out
);

  logic signed [31:0]   signed_op_1, signed_op_2;
  logic                 eq, ne, lt, ge, ltu, geu;
  logic                 current_out;  // 1 clock cycle latency for alu

  assign signed_op_1 = opa;
  assign signed_op_2 = opb;

  assign eq   = op_1 == op_2;
  assign ne   = op_1 != op_2;
  assign lt   = signed_op_1 < signed_op_2;
  assign ge   = signed_op_1 > signed_op_2;
  assign ltu  = op_1 < op_2;
  assign geu  = op_1 > op_2;

  assign current_out = (br_type.br_eq  & eq)  |
                       (br_type.br_ne  & ne)  |
                       (br_type.br_lt  & lt)  |
                       (br_type.br_ge  & ge)  |
                       (br_type.br_ltu & ltu) | 
                       (br_type.br_geu & geu);

  always_ff @(posedge clock) begin
    br_out <= current_out;
  end

endmodule

