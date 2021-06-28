`include "common_pkg.sv"
`include "dcache_pkg.sv"
`include "AXI_bus_pkg.sv"

import common_pkg::word_t;
import AXI_bus_pkg::axi_word_t;

module allocate_unit (
    input logic clk,
    input logic rst,

    ////////////////////////////////////////////////////////////////////////////////
    // dcache to allocation unit
    ////////////////////////////////////////////////////////////////////////////////
    input word_t allocate_req_addr,
    input logic allocate_req_valid,
    output logic allocate_req_ready,

    output logic [dcache_pkg::LINEBITS-1:0] allocate_resp_data,
    output logic allocate_resp_valid,
    input logic allocate_resp_ready,

    ////////////////////////////////////////////////////////////////////////////////
    // AXI channels
    ////////////////////////////////////////////////////////////////////////////////
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

integer allocate_cnt;
logic allocate_next_finish = (allocate_cnt - 1 == 0);
logic allocate_req_fire, allocate_resp_fire;
logic axi_transcation_fire;
assign axi_transcation_fire = RREADY && RVALID;

assign allocate_req_fire = allocate_req_valid & allocate_req_ready;
assign allocate_resp_fire = allocate_resp_valid & allocate_resp_ready;
always_ff @( posedge clk ) begin
    if (rst || allocate_resp_fire) begin
        allocate_cnt <= 0;
    end else if (allocate_req_fire) begin
        allocate_cnt <= dcache_pkg::ALLOC_BEATS;
    end else begin
        if (allocate_cnt > 0 && axi_transcation_fire) begin
            allocate_cnt <= allocate_cnt - 1;
        end
    end
end

logic [dcache_pkg::LINEBITS-1:0] allocate_resp_data_shift_val, allocate_resp_data_shit_next;
always_ff @( posedge clk ) begin
   if (axi_transcation_fire) begin
       allocate_resp_data_shift_val <= allocate_resp_data_shit_next;
   end 
end
assign allocate_resp_data_shit_next = {allocate_resp_data_shift_val[LINEBITS-1:AXI_WIDTH], RDATA};

typedef enum { IDLE, START, END } state_t;
state_t state_val, state_next;
always_ff @( posedge clk ) begin
    if (rst) begin
        state_val <= 0;
    end else begin
        state_val <= state_next; 
    end
end

always_comb begin
    state_next = state_val;
    case(state_val)
    IDLE: begin
        if (allocate_req_fire) begin
            state_next = START;
        end
    end
    START: begin
        if (allocate_next_finish) begin
           state_next = END; 
        end
    end
    END: begin
        if (allocate_resp_fire) begin
            state_next = START;
        end else begin
            state_next = IDLE;
        end
    end
    endcase
end

// AR channel
assign ARID = 0;
assign ARADDR[31:0] = allocate_req_addr;
assign ARADDR[48:32] = 0;
assign ARLEN = ALLOC_BEATS;
assign ARSIZE = 3'b111;
assign ARBURST = 2'b01; // INCR

assign ARLOCK = 0;
assign ARCACHE = 0; 
assign ARPROT = 0;
assign ARQOS = 0;
assign ARUSER = 0;

assign ARVALID = allocate_req_valid && (state_val == IDLE || state_val == END);
assign allocate_req_ready = ARREADY;

// R channel
assign RREADY = (state_val == START);

assign allocate_resp_data = allocate_resp_data_shift_val;
assign allocate_resp_valid = (state_val == END);
    
endmodule