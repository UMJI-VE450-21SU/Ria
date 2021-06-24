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
  output logic [31:0]  core2icache_addr
);

  logic except;
  logic stall;
// IF
  fb_entry_t [`FECTH_WIDTH-1:0] if_insts_out;
  logic                         if_insts_out_valid;
// FB
  fb_entry_t [`FECTH_WIDTH-1:0] fb_insts_in;
  logic                         fb_insts_in_valid;
  fb_entry_t [`FECTH_WIDTH-1:0] fb_insts_out;
  logic [`FECTH_WIDTH-1:0]      fb_insts_out_valid;
  logic                         fb_full;  // Connect to inst_fetch
//////////////////////////////////////////////////
//                                              //
//              Inst Fetch                      //
//                                              //
//////////////////////////////////////////////////


  inst_fetch if (
    .clock (clock),
    .reset (reset),
    .stall        (stall | fb_full),
    .pc_predicted (0),
    .branch_taken (0),
    .branch_pc    (0),
    .icache2core_data (icache2core_data),
    .icache2core_data_valid(icache2core_data_valid),
    .core2icache_addr(core2icache_addr),
    .insts_out(if_insts_out),
    .insts_out_valid(if_insts_out_valid),
  );

//////////////////////////////////////////////////
//                                              //
//              Fetch Buffer                    //
//                                              //
//////////////////////////////////////////////////

always_ff @(posedge clock) begin
  if(reset | except) begin
    fb_insts_in       <= 0;
    fb_insts_in_valid <= 0;
  end else begin
    fb_insts_in       <= if_insts_out;
    fb_insts_in_valid <= if_insts_out_valid;
  end
end

fetch_buffer fb(
  .clock(clock),
  .reset(reset),

  .insts_in(fb_insts_in),
  .insts_in_valid(fb_insts_in_valid),

  .insts_out(fb_insts_out),
  .valid(fb_insts_out_valid),

  .full(fb_full)  // Connect to inst_fetch
);

//////////////////////////////////////////////////
//                                              //
//               Inst Decode                    //
//                                              //
//////////////////////////////////////////////////
endmodule