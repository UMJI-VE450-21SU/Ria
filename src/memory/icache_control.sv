`include "icache_pkg.sv"


module icache_control (
    input logic clk,

    // signals for top level signal
    input addr_t i_addr,
    input logic i_addr_valid,
    output logic o_addr_ready, 

    output logic o_result_valid,

    /////// data line control signals ///////
    output logic d_re, // read enable
    output logic wrap, // wrap or not

    output addr_t d_waddr, // when doing allocation, use this address
    output word_t [WBKSZ-1:0] d_wdata, // when doing allocation, use this to supply data
    output logic data_we, // data write enable

    /////// overhead control signals ///////
    output logic overhead_re,
    input overhead_t [1:0] overhead_out[WAYS],

    output laddr_t laddr_w,
    output logic [WAYS-1:0] overhead_we,
    output overhead_t overhead_w
);

    // TODO: implementation
    
endmodule