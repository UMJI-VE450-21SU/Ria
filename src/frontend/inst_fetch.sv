//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Zhiyuan Liu
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
    input                                        clock,
    input                                        reset,
    input                                        buffer_full,
    input          [`INST_INDEX_SIZE-1:0]        inst_addr,
    output  logic  [`INST_FETCH_NUM-1:0]         inst_valid,
    output  logic  [`INST_PACK-1:0]              inst_value
);

  logic req;
  logic mem_valid;
  logic ready;

  mem_simulator mem (
    .clock      (clock),
    .req        (req),
    .inst_addr  (inst_addr),
    .inst_value (inst_value),
    .valid      (mem_valid),
    .ready      (ready)
  );

  always_ff @ (posedge clock) begin
    //TODO: change the reset logic, assume reset with real pc value 
    //TODO: 16bits instruction 
    
    //decides req signal 
    if ( (reset | ready) & ~buffer_full) begin
      req <= 1'b1;
    end else begin
      req <= 1'b0;
    end
  end

  generate
    for (genvar i = 0; i < `INST_FETCH_NUM; i++) begin
      assign inst_valid[i] = (inst_addr[3:2] <= i)  & mem_valid & ~buffer_full & ready ;  
    end
  endgenerate
    
endmodule
