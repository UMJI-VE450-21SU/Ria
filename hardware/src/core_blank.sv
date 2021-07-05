`timescale 1ns/1ns

module core_blank (
  input clock,
  input reset,

  // ======= icache related ==================
  input        [31:0]  icache2core_data,
  input                icache2core_data_valid,
  output logic [31:0]  core2icache_addr,

  // ======= dcache related ==================
  input        [63:0]  dcache2core_data,
  input                dcache2core_data_valid,
  output logic [63:0]  core2dcache_data,
  output logic         core2dcache_data_we,
  output logic [3:0]    core2dcache_data_size,
//  input                dcache2core_data_w_ack, // todo: remove this
  output logic [31:0]  core2dcache_addr
);



logic [31:0] icache_cnt_d;
always @(posedge clock) begin
  if (reset || icache_cnt_d >= 10) begin
    icache_cnt_d <= 0;
  end else begin
    icache_cnt_d <= icache_cnt_d + 1;
  end
end

always @(posedge clock) begin
  $display("now the icache data is %8x", icache2core_data);
  if ($time > 500) begin
    $finish;
  end
end

logic [31:0] dcache_cnt_d;
always @(posedge clock) begin
  if (reset) begin
    dcache_cnt_d <= 0;
  end else begin
    dcache_cnt_d <= dcache_cnt_d + 1;
  end
end

assign core2dcache_addr = dcache_cnt_d;

assign core2icache_addr = icache_cnt_d;

logic [31:0] partial;

assign partial = dcache_cnt_d * dcache_cnt_d + icache_cnt_d + 32'h1199_bbbb;

assign core2dcache_data = {partial, partial};

assign core2dcache_data_we = dcache_cnt_d % 2 == 0;

assign core2dcache_data_size = 4 + (dcache_cnt_d % 4 == 0) * 4;

assign core2dcache_addr = dcache_cnt_d % 100;

endmodule
