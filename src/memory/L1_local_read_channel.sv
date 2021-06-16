`ifndef L1_LOCAL_READ_CHANNEL
`define L1_LOCAL_READ_CHANNEL
`include "icache_pkg.sv"

interface L1_local_read_channel;

    // L1 send a read request with WNUM / WBKSZ beats
    logic [WDSZ-1:0] req_addr;
    logic req_valid;
    logic req_ready;

    // the master should expect WNUM / WBKSZ beats
    // i.e. maintain WNUM / WBKSZ cycles ready and then disassert
    // ready
    logic [WBKSZ * WDSZ-1:0] resp_data;
    logic resp_valid;
    logic resp_ready;

    modport master (
        input req_ready, resp_data, resp_valid,
        output req_addr, req_valid, resp_ready
    );

    modport slave (
        output req_ready, resp_data, resp_valid,
        input req_addr, req_valid, resp_ready
    );
    
endinterface //L1_local_read_channel

`endif