`include "icache_pkg.sv"
// [Description]
// Icache's highest level design.
//
// when addr_ready is asserted, icache will be in the state to accept
// read address. 
//
// when result_valid is asserted, the data is output. 
// when cache hit, result will be output with one cycle latency.
// when cache miss, result will be output with multi cycle latency. 
//
// result_valid will be asserted when the whole block of memory is valid.
// 
// [Notes - cannot be notice from the FSM diagram]
// After result_valid is asserted, it will immediately start another
// ready. When a cache miss occur, the supplied input should hold
// until it get a hit for that address.
//
// This is an icache so there is only read allocation, which simplifies the 
// control logic.

module icache (
    input clk,
    input rst,

    // interface to the processor
    input addr_t addr,
    input logic addr_valid,
    output logic addr_ready,

    output word_t [RBKSZ-1:0] result,
    output logic result_valid // i.e. miss or not

);

logic wrap;
assign wrap = addr.waddr > (WNUM - RBKSZ);

//  cache data's signals
logic data_re;
word_t [RBKSZ-1:0] d_rdata;

addr_t d_waddr;
word_t [WBKSZ-1:0] d_wdata;
logic data_we;

cache_mem_data cache_data ( 
    .clk(clk),

    .laddra(addr.laddr),
    .waddra(addr.waddr),
    .wrap(wrap),
    .re(data_re), 
    .dout(result), // -> output

    .laddrb(d_waddr.laddr),
    .waddrb(d_waddr.waddr),
    .din(d_wdata),
    .we(data_we)
);

// cache overhead's signals
logic overhead_re;
overhead_t [1:0] overhead_out;

laddr_t overhead_laddr_w;
logic overhead_we;
overhead_t overhead_in;

cache_mem_overhead cache_overhead (
    .clk(clk),

    .laddra(addr.laddr),
    .re(overhead_re),
    .wrap(wrap),
    .overhead_out(overhead_out),

    .laddrb(overhead_laddr_w),
    .overhead_in(overhead_in),
    .we(overhead_we)
);

logic [WDSZ-1:0] mem_read_req_addr;
logic mem_read_req_valid;
logic mem_read_req_ready;

logic [WBKSZ * WDSZ - 1: 0] mem_read_resp_data;
logic mem_read_resp_valid;
logic mem_read_resp_ready;

icache_control cache_control (
    // cache control gives all the 6 signals
    .clk(clk),
    .rst(rst),

    .cache_addr(addr),
    .cache_addr_valid(addr_valid),
    .cache_addr_ready(addr_ready),

    .cache_result_valid(result_valid),

    .wrap(wrap),
    /////// data line control signals ///////
    .data_re(data_re),

    .data_waddr(d_waddr),
    .data_wdata(d_wdata),
    .data_we(data_we),

    /////// overhead control signals ///////
    .overhead_re(overhead_re),
    .overhead_out(overhead_out),
    .overhead_laddr_w(overhead_laddr_w),
    .overhead_we(overhead_we),
    .overhead_w(overhead_in),

    /////// read channel to the rwter ///////
    .mem_read_req_addr(mem_read_req_addr),
    .mem_read_req_ready(mem_read_req_ready),
    .mem_read_req_valid(mem_read_req_valid),

    .mem_read_resp_data(mem_read_resp_data),
    .mem_read_resp_valid(mem_read_resp_valid),
    .mem_read_resp_ready(mem_read_resp_ready)
);

////// interface between AXI //////
logic [5:0] ARID;
logic [48:0] ARADDR;
logic [7:0] ARLEN;
logic [2:0] ARSIZE;
logic [1:0] ARBURST;

logic ARLOCK;
logic [3:0] ARCACHE;
logic [2:0] ARPROT;
logic [3:0] ARQOS;
logic ARUSER;

logic ARVALID;
logic ARREADY;

// R channel (RESP, S -> M), IP lists 6 signals
logic [5:0] RID; // no use
logic [63:0] RDATA;
logic [1:0] RRESP; // no use

logic RLAST;

logic RVALID;
logic RREADY;

AXI_reader axi_writer_reader(

    // channel to the control
    .mem_read_req_addr(mem_read_req_addr),
    .mem_read_req_ready(mem_read_req_ready),
    .mem_read_req_valid(mem_read_req_valid),

    .mem_read_resp_data(mem_read_resp_data),
    .mem_read_resp_valid(mem_read_resp_valid),
    .mem_read_resp_ready(mem_read_resp_ready),


    // channel to the AXI
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
    .RRESP(RRESP),

    .RLAST(RLAST),

    .RVALID(RVALID),
    .RREADY(RREADY)
);

logic axi_clk;
assign axi_clk = clk;
logic axi_rstn;
assign axi_rstn = ~rst;


axi_vip_0 axi_slave_verification (
  .aclk(axi_clk),
  .aresetn(axi_rstn),
  .s_axi_awid(0),
  .s_axi_awaddr(0),
  .s_axi_awlen(0),
  .s_axi_awsize(0),
  .s_axi_awburst(0),
  .s_axi_awlock(0),
  .s_axi_awcache(0),
  .s_axi_awprot(0),
  .s_axi_awregion(0),
  .s_axi_awqos(0),
  .s_axi_awuser(0),
  .s_axi_awvalid(0),
  .s_axi_awready(),
  .s_axi_wdata(0),
  .s_axi_wstrb(0),
  .s_axi_wlast(0),
  .s_axi_wvalid(0),
  .s_axi_wready(),
  .s_axi_bid(),
  .s_axi_bresp(),
  .s_axi_bvalid(),
  .s_axi_bready(0),
  .s_axi_arid(ARID),
  .s_axi_araddr(ARADDR),
  .s_axi_arlen(ARLEN),
  .s_axi_arsize(ARSIZE),
  .s_axi_arburst(ARBURST),
  .s_axi_arlock(ARLOCK),
  .s_axi_arcache(ARCACHE),
  .s_axi_arprot(ARPROT),
  .s_axi_arregion(0),
  .s_axi_arqos(ARQOS),
  .s_axi_aruser(ARUSER),
  .s_axi_arvalid(ARVALID),
  .s_axi_arready(ARREADY),
  .s_axi_rid(RID),
  .s_axi_rdata(RDATA),
  .s_axi_rresp(RRESP),
  .s_axi_rlast(RLAST),
  .s_axi_rvalid(RVALID),
  .s_axi_rready(RREADY)
);
    
endmodule