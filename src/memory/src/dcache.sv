`include "dcache_pkg.sv"
`include "common_pkg.sv"
`include "AXI_bus_pkg.sv"
import common_pkg::word_t;
import AXI_bus_pkg::axi_word_t;
// [Description]
// At this stage, I will only try to implement a single port cache
// with the AXI unverified I do not want to make the things even 
// harder
//
// [NOTE] Unlike the icache, the dcache do not support unaligned read/
// write

module dcache (
    ////////////////////////////////////////////////////////////////////////////////
    // dcache to CPU interface
    ////////////////////////////////////////////////////////////////////////////////
    input logic clk,
    input logic rst,

    // Request channel
    // interface to the processor
    input word_t cache_req_addr,
    input logic [3:0] cache_req_wstrobe,    // enable ? bytes to be written
                                            // if |wstrobe is 0, then it is a read
                                            // request
    input word_t cache_req_data_in,
    input logic cache_req_valid,
    output logic cache_req_ready,

    output word_t cache_resp_result, 
    // read for two word because of double
    output logic cache_result_valid,
    input logic cache_result_ready,


    ////////////////////////////////////////////////////////////////////////////////
    // dcache AXI channel 
    ////////////////////////////////////////////////////////////////////////////////
    // AW channel (REQ, M -> S), IP lists 12 signals
    output logic [5:0] AWID,
    output logic [48:0] AWADDR,
    output logic [7:0] AWLEN,
    output logic [2:0] AWSIZE,
    output logic [1:0] AWBURST,

    output logic AWLOCK,
    output logic [3:0] AWCACHE,
    output logic [2:0] AWPROT,
    output logic [3:0] AWQOS,
    output logic AWREGION, // not listed by XILINX IP
    output logic AWUSER,

    output logic AWVALID,
    input logic AWREADY,

    // W channel (DRESP, M -> S), IP lists 5 signals
    output logic [63:0] WDATA,
    output logic [7:0] WSTRB,

    output logic WLAST,
    output logic WUSER, // not listed by XILINX IP

    output logic WVALID,
    input logic WREADY,

    // B channel (RESP, S -> M), IP uses 4 signals
    input logic [5:0] BID,   // no use
    input logic [1:0] BRESP, // no use

    input logic BUSER, // not listed by XILINX IP

    input logic BVALID,
    output logic BREADY,

    // AR channel
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

    input logic RLAST, // no use

    input logic RVALID,
    output logic RREADY
);
import dcache_pkg::*;
import common_pkg::*;
import AXI_bus_pkg::*;

logic [dcache_pkg::LINEBITS-1:0] wb_req_data;
addr_t wb_req_addr;
logic wb_req_valid;
logic wb_req_ready;

logic wb_resp_valid;
logic wb_resp_ready;

addr_t allocate_req_addr;
logic allocate_req_valid;
logic allocate_req_ready;

logic [dcache_pkg::LINEBITS-1:0] allocate_resp_data;
logic allocate_resp_valid;
logic allocate_resp_ready;

dcache_main dcache_main (
    .clk(clk),
    .rst(rst),

    .cache_req_addr(cache_req_addr),
    .cache_req_wstrobe(cache_req_wstrobe),
    .cache_req_data_in(cache_req_data_in),
    .cache_req_valid(cache_req_valid),
    .cache_req_ready(cache_req_ready),

    .cache_resp_result(cache_resp_result),
    .cache_result_valid(cache_result_valid),
    .cache_result_ready(cache_result_ready),

    .wb_req_data(wb_req_data),
    .wb_req_addr(wb_req_addr),
    .wb_req_valid(wb_req_valid),
    .wb_req_ready(wb_req_ready),

    .wb_resp_valid(wb_resp_valid),
    .wb_resp_ready(wb_resp_ready),

    .allocate_req_addr(allocate_req_addr),
    .allocate_req_valid(allocate_req_valid),
    .allocate_req_ready(allocate_req_ready),

    .allocate_resp_data(allocate_resp_data),
    .allocate_resp_valid(allocate_resp_valid),
    .allocate_resp_ready(allocate_resp_ready)
);

write_back_unit write_back_unit (
    .clk(clk),
    .rst(rst),

    .wb_req_data(wb_req_data),
    .wb_req_addr(wb_req_addr),
    .wb_req_valid(wb_req_valid),
    .wb_req_ready(wb_req_ready),

    .wb_resp_valid(wb_resp_valid),
    .wb_resp_ready(wb_resp_ready),

    .AWID(AWID),
    .AWADDR(AWADDR),
    .AWLEN(AWLEN),
    .AWSIZE(AWSIZE),
    .AWBURST(AWBURST),
    
    .AWLOCK(AWLOCK),
    .AWCACHE(AWCACHE),
    .AWPROT(AWPROT),
    .AWQOS(AWQOS),
    .AWREGION(AWREGION),
    .AWUSER(AWUSER),

    .AWVALID(AWVALID),
    .AWREADY(AWREADY),

    .WDATA(WDATA),
    .WSTRB(WSTRB),

    .WLAST(WLAST),
    .WUSER(WUSER),

    .WVALID(WVALID),
    .WREADY(WREADY),
    
    .BID(BID),
    .BRESP(BRESP),

    .BUSER(BUSER),

    .BVALID(BVALID),
    .BREADY(BREADY)
);

allocate_unit allocate_unit (
    .clk(clk),
    .rst(rst),

    .allocate_req_addr(allocate_req_addr),
    .allocate_req_valid(allocate_req_valid),
    .allocate_req_ready(allocate_req_ready),
    
    .allocate_resp_data(allocate_resp_data),
    .allocate_resp_valid(allocate_resp_valid),
    .allocate_resp_ready(allocate_resp_ready),

    .ARID(ARID),
    .ARADDR(ARADDR),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),

    .ARLOCK(ARLOCK),
    .ARCACHE(ARCACHE),
    .ARPROT(ARPROT),
    .ARQOS(ARQOS),
    .ARUSER(ARUSER),

    .ARVALID(ARVALID),
    .ARREADY(ARREADY),

    // R channel (RESP, S -> M), IP lists 6 signals
    .RID(RID), // no use
    .RDATA(RDATA),
    .RRESP(RRESP), // no use

    .RLAST(RLAST), // no use

    .RVALID(RVALID),
    .RREADY(RREADY)
);
    
endmodule