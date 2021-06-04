`define MULT_LATENCY 5
module mult (
  input               clock,
  input               reset,
  input  micro_op_t   uop,
  input  [31:0]       in1,
  input  [31:0]       in2,
  output              done,
  output logic [31:0] out
);

wire signed [31:0]  signed_opa, signed_opb;
wire signed [63:0]  final_product,product_0,product_1,product_2;
logic [1:0]         sign;
reg                 range; // 1 if [63:32]
reg [2:0]           cnt;
reg [1:0]           sign_reg;
logic               
// every mult have a delay of 5 clock cycles

assign signed_opa = in1;
assign signed_opb = in2;

always_comb begin
    case (uop.mult_type_t)
        MULHU:      sign = 2'b00;  
        MULHSU:     sign = 2'b01;
        default:    sign = 2'b11;
    endcase
    case (sign_reg)
        2'b0:   final_product = product_0;
        2'b1:   final_product = product_1;
        default:final_product = product_2;
    endcase
end

always_ff @( clock ) begin : blockName
    if (uop.valid) begin
        cnt <= 0;
        range <= (uop.mult_type_t ~= MULHU);
        sign_reg <= sign;
    else
        if(cnt < `MULT_LATENCY - 1) begin
            cnt <= cnt + 1;
        end
    end
end

assign done = (cnt == `MULT_LATENCY);
assign out = range? final_product[63:32]:final_product[31:0];

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
    .A(in1),
    .B(in2),
    .SCLR(reset),//sync clear
    .CE(sign[1] & sign[0]),
    .P(product_2)
);

endmodule