module mux_4x1 (
  input                             clk,
  input [1:0]                       sel,
  input [(`DATA_WIDTH - 1):0]       data_0,
  input [(`DATA_WIDTH - 1):0]       data_1,
  input [(`DATA_WIDTH - 1):0]       data_2,
  input [(`DATA_WIDTH - 1):0]       data_3,
  output logic [(`DATA_WIDTH - 1):0] data_out
);
  always_ff @( posedge clk ) begin
    case (sel)
      2'b00: data_out <= data_0;
      2'b01: data_out <= data_1;
      2'b10: data_out <= data_2;
      2'b11: data_out <= data_3;
    endcase
  end
endmodule
