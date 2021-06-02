//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/02
// Contributor: Zhiyuan Liu
// Reviewer: 
// Module Name: inst_fetch_testbench
// Target Devices: testbench for instruction fetch
// Description: 
// testbench for instruction fetch
// Dependencies: 
// ../memory/mem_sim.sv
//////////////////////////////////////////////////////////////////////////////////
`include "../common/defines.svh"

module instruction_fetch_testbench;
parameter half_clk_cycle = 1;

reg  clock, reset, buffer_full;
reg  [`INST_INDEX_SIZE-1:0]  inst_addr;
wire [`INST_PACK-1:0]        inst_value;
wire [`INST_FETCH_NUM-1:0]   valid;
wire                         ready;

inst_fetch if (
    .clock         (clock),
    .reset         (reset),
    .buffer_full   (buffer_full),
    .inst_addr     (inst_addr),
    .inst_valid    (valid),
    .inst_value    (ready)
  );



always #half_clk_cycle clock = ~clock;

initial begin
  #0 clock = 0; buffer_full = 0;
  #2 reset = 1'b1; inst_addr = 2; //check for reset
  #1 reset=0 ;    
  #20 inst_addr = 4; //check normal memory fetch
  #20 inst_addr = 100;    // Check for memory valid check 
  #2 buffer_full =1;
  #20 inst_addr = 1 ;   // Check for buffer full
  #20 $stop;
end

endmodule