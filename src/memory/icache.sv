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

logic ACLK, ARESETn;

MPSOC_S_AXI4_HP_bus axi_bus(ACLK, ARESETn);

AXI_writer_reader axi_writer_reader(
    .clk(clk),
    .ACLK(ACLK),

    .axi_bus(axi_bus.master),

    .mem_read_channel(mem_read_channel.slave)
);

PS_DDR_Controller_wrapper ps_ddr_controller_wrapper(
    .bus(axi_bus.slave),

    .ACLK(ACLK),
    .ARESETn(ARESETn)
);
    
endmodule