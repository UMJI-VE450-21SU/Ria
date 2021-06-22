// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Ria (Top Module)
// Author:  Li Shi, Jian Shi, Yichao Yuan, Yiqiu Sun, Zhiyuan Liu
// Date:    2021/06/21

module ria (
  input clock,
  input reset,

  // ======= icache related ==================
  input        [31:0]  icache2core_data,
  input                icache2core_data_valid,
  output logic [31:0]  core2icache_addr,

  
);

  inst_fetch inst_fetch (
    .clock (clock),
    .reset (reset),
    .stall        (0),
    .pc_predicted (0),
    .branch_taken (0),
    .branch_pc    (0),
    .icache2core_data (icache2core_data)
  );
  
endmodule