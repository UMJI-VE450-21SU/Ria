// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Top (for verilator simulation)
// Author:  Li Shi, Jian Shi, Yichao Yuan, Yiqiu Sun, Zhiyuan Liu
// Date:    2021/06/21

`include "src/common/micro_op.svh"

module top (
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
  output mem_size_t    core2dcache_data_size,
  output logic [31:0]  core2dcache_addr
);

  core core (
    .clock                  (clock),
    .reset                  (reset),
    .icache2core_data       (icache2core_data),
    .icache2core_data_valid (icache2core_data_valid),
    .core2icache_addr       (core2icache_addr),
    .dcache2core_data       (dcache2core_data),
    .dcache2core_data_valid (dcache2core_data_valid),
    .core2dcache_data       (core2dcache_data),
    .core2dcache_data_we    (core2dcache_data_we),
    .core2dcache_data_size  (core2dcache_data_size),
    .core2dcache_addr       (core2dcache_addr)
  );

  initial begin
    if ($test$plusargs("trace") != 0) begin
      $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
      $dumpfile("logs/vlt_dump.vcd");
      $dumpvars();
    end
    $display("[%0t] Model running...\n", $time);
   end

endmodule
