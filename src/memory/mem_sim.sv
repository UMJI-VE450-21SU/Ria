//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/05/22
// Contributor: Jian Shi
// Reviewer: 
// Module Name: mem_simulator
// Target Devices: memory simulator
// Description: 
// a simple memory simulator
// Dependencies: 
// ../common/defines.svh
//////////////////////////////////////////////////////////////////////////////////

`define INST_NUM          100
`define INST_WIDTH        32
`define INST_INDEX_SIZE   5   // log2(INST_WIDTH)

module mem_simulator #(
  parameter init_file = "../../testbench/inst/default.mem"
)(
  input                                   clock,
  input           [`INST_INDEX_SIZE-1:0]  inst_addr,
  output  logic   [`INST_WIDTH-1:0]       inst_value,
  output  logic                           validation
);

logic validation_next;
logic [`INST_WIDTH-1:0]       inst_value_next;

reg   [`INST_WIDTH-1:0]       inst_list     [`INST_NUM-1:0];

initial begin
  $readmemh(init_file, inst_list);
end

assign validation = (inst_addr < `INST_NUM) ? 1 : 0;

always_ff @(posedge clock) begin
  inst_value <= inst_list[inst_addr];
end

endmodule