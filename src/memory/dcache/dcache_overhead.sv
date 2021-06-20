`include "dcache_pkg.sv"
// [Description]
// Unlike the icache design, the dcache only supports aligned access
// therefore, there will be no chance to check the tag for two lines

// Expected memory useage: BRAM x 1 
// 1k, each row contains two set of overhead. 

module dcache_overhead(
    input logic clk,

    // read two at a time
    input laddr_t laddra, 
    input logic re,
    output overhead_t overhead_out, 

    // write one at a time
    input laddr_t laddrb,
    input overhead_t overhead_in,
    input logic we
);
    // need additional one row
    (* ram_style = "block" *) overhead_t [LNUM:0] oram;

    always_ff @( posedge clk ) begin : overhead_write
        if (we) begin
            oram[laddrb] <= overhead_in;            
        end
    end

    always_ff @( posedge clk ) begin : overhead_read
        if (re) begin
            overhead_out <= oram[laddra];
        end
        
    end


    
endmodule