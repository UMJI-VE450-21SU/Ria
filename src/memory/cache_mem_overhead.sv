`include "icache_pkg.sv"
// [Description]
// when the instruction fetch is across the
// boundary, two set of overhead need to be checked seperately. 
// by arrange the tag position properly, we can achieve that

// Expected memory useage: BRAM x 1 
// 512bx36b x 2, each row contains two set of overhead. 

module cache_mem_overhead(
    input logic clk,

    // read two at a time
    input laddr_t laddra, 
    input logic re,
    input logic wrap,
    output overhead_t [1:0] overhead_out, 

    // write one at a time
    input laddr_t laddrb,
    input overhead_t overhead_in,
    input logic we
);
    // need additional one row
    (* ram_style = "block" *) overhead_t [1:0][LNUM/2:0] oram;

    wire [LADDRSZ-2:0] row_target_a = laddra >> 1;
    wire [LADDRSZ-2:0] row_target_b = laddrb >> 1;
    always_ff @( posedge clk ) begin : overhead_access
        if (we) begin
            oram[row_target_b][!laddrb[0]] <= overhead_in;            
        end
        if (re) begin
            if (wrap) begin
                overhead_out[0] <= oram[row_target_a][1];
                overhead_out[1] <= oram[row_target_a + 1][0];
            end else begin
                overhead_out[0] <= oram[row_target_a][0];
                overhead_out[1] <= oram[row_target_a][1];
            end
        end
    end
    
endmodule

