`include "icache_pkg.sv"
// [Description]
// when the instruction fetch is across the
// boundary, two set of overhead need to be checked seperately. 
// this module can output tags and states for two different lines.

// This file is seperated from line data for individual access.
// for example, cache coherency may be needed.

// Expected memory useage: BRAM x 1 
// 512bx72, each row contains two set of overhead. 


module cache_mem_overhead(
    input logic clk,

    input laddr_t laddra, 
    input logic wrap,
    input logic re,
    output overhead_t [1:0] overhead_out[WAYS], 
    // if not wrap, only the first overhead in each way will be used

    input laddr_t laddrb,
    input overhead_t overhead_in,
    input logic [WAYS-1:0] we // only one change at a time. Use mask to do this 
);
    (* ram_style = "block" *) overhead_t [1:0][LNUM/2-1:0] oram [$clog2(WAYS)];

    wire [LADDRSZ-2:0] row_target_a = laddra[LADDRSZ-1:1];

    // still need to review
    always_ff @( posedge clk ) begin : read_access
        for (int i = 0; i < WAYS; i++) begin
           overhead_out[i][0] <= oram[i][9'(row_target_a + 9'(wrap))][0];
           overhead_out[i][1] <= oram[i][row_target_a][1];
        end
    end

    wire [LADDRSZ-2:0] row_target_b = laddrb[LADDRSZ-1:1];
    always_ff @( posedge clk ) begin : write_access
        for (int i = 0; i < WAYS; i++) begin
            if (we[i]) begin
                oram[i][row_target_b][laddrb[0]] <= overhead_in;            
            end
        end 
    end
    
endmodule

