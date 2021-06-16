module pipe_0 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output micro_op_t uop_completed,
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

  always_ff @(posedge clock) begin
    if (reset) begin
      uop_completed <= 0;
    end else begin
      uop_completed <= uop;
    end
  end

  assign out = ({32{uop.fu_code == FU_ALU}} & alu_out) |
               ({32{uop.fu_code == FU_BR}} & {32{br_out}});

  assign busy = 1'b0;

endmodule


module pipe_1 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output micro_op_t uop_completed,
  output [31:0]     out,
  output            busy,
)

  wire                                  input_valid = uop.valid;
  logic micro_op_t [`IMUL_LATENCY-1:0]  uop_fifo;
  logic [31:0]                          alu_out, imul_out;

  always_ff @(posedge clock) begin
    if (reset) begin
      uop_fifo <= 0;
    end else begin
      if (input_valid & (uop.fu_code == FU_ALU)) begin
        uop_fifo[0] <= uop;
      end else begin
        uop_fifo[0] <= uop_fifo[1];
      end
      for (int i = 1; i < `IMUL_LATENCY - 1; i++) begin
        uop_fifo[i] <= uop_fifo[i + 1];
      end
      if (input_valid & (uop.fu_code == FU_IMUL)) begin
        uop_fifo[`IMUL_LATENCY - 1] <= uop;
      end else begin
        uop_fifo[`IMUL_LATENCY - 1] <= 0;
      end
    end
  end

  alu alu_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (alu_out)
  );

  imul imul_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (imul_out)
  );

  assign out = ({32{uop_fifo[0].fu_code == FU_ALU}}  & alu_out) |
               ({32{uop_fifo[0].fu_code == FU_IMUL}} & imul_out});

  assign busy = 1'b0;

endmodule
