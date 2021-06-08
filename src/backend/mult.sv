module mult (
  input               clock,
  input               reset,
  input  micro_op_t   uop,
  input  [31:0]       in1,
  input  [31:0]       in2,
  output logic [31:0] out // have a delay of 5 cycles
);

wire signed [31:0]      signed_opa, signed_opb; // for signed wire
wire signed [63:0]      final_product,product_0,product_1,product_2;
logic [1:0]             sign;
reg [`MULT_LATENCY-1:0] range; // 1 if [63:32]
reg [`MULT_LATENCY-1:0] sign_reg [1:0];
// every mult have a delay of 5 clock cycles

assign signed_opa = in1;
assign signed_opb = in2;

always_comb begin
    case (uop.mult_type_t)
        MULHU:      sign = 2'b00;  
        MULHSU:     sign = 2'b01;
        default:    sign = 2'b11;
    endcase
    case (sign_reg[`MULT_LATENCY-1])
        2'b0:   final_product = product_0;
        2'b1:   final_product = product_1;
        default:final_product = product_2;
    endcase
end

assign out = range[`MULT_LATENCY-1]? final_product[63:32]:final_product[31:0];

always_ff @(posedge clock ) begin
    if(reset) begin
        range <= 0;
        sign_reg <= 0;
    else
        range[`MULT_LATENCY-1:1] <= range[`MULT_LATENCY-2:0];
        range[0] <= (uop.mult_type_t ~= MULHU);
        sign_reg[`MULT_LATENCY-1:1] <= sign_reg[`MULT_LATENCY-2:0];
        sign_reg[0] <= sign;
    end
end

// signed bits: 00
mult_gen_0 int_mult(
    .CLK(clock),
    .A(in1),
    .B(in2),
    .SCLR(reset),//sync clear
    .CE(~sign[1] & ~sign[0]),
    .P(product_0)
);

// signed bits: 01
mult_gen_1 int_mult_1(
    .CLK(clock),
    .A(in1),
    .B(in2),
    .SCLR(reset),//sync clear
    .CE(~sign[1] & sign[0]),
    .P(product_1)
);

// signed bits: 11
mult_gen_0 int_mult_0(
    .CLK(clock),
    .A(signed_opa),
    .B(signed_opb),
    .SCLR(reset),//sync clear
    .CE(sign[1] & sign[0]),
    .P(product_2)
);

endmodule