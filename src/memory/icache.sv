`include "icache_pkg.sv"
`include "MPSOC_S_AXI4_HP_bus.sv"
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

module icache (
    input clk,

    input addr_t addr,
    input logic addr_valid,
    output logic addr_ready,

    output word_t [RBKSZ-1:0] result,
    output logic result_valid // i.e. miss or not
);

logic data_re, wrap;
addr_t d_waddr;
word_t [WBKSZ-1:0] d_wdata;
logic data_we;

logic overhead_re;
logic [WAYS-1:0] overhead_we;
overhead_t [1:0] overhead_out[WAYS];
laddr_t overhead_laddr_w;
overhead_t overhead_in;

icache_control cache_control (
    .clk(clk),

    .i_addr(addr),
    .i_addr_valid(addr_valid),
    .o_addr_ready(addr_ready),

    .o_result_valid(result_valid),

    /////// data line control signals ///////
    .d_re(data_re),
    .wrap(wrap),

    .d_waddr(d_waddr),
    .d_wdata(d_wdata),
    .data_we(data_we),

    /////// overhead control signals ///////
    .overhead_re(overhead_re),
    .overhead_out(overhead_out),
    .laddr_w(overhead_laddr_w),
    .overhead_we(overhead_we),
    .overhead_w(overhead_in)
);

cache_mem_data cache_data ( 
    .clk(clk),

    .laddra(addr.laddr),
    .waddra(addr.waddr),
    .wrap(wrap),
    .re(data_re),
    .dout(result), // direct map

    .laddrb(d_waddr.laddr),
    .waddrb(d_waddr.waddr),
    .din(d_wdata),
    .we(data_we)
);

cache_mem_overhead cache_overhead (
    .clk(clk),

    .laddra(addr.laddr),
    .wrap(wrap),
    .re(overhead_re),
    .overhead_out(overhead_out),

    .laddrb(overhead_laddr_w),
    .overhead_in(overhead_in),
    .we(overhead_we)
);

logic ACLK, ARESTn;

MPSOC_S_AXI4_HP_bus axi_bus(ACLK, ARESTn);

AXI_writer_reader axi_writer_reader(
    .clk(clk),

    .bus(axi_bus.master)
);

PS_DDR_Controller_wrapper ps_ddr_controller_wrapper(
    .bus(axi_bus.slave),

    .ACLK(clk),
    .ARESTn(ARESTn)
);

    
endmodule