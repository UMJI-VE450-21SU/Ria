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
// ../common/defines.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/defines.svh"

module fetch_buffer(
    input                                   clk,
    input                                   reset,

    input ib_entry_t [`INST_FETCH_NUM-1:0]  insts_in,
    input                                   insts_in_valid,

    output ib_entry_t [`INST_FETCH_NUM-1:0] insts_out,
    output logic                            valid,

    output logic                            full
);

logic [`INST_FETCH_NUM-1:0] full_hub;
logic [`INST_FETCH_NUM-1:0] valid_hub;

fifo #(
    .WIDTH($bits(ib_entry_t)),
    .LOGDEPTH(`IB_ADDR)
)fb_fifo [`INST_FETCH_NUM-1:0] (
    .clk(clk),
    .rst(reset),
    .enq_valid(insts_in_valid),
    .enq_data(insts_in),
    .enq_ready(full_hub),
    .deq_valid(valid_hub),
    .deq_data(insts_out),
    .deq_ready(insts_in_valid)
);

assign full = full_hub[0];
assign valid = valid_hub[0];

endmodule
