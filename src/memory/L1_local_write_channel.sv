
`ifndef L1_LOCAL_WRITE_CHANNEL
`define L1_LOCAL_WRITE_CHANNEL
`include "icache_pkg.sv"

interface L1_local_write_channel;

    logic [WDSZ-1:0] mem_write_req_addr;
    logic mem_write_req_valid;
    logic mem_write_req_ready;

    logic [WDSZ * RBKSZ - 1:0] mem_write_req_data;
    logic mem_write_req_data_valid;
    logic mem_write_req_data_ready;

    logic mem_write_resp;
    logic mem_write_resp_valid;
    logic mem_write_resp_ready;

    modport master (
        output mem_write_req_addr, mem_write_req_valid, mem_write_req_data, 
            mem_write_req_data_valid, mem_write_resp_ready,
        input mem_write_req_ready, mem_write_req_data_ready, mem_write_resp_valid,
            mem_write_resp
    );

    modport slave (
        input mem_write_req_addr, mem_write_req_valid, mem_write_req_data, 
            mem_write_req_data_valid, mem_write_resp_ready,
        output mem_write_req_ready, mem_write_req_data_ready, mem_write_resp_valid,
            mem_write_resp
    );
    
endinterface //L1_local_write_channel

`endif