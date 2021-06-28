// [Description]
// the main part of the icache
`include "common_pkg.sv"
`include "icache_pkg.sv"

import common_pkg::word_t;
import icache_pkg::addr_t;

module icache_main (
    ////////////////////////////////////////////////////////////////////////////////
    // dcache to CPU interface
    ////////////////////////////////////////////////////////////////////////////////
    input logic clk,
    input logic rst,

    // Request channel
    // interface to the processor
    input addr_t cache_req_addr,
    input logic cache_req_valid,
    output logic cache_req_ready,

    output word_t cache_resp_result[icache_pkg::RBKSZ], 
    // read for two word because of double
    output logic cache_result_valid,
    input logic cache_result_ready,

    ////////////////////////////////////////////////////////////////////////////////
    // dcache to write back unit
    ////////////////////////////////////////////////////////////////////////////////
    output logic [icache_pkg::LINEBITS-1:0] wb_req_data,
    output addr_t wb_req_addr,
    output logic wb_req_valid,
    input logic wb_req_ready,

    input logic wb_resp_valid,
    output logic wb_resp_ready,

    ////////////////////////////////////////////////////////////////////////////////
    // dcache to allocation unit
    ////////////////////////////////////////////////////////////////////////////////
    output addr_t allocate_req_addr,
    output logic allocate_req_valid,
    input logic allocate_req_ready,

    input logic [icache_pkg::LINEBITS-1:0] allocate_resp_data,
    input logic allocate_resp_valid,
    output logic allocate_resp_ready
);
import icache_pkg::*;
import common_pkg::*;

logic cache_req_fire;
assign cache_req_fire = cache_req_ready & cache_req_valid;

logic wb_req_fire, wb_resp_fire;
assign wb_req_fire = wb_req_valid & wb_req_ready;
assign wb_resp_fire = wb_resp_valid & wb_resp_ready;

logic allocate_req_fire, allocate_resp_fire;
assign allocate_req_fire = allocate_req_valid & allocate_req_ready;
assign allocate_resp_fire = allocate_resp_ready & allocate_resp_valid;

////////////////////////////////////////////////////////////////////////////////
// cache data
////////////////////////////////////////////////////////////////////////////////


laddr_t data_laddra;
waddr_t data_waddra;
logic data_ena;
logic [DATA_DATA_WIDTH-1:0] data_dina;

logic [DATA_ADDR_WIDTH-1:0] data_addrb;
logic data_enb;
logic [DATA_DATA_WIDTH-1:0] data_doutb;

icache_mem cache_data (
   .clk(clk), // common clock

   .laddra(data_laddra),
   .waddra(data_waddra),
   .wea(data_wea),
   .ena(data_ena),
   .dina(data_dina),

   .addrb(data_addrb),
   .enb(data_enb),
   .doutb(data_doutb)
);

////////////////////////////////////////////////////////////////////////////////
// cache overhead
////////////////////////////////////////////////////////////////////////////////


logic [dcache_pkg::OVERHEAD_ADDR_WIDTH-1:0] overhead_addra;
logic overhead_ena;
overhead_t overhead_dina;

logic [dcache_pkg::OVERHEAD_ADDR_WIDTH-1:0] overhead_addrb;
logic overhead_enb;
overhead_t overhead_doutb;

dcache_overhead cache_overhead (
   .clk(clk), // common clock

   .addra(overhead_addra),
   .ena(overhead_ena),
   .dina(overhead_dina),

   .addrb(overhead_addrb),
   .enb(overhead_enb),
   .doutb(overhead_doutb)
);

assign overhead_enb = 1;

////////////////////////////////////////////////////////////////////////////////
// delayed write
////////////////////////////////////////////////////////////////////////////////
logic [3:0] delayed_strobe_val;
word_t delayed_write_data;
addr_t delayed_write_addr;
logic delayed_write_exist;
always_ff @( posedge clk ) begin : delayed_write
    if (cache_req_write_fire) begin
        delayed_strobe_val <= cache_req_wstrobe; 
        delayed_write_data <= cache_req_data_in;
        delayed_write_addr <= cache_req_addr;
        delayed_write_exist <= 1;
    end 
end

logic [$bits(wb_req_data)-1:0] delayed_write_alternative;
assign delayed_write_alternative = {WNUM{delayed_write_data}};
logic [$bits(wb_req_data)/8-1:0] delayed_write_mask;
always_comb begin
    for (integer i = 0; i < $bits(wb_req_data)/8; i = i + 1) begin
        delayed_write_mask[i] = (4'(i / WDSZ) == delayed_write_addr.waddr) &&
            delayed_strobe_val[i % (WDSZ/8)]; 
    end
end

////////////////////////////////////////////////////////////////////////////////
// last req 
////////////////////////////////////////////////////////////////////////////////
addr_t last_cache_req_addr;
logic [common_pkg::WDSZ/8-1:0] last_cache_req_wstrobe;
word_t last_cache_req_data_in;
logic last_cache_req_exist;
always_ff @( posedge clk ) begin : last_req
    if (cache_req_fire) begin
        last_cache_req_addr <= cache_req_addr;
        last_cache_req_wstrobe <= cache_req_wstrobe;
        last_cache_req_data_in <= cache_req_data_in;
        last_cache_req_exist <= 1;
    end 
end

////////////////////////////////////////////////////////////////////////////////
// state machine
////////////////////////////////////////////////////////////////////////////////
typedef enum { HIT, WB, ALLOC, READ } state_t;
state_t state_val, state_next;
always_ff @( posedge clk ) begin : FSM_state
    if (rst) begin
        state_val <= HIT;
    end else begin
        state_val <= state_next;
    end
end

always_comb begin : FSM_transit
    state_val = state_next;
    wb_req_valid = 0;
    allocate_req_valid = 0;
    case (state_val)
    HIT: begin
        if (!cache_result_valid) begin
            if (overhead_doutb.dirty) begin
                state_next = WB;
                wb_req_valid = 1;
            end else begin
                state_next = ALLOC; 
                allocate_req_valid = 1;
            end
        end   
    end
    WB: begin
       if (wb_resp_fire) begin
           state_next = ALLOC;
           allocate_req_valid = 1;
       end 
    end
    ALLOC: begin
       if (allocate_resp_fire) begin
           state_next = READ;
       end 
    end
    READ: begin
        state_next = HIT; 
    end
    endcase

end

logic [$bits(data_doutb)-1:0] mem_data_shift;
assign mem_data_shift = data_doutb >> (last_cache_req_addr.waddr * WDSZ);

assign cache_resp_result = mem_data_shift[WDSZ-1:0];

assign cache_req_ready = (state_val == HIT);
assign cache_result_valid = 
    (last_cache_req_exist && ~(|last_cache_req_wstrobe)) && 
    (overhead_doutb.valid) && (state_val == HIT);


always_comb begin
   for (integer i = 0; i < $bits(wb_req_data); i = i + 1) begin
        wb_req_data[i] = delayed_write_mask[i] ?
            delayed_write_alternative[i] : data_doutb[i];
   end 
end
assign wb_req_addr = '{cache_req_addr.tag, cache_req_addr.laddr, 0, 0};
assign wb_resp_ready = (state_val == WB);

assign allocate_req_addr = '{cache_req_addr.tag, cache_req_addr.laddr, 0, 0};

assign allocate_resp_ready = (state_val == ALLOC);
    
endmodule