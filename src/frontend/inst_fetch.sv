//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Yiqiu Sun
// Reviewer: 
// Module Name: instruction fetch
// Target Devices: fetch the instruction
// Description: 
// instruction fetch
// Dependencies: 
// ../common/defines.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/defines.svh"

module inst_fetch (
  // ======= basic ===========================
    input                               clock,
    input                               reset,
    input                               stall, // stall is effective in the next clock cycle
  // ======= branch predictor related ========
    input        [`INST_WIDTH-1:0]      pc_predicted,
    input                               take_branch,
    input        [`INST_WIDTH-1:0]      branch_pc,
  // ======= cache related ===================
    input        [`INST_PACK-1:0]       Icache2proc_data,
    input                               Icache2proc_data_valid,
    output logic [`INST_WIDTH-1:0]      proc2Icache_addr, // one addr is enough
  // ======= inst buffer related =============
    output ib_entry_t [`INST_FETCH_NUM-1:0]   insts_out,
    output logic                              insts_out_valid
);


reg [`INST_WIDTH-1:0] PC_reg;
logic PC_enable;

assign PC_enable = ~stall & Icache2proc_data_valid;

always_ff @(posedge clock) begin
  if(reset)       PC_reg <= 0; else
  if(take_branch) PC_reg <= branch_pc; else
  if(PC_enable)   PC_reg <= pc_predicted;
end

assign proc2Icache_addr = PC_reg;
assign insts_out_valid = Icache2proc_data_valid & ~stall;

generate
  for(genvar i = 0; i < `INST_FETCH_NUM; i = i + 1) begin
    assign insts_out[i].inst = Icache2proc_data[(i+1)*`INST_WIDTH-1:i*`INST_WIDTH];
    assign insts_out[i].PC   = PC_reg + i*4;
  end
endgenerate

endmodule

