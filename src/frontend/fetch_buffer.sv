//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Zhiyuan Liu
// Reviewer: 
// Module Name: 
// Target Devices: instruction buffer
// Description: 
// instruction buffer
// Dependencies: 
// ../common/micro_op.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module fetch_buffer(
    input                                   clk,
    input                                   reset,

    input ib_entry_t [`INST_FETCH_NUM-1:0]  insts_in,
    input                                   insts_in_valid,

    output ib_entry_t [`INST_FETCH_NUM-1:0] insts_out,
    output logic                            valid,

    output logic                            full
);

fifo #(
    .WIDTH($bits(ib_entry_t)*`INST_FETCH_NUM),
    .LOGDEPTH(`IB_ADDR)
)fb_fifo(
    .clk(clk),
    .rst(reset),
    .enq_valid(insts_in_valid),
    .enq_data(insts_in),
    .enq_ready(full),
    .deq_valid(valid),
    .deq_data(insts_out),
    .deq_ready(insts_in_valid)
);
    
endmodule
