// [Description]
// At this stage, only convert the cache's allocation requests to AXI request

`include "dcache_pkg.sv"

module AXI_reader (
    // input axi_clk,
    // input axi_rstn,

    /////// interface between cache ///////
    input word_t mem_read_req_addr,
    input logic mem_read_req_valid,
    output logic mem_read_req_ready,

    output logic [AXI_WIDTH-1:0] mem_read_resp_data,
    output logic mem_read_resp_valid,
    input logic mem_read_resp_ready,

    ////// interface between AXI //////
    output logic [5:0] ARID,
    output logic [48:0] ARADDR,
    output logic [7:0] ARLEN,
    output logic [2:0] ARSIZE,
    output logic [1:0] ARBURST,

    output logic ARLOCK,
    output logic [3:0] ARCACHE,
    output logic [2:0] ARPROT,
    output logic [3:0] ARQOS,
    output logic ARUSER,

    output logic ARVALID,
    input logic ARREADY,

    // R channel (RESP, S -> M), IP lists 6 signals
    input logic [5:0] RID, // no use
    input logic [63:0] RDATA,
    input logic [1:0] RRESP, // no use

    input logic RLAST,

    input logic RVALID,
    output logic RREADY
);

// no need for out of order 
assign ARID = 0;
assign ARADDR[31:0] = mem_read_req_addr;
assign ARADDR[48:32] = 0;
assign ARLEN = 8'($clog2(ALLOC_BEATS));
assign ARSIZE = 3'(AXI_WIDTH / 8);
assign ARBURST = 2'b01; // INCR

assign ARLOCK = 0;
assign ARCACHE = 0; 
assign ARPROT = 0;
assign ARQOS = 0;
assign ARUSER = 0;

assign ARVALID = mem_read_req_valid;
assign mem_read_req_ready = ARREADY;

assign RREADY = mem_read_resp_ready;
assign mem_read_resp_valid = RVALID;
assign mem_read_resp_data = RDATA;

endmodule