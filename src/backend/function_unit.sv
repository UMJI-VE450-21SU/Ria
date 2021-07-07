// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Function Units
// Author:  Li Shi
// Date:    2021/06/21

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

  assign signed_in1 = in1;
  assign signed_in2 = in2;

  assign add  = in1 + in2;
  assign sub  = in1 - in2;
  assign slt  = {32{signed_in1 < signed_in2}};
  assign sltu = {32{in1 < in2}};
  assign lxor = in1 ^ in2;
  assign lor  = in1 | in2;
  assign land = in1 & in2;
  assign sll  = in1 << in2[4:0];
  assign srl  = in1 >> in2[4:0];
  assign sra  = signed_in1 >>> in2[4:0];

  assign fn = uop.alu_type;

  assign result = ({32{fn == ALU_ADD}}  & add [31:0]) |
                  ({32{fn == ALU_SUB}}  & sub [31:0]) |
                  ({32{fn == ALU_SLT}}  & slt [31:0]) |
                  ({32{fn == ALU_SLTU}} & sltu[31:0]) |
                  ({32{fn == ALU_XOR}}  & lxor[31:0]) |
                  ({32{fn == ALU_OR}}   & lor [31:0]) |
                  ({32{fn == ALU_AND}}  & land[31:0]) |
                  ({32{fn == ALU_SLL}}  & sll [31:0]) |
                  ({32{fn == ALU_SRL}}  & srl [31:0]) |
                  ({32{fn == ALU_SRA}}  & sra [31:0]);

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
  output logic        br_taken,
  output [31:0]       br_addr,
  output micro_op_t   br_uop
);

  logic signed [31:0] signed_in1, signed_in2;
  logic               eq, ne, lt, ge, ltu, geu;
  br_type_t           br_type;
  logic               result;
  logic [31:0]        result_addr;

  assign signed_in1 = in1;
  assign signed_in2 = in2;

  assign eq   = in1 == in2;
  assign ne   = in1 != in2;
  assign lt   = signed_in1 < signed_in2;
  assign ge   = signed_in1 > signed_in2;
  assign ltu  = in1 < in2;
  assign geu  = in1 > in2;

  assign br_type = uop.br_type;

  always_comb begin
    br_uop = uop;
    br_uop.br_taken = result;
    br_uop.br_addr = result_addr;
  end

  assign result = ((br_type == BR_EQ)  & eq)  |
                  ((br_type == BR_NE)  & ne)  |
                  ((br_type == BR_LT)  & lt)  |
                  ((br_type == BR_GE)  & ge)  |
                  ((br_type == BR_LTU) & ltu) |
                  ((br_type == BR_GEU) & geu);
  assign result_addr = uop.pc + uop.imm;

  always_ff @(posedge clock) begin
    if (reset) begin
      br_taken <= 0;
      br_addr <= 0;
    end else begin
      br_taken <= result;
      br_addr <= result_addr;
    end
  end

endmodule


module imul (
  input               clock,
  input               reset,
  input  micro_op_t   uop,
  input  [31:0]       in1,
  input  [31:0]       in2,
  output logic [31:0] out                         // 5-cycle latency
);

  logic signed [31:0]          signed_in1, signed_in2; // for signed wire
  logic signed [63:0]          final_product, product_0, product_1, product_2;
  logic [1:0]                  sign;
  reg [`IMUL_LATENCY-1:0]      range;                  // 1 if [63:32]
  reg [`IMUL_LATENCY-1:0][1:0] sign_reg;
  // every imul have a delay of 5 clock cycles

  assign signed_in1 = in1;
  assign signed_in2 = in2;

  always_comb begin
    case (uop.imul_type)
      IMUL_MULHU:   sign = 2'b00;  
      IMUL_MULHSU:  sign = 2'b01;
      default:      sign = 2'b11;
    endcase
    case (sign_reg[`IMUL_LATENCY-1])
      2'b0:    final_product = product_0;
      2'b1:    final_product = product_1;
      default: final_product = product_2;
    endcase
  end

  assign out = range[`IMUL_LATENCY-1]? final_product[63:32]:final_product[31:0];

  always_ff @(posedge clock) begin
    if(reset) begin
      range <= 0;
      sign_reg <= 0;
    end else begin
      range[`IMUL_LATENCY-1:1] <= range[`IMUL_LATENCY-2:0];
      range[0] <= (uop.imul_type != IMUL_MULHU);
      sign_reg[`IMUL_LATENCY-1:1] <= sign_reg[`IMUL_LATENCY-2:0];
      sign_reg[0] <= sign;
    end
  end

  // todo: fix unsigned / signed issue
  imul_unsigned int_mult (
    .clock  (clock),
    .A      (in1),
    .B      (in2),
    .RES    (product_0)
  );
  assign product_1 = product_0;
  assign product_2 = product_0;

endmodule
