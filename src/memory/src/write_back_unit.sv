`include "common_pkg.sv"
`include "dcache_pkg.sv"
`include "AXI_bus_pkg.sv"

import common_pkg::word_t;
import AXI_bus_pkg::axi_word_t;

module write_back_unit (
    input logic clk,
    input logic rst,
    // Input request
    input logic [dcache_pkg::LINEBITS-1:0] wb_req_data,
    input word_t wb_req_addr,
    input logic wb_req_valid,
    output logic wb_req_ready,

    output logic wb_resp_valid,
    input logic wb_resp_ready,
    
    ////////////////////////////////////////////////////////////////////////////////
    // AXI channels
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
    output logic BREADY

);
import dcache_pkg::*;
import common_pkg::*;
import AXI_bus_pkg::*;

integer wb_cnt;
logic wb_next_finish = (wb_cnt - 1 == 0);
logic wb_req_fire, wb_resp_fire;
logic axi_transcation_fire;
assign axi_transcation_fire = WREADY && WVALID;

assign wb_req_fire = wb_req_valid & wb_req_ready;
assign wb_resp_fire = wb_resp_valid & wb_resp_ready;
always_ff @( posedge clk ) begin
    if (rst || wb_resp_fire) begin
        wb_cnt <= 0;
    end else if (wb_req_fire) begin
        wb_cnt <= dcache_pkg::ALLOC_BEATS;
    end else begin
        if (wb_cnt > 0 && axi_transcation_fire) begin
            wb_cnt <= wb_cnt - 1;
        end
    end
end


logic [dcache_pkg::LINEBITS-1:0] wb_req_data_shift_val, wb_req_data_shit_next;
always_ff @( posedge clk ) begin
   if (wb_req_fire) begin
       wb_req_data_shift_val <= wb_req_data_shit_next;
   end 
end
assign wb_req_data_shit_next = wb_req_fire ? 
    wb_req_data : wb_req_data_shift_val >> AXI_WIDTH;

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
        if (wb_req_fire) begin
            state_next = START;
        end
    end
    START: begin
        if (wb_next_finish) begin
           state_next = END; 
        end
    end
    END: begin
        if (wb_resp_fire) begin
            state_next = START;
        end else begin
            state_next = IDLE;
        end
    end
    endcase
end

// AW channel
assign AWID = 0;
assign AWADDR[31:0] = wb_req_addr;
assign AWADDR[48:32] = 0;
assign AWLEN = dcache_pkg::ALLOC_BEATS;
assign AWSIZE = 3'b111;
assign AWBURST = 2'b01;

assign AWLOCK = 0;
assign AWCACHE = 0;
assign AWPROT = 0;
assign AWQOS = 0;
assign AWREGION = 0;
assign AWUSER = 0;

assign AWVALID = wb_req_valid && (state_val == IDLE || state_val == END);
assign wb_req_ready = AWREADY;

// W channel
assign WDATA = wb_req_data_shift_val[AXI_WIDTH-1:0];
assign WSTRB = 8'hff;
assign WLAST = wb_next_finish;
assign WUSER = 0;
assign WVALID = (state_val == START);

// B channel
assign wb_resp_valid = BVALID;
assign BREADY = wb_resp_ready;
    
endmodule