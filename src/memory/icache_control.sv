`include "icache_pkg.sv"

module icache_control (
    input logic clk,
    input logic rst,

    /////// the top level signals //////
    input addr_t cache_addr,
    input logic cache_addr_valid,
    output logic cache_addr_ready, 

    output logic cache_result_valid, // take action if there is a miss

    /////// data line control signals ///////
    input logic wrap, // wrap or not

    output logic data_re, // read enable

    output addr_t data_waddr, // when doing allocation, use this address
    output word_t [WBKSZ-1:0] data_wdata, // when doing allocation, use this to supply data
    output logic data_we, // data write enable

    /////// overhead control signals ///////
    output logic overhead_re,
    input overhead_t [1:0] overhead_out,

    output laddr_t overhead_laddr_w,
    output logic overhead_we,
    output overhead_t overhead_w,

    /////// interface between AXI_writer_reader ///////
    output logic [WDSZ-1:0] mem_read_req_addr,
    output logic mem_read_req_valid,
    input logic mem_read_req_ready,

    input logic [WBKSZ * WDSZ - 1: 0] mem_read_resp_data, // a beat from AXI
    input logic mem_read_resp_valid,
    output logic mem_read_resp_ready
);


    // if no wrap, then only check the first
    logic target_hit, target_wrap_hit;
    always_comb begin : valid_comb_logic
        // valid if any way match the tag and valid
        target_hit = 0;
        target_wrap_hit = 0;
        if (overhead_out[0].tag == cache_addr.tag &&
            overhead_out[0].valid) begin
            target_hit = 1;
        end
        if (overhead_out[1].tag == cache_addr.tag &&
            overhead_out[1].valid) begin
            target_wrap_hit = 1;
        end
    end
    assign cache_result_valid = wrap ? target_wrap_hit & target_hit : target_hit;

    // if there is miss, allocate line will be the line to be resolved
    addr_t line_addr, wrap_line_addr, allocate_line;
    logic allocate_which;
    assign line_addr = '{cache_addr.tag, cache_addr.laddr, 0, 0};
    assign wrap_line_addr = '{cache_addr.tag, cache_addr.laddr + 1, 0, 0};
    // if there is a miss, fix the first line first
    assign allocate_which = !target_hit; 
    assign allocate_line = allocate_which ? line_addr : wrap_line_addr;
    // the target overhead is determined by allocate line
    assign overhead_laddr_w = allocate_line.laddr;

    // allocate req fire, beat
    logic allocate_beat_fire, allocate_req_fire;
    assign allocate_req_fire = mem_read_req_ready & mem_read_req_valid;
    assign allocate_beat_fire = mem_read_resp_ready & mem_read_resp_valid;

    // allocate resp cnt, expect all beats to be written in to the SRAM
    integer allocate_cnt, allocate_cnt_next;
    logic allocate_cnt_en, allocate_cnt_finish, allocate_cnt_rst;
    always_ff @( posedge clk ) begin : allocate_cnt_reg
       if (rst | allocate_cnt_rst) begin
           allocate_cnt <= 0;
       end else begin
           if (allocate_cnt_en) begin
               allocate_cnt <= allocate_cnt + 1;
           end
       end
    end
    assign allocate_cnt_next = allocate_cnt + 1;
    assign allocate_cnt_finish = (allocate_cnt_next == ALLOC_BEATS);
    assign allocate_cnt_rst = allocate_cnt_finish;
    assign allocate_cnt_en = allocate_beat_fire;

    // the request, if fire, always use the allocate line
    assign mem_read_req_addr = allocate_line;
    // the write data, always equals to the response data
    assign data_wdata =  mem_read_resp_data;
    // the write address, always equals to line addr + offset
    assign data_waddr =  allocate_line + allocate_cnt * (AXI_WIDTH / 8);
    // when the transacation is fire, the write is enabled
    assign data_we = allocate_beat_fire;
    // always ready to write. No request, no write
    assign mem_read_resp_ready = 1;

    typedef enum {IDLE, HIT, ALLOCATE_REQ, ALLOCATE, OVERHEAD, READ} state_t;
    state_t state, state_next;
    always_ff @( posedge clk ) begin : update_state
        if (rst) state <= IDLE;
        else state <= state_next; 
    end

    logic cache_addr_fire;
    assign cache_addr_fire = cache_addr_ready & cache_addr_valid;

    always_comb begin : control_FSM_decode
        // cache signals
        cache_addr_ready = 0;

        // default for data control
        data_re = 0;

        // default for overhead control
        overhead_re = 0;
        overhead_we = 0;
        overhead_w = 0;
        
        // AXI reader writer channel
        mem_read_req_valid = 0;

        // next state
        state_next = state;
        unique case(state)
        IDLE: begin
        // IDLE is the default case
            data_re = 1;
            overhead_re = 1;
            cache_addr_ready = 1;

            if (cache_addr_fire) begin
                state_next = HIT; // expect a hit                
            end 
        end
        HIT: begin
        // HIT expect overhead give a hit, otherwise do allocation
            if (wrap) begin
                // if wrap need to hit both of the line
                cache_result_valid = target_hit & target_wrap_hit;
            end else begin
                cache_result_valid = target_hit;
            end 

            if (!cache_result_valid) begin
                state_next = ALLOCATE_REQ;
            end
        end
        ALLOCATE_REQ: begin
        // ALLOCATE_REQ starts a req for <allocate_line>
            mem_read_req_valid = 1;
            if (allocate_req_fire) begin
                state_next = ALLOCATE; 
            end
        end
        ALLOCATE: begin
        // ALLOCATE waits the allocation to be finished
            if (allocate_cnt_finish) begin
                overhead_re = 1; // read out states
                state_next = OVERHEAD;
            end
        end
        OVERHEAD: begin
        // OVERHEAD, write OVERHEAD for the <allocate_line>
        overhead_we = 1;
        overhead_w = '{allocate_line.tag, 1'b1, overhead_out[allocate_which].dirty};
        state_next = READ;
        end
        READ: begin
        // READ, enable read (avoid address collision)
            data_re = 1;
            overhead_re = 1;
            if (!cache_result_valid) begin
                state_next = ALLOCATE_REQ;
            end else begin
                state_next = HIT;
            end
        end
        default: begin
            state_next = IDLE;
        end
        endcase
    end

endmodule