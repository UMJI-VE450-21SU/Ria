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
`include "../common/defines.svh"
`define INST_NUM          40
`define INST_WIDTH        32
`define INST_PACK         128
`define INST_INDEX_SIZE   32

module mem_simulator #(
  parameter init_file = "default.mem"
)(
  input                                   clock,
  input                                   req,
  output  reg                             ready,
  input           [`INST_INDEX_SIZE-1:0]  inst_addr,
  output  logic   [`INST_PACK-1:0]        inst_value,
  output  reg                             valid
);

reg                           cal_lock;
reg   [`INST_INDEX_SIZE-1:0]  addr_lock;

reg                           rand_lock;
reg   [3:0]                   rand_val;
logic [3:0]                   rand_next;

reg   [3:0]                   clock_counter;
logic [3:0]                   clock_counter_next;

logic [`INST_PACK-1:0]        inst_value_next;

reg   [`INST_PACK-1:0]        inst_list     [`INST_NUM-1:0];

initial begin
  $readmemh(init_file, inst_list);
  clock_counter_next = 0;
  rand_lock = 0;
end

assign rand_next = rand_lock ? rand_val : ($random % 16 + 1);

assign inst_value_next = inst_list[addr_lock];

assign clock_counter_next = clock_counter + 1;

always_ff @(posedge clock) begin
  if (clock_counter_next >= rand_val) begin
    clock_counter <= 0;
    if (cal_lock) begin
      inst_value <= inst_value_next;
      ready <= 1;
      cal_lock <= 0;
      valid <= (addr_lock < `INST_NUM) ? 1 : 0;
    end
    rand_val <= rand_next;
  end else if (clock_counter_next < rand_val)begin
    clock_counter <= clock_counter_next;
    ready <= 0;
    if (req) begin
      cal_lock <= 1;
      addr_lock <= inst_addr;
      valid <= (inst_addr < `INST_NUM) ? 1 : 0;
    end
  end else begin
    rand_val <= rand_next;
    ready <= 0;
    cal_lock <= 0;
  end
end

endmodule