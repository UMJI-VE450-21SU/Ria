`include "dcache_pkg.sv"

module dcache_control (
    input logic clk,
    input logic rst,

    /////// the top level signals //////
    input addr_t cache_addr,
    input logic cache_addr_valid,
    output logic cache_addr_ready, 

    output logic cache_result_valid, // take action if there is a miss

    /////// data line control signals ///////
    // [read]
    output laddr_t dladdra, // line address & word address for read
    output waddr_t dwaddra,
    output logic dre,
    input word_t [RBKSZ-1:0] dout,

    // [write]
    output laddr_t dladdrb, // line address & word address for write
    output waddr_t dwaddrb,
    output word_t [WBKSZ-1:0] din,       // data for [write]
    output logic dwe,                      // write enable

    /////// overhead control signals ///////
    output logic overhead_re,
    input overhead_t overhead_out,

    output laddr_t overhead_laddr_w,
    output logic overhead_we,
    output overhead_t overhead_w,

    /////// interface between AXI_reader ///////
    output logic [WDSZ-1:0] mem_read_req_addr,
    output logic mem_read_req_valid,
    input logic mem_read_req_ready,

    input logic [WBKSZ * WDSZ - 1: 0] mem_read_resp_data, // a beat from AXI
    input logic mem_read_resp_valid,
    output logic mem_read_resp_ready,

    /////// interface between AXI_writer ///////
    output logic [WDSZ-1:0] mem_write_req_addr,
    output logic mem_write_req_valid,
    input logic mem_write_req_ready,

    output word_t [1:0] mem_write_req_data,
    output logic mem_write_req_data_valid,
    input logic mem_write_req_data_ready,

    // only consider correct response
    input logic mem_write_resp_valid, 
    output logic mem_write_resp_ready
);


    assign cache_result_valid = overhead_out.tag == cache_addr.tag;

    // if there is a miss, which line will be operated
    addr_t target_line;
    assign target_line = '{cache_addr.tag, cache_addr.laddr, 0, 0};
    assign overhead_laddr_w = target_line.laddr;

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
    assign mem_read_req_addr = target_line;
    // the write data, always equals to the response data
    assign data_wdata =  mem_read_resp_data;
    // the write address, always equals to line addr + offset
    assign data_waddr =  target_line + allocate_cnt * (AXI_WIDTH / 8);
    // when the transacation is fire, the write is enabled
    assign data_we = allocate_beat_fire;
    // always ready to write. No request, no write
    assign mem_read_resp_ready = 1;


    // write_back req fire, beat
    logic write_back_beat_fire, write_back_req_fire;
    assign write_back_req_fire = mem_read_req_ready & mem_read_req_valid;
    assign write_back_beat_fire = mem_read_resp_ready & mem_read_resp_valid;

    // write back cnt
    integer write_back_cnt, write_back_cnt_next;
    logic write_back_cnt_en, write_back_cnt_finish, write_back_cnt_rst;
    always_ff @( posedge clk ) begin : write_back_cnt_reg
       if (rst | write_back_cnt_rst) begin
           write_back_cnt <= 0;
       end else begin
           if (write_back_cnt_en) begin
               write_back_cnt <= write_back_cnt + 1;
           end
       end
    end
    assign write_back_cnt_next = write_back_cnt + 1;
    assign write_back_cnt_finish = (write_back_cnt_next == ALLOC_BEATS);
    assign write_back_cnt_rst = write_back_cnt_finish;
    assign write_back_cnt_en = write_back_beat_fire;

    assign mem_write_req_addr = target_line;
    assign mem_write_req_data = 

    typedef enum {IDLE, HIT, ALLOCATE_REQ, ALLOCATE, WB_REQ, WB, OVERHEAD, READ} state_t;
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
            if (!cache_result_valid) begin
                if (overhead_out.dirty && we) begin
                    state_next = WB_REQ; 
                end else begin
                    state_next = ALLOCATE_REQ;
                end
            end
        end
        WB_REQ: begin
        // WB_REQ starts a req for 
            
        end
        WB: begin
            
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