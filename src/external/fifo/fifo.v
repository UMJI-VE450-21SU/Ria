module fifo #(
    parameter WIDTH = 32,  // data width is 32-bit
    parameter LOGDEPTH = 3 // 2^3 = 8 entries
) (
    input clk,
    input rst,

    input  enq_valid,
    input  [WIDTH-1:0] enq_data,
    output enq_ready,

    output deq_valid,
    output [WIDTH-1:0] deq_data,
    input deq_ready
);
    
    
    localparam DEPTH = (1 << LOGDEPTH);
    
    // use "fire" to indicate when a valid transaction has been made
    wire enq_fire;
    wire deq_fire;
    
    assign enq_fire = enq_valid & enq_ready;
    assign deq_fire = deq_valid & deq_ready;


    // following signals may be helpful
    wire full, empty; 
    
    // TODO: Fill in the remaining logic to implement the FIFO
    
    wire [LOGDEPTH-1:0] rptr, rptr_next;
    wire rptr_ce, rptr_rst;
    assign rptr_next = rptr + 1;
    assign rptr_ce   = deq_fire;
    assign rptr_rst  = rst;
    
    wire [LOGDEPTH-1:0] wptr, wptr_next;
    wire wptr_ce, wptr_rst;
    assign wptr_next = wptr + 1;
    assign wptr_ce   = enq_fire;
    assign wptr_rst  = rst;
    
    REGISTER_R_CE #(.N(LOGDEPTH)) rptr_reg(.q(rptr), .d(rptr_next), .ce(rptr_ce), .rst(rptr_rst), .clk(clk));
    REGISTER_R_CE #(.N(LOGDEPTH)) wptr_reg(.q(wptr), .d(wptr_next), .ce(wptr_ce), .rst(wptr_rst), .clk(clk));
    
    // is the buffer full? This is needed for when rptr == wptr
    // read & write pointer
    wire full_next, full_ce, full_rst;
    REGISTER_R_CE #(.N(1)) full_reg(.q(full), .d(full_next), .ce(full_ce), .rst(full_rst), .clk(clk));
    assign full_ce   = enq_fire || deq_fire;
    assign full_next = enq_fire && (wptr_next == rptr);
    assign full_rst  = rst;
    
    // the buffer itself.
    wire [LOGDEPTH-1:0] buffer_addr0;
    wire [WIDTH-1:0]    buffer_d0, buffer_q0;
    wire [LOGDEPTH-1:0] buffer_addr1;
    wire [WIDTH-1:0]    buffer_d1, buffer_q1;
    wire buffer_we0;
    wire buffer_we1;
    XILINX_SYNC_RAM_DP #(.AWIDTH(LOGDEPTH), .DWIDTH(WIDTH), .DEPTH(DEPTH)) buffer (
    .q0(buffer_q0), .d0(buffer_d0), .addr0(buffer_addr0), .we0(buffer_we0),
    .q1(buffer_q1), .d1(buffer_d1), .addr1(buffer_addr1), .we1(buffer_we1),
    .clk(clk), .rst(rst));
    assign buffer_d0    = 0;
    assign buffer_addr0 = rptr_next;
    assign buffer_we0   = 0;
    
    assign buffer_d1    = enq_data;
    assign buffer_addr1 = wptr;
    assign buffer_we1   = enq_fire && ~full;
    
    
    // Define any additional regs or wires you need (if any) here
    
    wire fifo_empty, fifo_full;
    assign fifo_empty = ~full & (wptr == rptr);
    assign fifo_full  = full;
    
    wire fifo_one_element;
    assign fifo_one_element = (wptr == rptr_next);

    wire addr_collision_val;
    REGISTER #(.N(1)) addr_collision(.q(addr_collision_val), .d(enq_fire & (rptr_next == wptr)), .clk(clk));
    
    wire [WIDTH-1: 0] read_buffer_reg_val, read_buffer_reg_next;
    wire read_buffer_reg_ce, read_buffer_reg_rst;
    
    REGISTER_R_CE #(.N(WIDTH)) read_buffer_reg(
    .q(read_buffer_reg_val), .d(read_buffer_reg_next), .rst(read_buffer_reg_rst),
    .ce(read_buffer_reg_ce), .clk(clk)
    );
    assign read_buffer_reg_ce = deq_fire | (enq_fire & fifo_empty) | (addr_collision_val & deq_fire);
    assign read_buffer_reg_next = (fifo_empty || addr_collision_val) ? enq_data : buffer_q0;
    assign read_buffer_reg_rst = rst;
    
    wire last_deq_fire_val;
    REGISTER #(.N(1)) last_deq_fire(.q(last_deq_fire_val), .d(deq_fire), .clk(clk));
    
    assign deq_data = (last_deq_fire_val & ~addr_collision_val) ? buffer_q0 : read_buffer_reg_val; // deq_data
    assign deq_valid  = ~fifo_empty; 
    assign enq_ready  = ~fifo_full; 
    
endmodule
