//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/05/31
// Contributor: Jian Shi
// Reviewer: 
// Module Name: mem_simulator_testbench
// Target Devices: testbench for memory simulator
// Description: 
// testbench for a simple memory simulator
// Dependencies: 
// ../memory/mem_sim.sv
//////////////////////////////////////////////////////////////////////////////////
`define INST_PACK         128
`define INST_INDEX_SIZE   32

module mem_simulator_testbench;
parameter half_clk_cycle = 1;

reg  clock, req;
reg  [`INST_INDEX_SIZE-1:0]  inst_addr;
wire [`INST_PACK-1:0]       inst_value;
wire ready, valid;

mem_simulator tb (clock, req, ready, inst_addr, inst_value,  valid);

always #half_clk_cycle clock = ~clock;

initial begin
  #0 clock = 0;
  #2 inst_addr = 2; req = 1;
  #2 req = 0; inst_addr = 100;    // Check for Valid Locker
  #20 inst_addr = 4; req = 1;
  #2 req = 0; inst_addr = 100;    // Check for Valid Locker
  #20 req = 1; inst_addr = 100;   // Check for Valid Judger
  #2 req = 0;
  #20 $stop;
end

endmodule
