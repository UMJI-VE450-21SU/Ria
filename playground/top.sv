`define DATA_WIDTH 32

module top
(
  input                             clk,
  input [1:0]                       sel,
  input [(`DATA_WIDTH - 1):0]       data_0,
  input [(`DATA_WIDTH - 1):0]       data_1,
  input [(`DATA_WIDTH - 1):0]       data_2,
  input [(`DATA_WIDTH - 1):0]       data_3,
  output wire [(`DATA_WIDTH - 1):0] data_out
);

  mux_4x1 mux_4x1 (
    .clk      (clk),
    .sel      (sel),
    .data_0   (data_0),
    .data_1   (data_1),
    .data_2   (data_2),
    .data_3   (data_3),
    .data_out (data_out)
  );

  initial begin
    if ($test$plusargs("trace") != 0) begin
        $display("[%0t] Tracing to logs/dump.vcd...\n", $time);
        $dumpfile("logs/dump.vcd");
        $dumpvars();
    end
    $display("[%0t] Model running...\n", $time);
  end

endmodule
