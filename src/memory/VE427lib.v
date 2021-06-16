/* 

 The "no flip-flop inference" policy.  Instead of using flip-flop and
 register inference, use explicit instantiation of register modules 
 (defined below). 
 
 This way of specification matches our RTL model of circuit,
 i.e., all specifications are nothing but a set of interconnected
 combinational logic blocks and state elements.  The goal is to
 simplify the use of Verilog and avoid mistakes that arise from
 specifying sequential logic.  Also, we can eliminate the explicit use
 of the non-blocking assignment "<=", and the associated confusion
 about blocking versus non-blocking.

*/
`timescale 1ns/1ns

// Register of D-Type Flip-flops
module REGISTER(q, d, clk);
   parameter N = 1;
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input 	     clk;
   initial q = {N{1'b0}};
   always @(posedge clk)
    q <= d;
endmodule // REGISTER

// Register with clock enable
module REGISTER_CE(q, d, ce, clk);
   parameter N = 1;
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input 	      ce, clk;
   initial q = {N{1'b0}};
   always @(posedge clk)
     if (ce) q <= d;
endmodule // REGISTER_CE

// Register with reset value
module REGISTER_R(q, d, rst, clk);
   parameter N = 1;
   parameter INIT = {N{1'b0}};
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input 	      rst, clk;
   initial q = INIT;
   always @(posedge clk)
     if (rst) q <= INIT;
     else q <= d;
endmodule // REGISTER_R

// Register with reset and clock enable
//  Reset works independently of clock enable
module REGISTER_R_CE(q, d, rst, ce, clk);
   parameter N = 1;
   parameter INIT = {N{1'b0}};
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input 	      rst, ce, clk;
   initial q = INIT;
   always @(posedge clk)
     if (rst) q <= INIT;
     else if (ce) q <= d;
endmodule // REGISTER_R_CE

// Xilinx FPGA Dual-ported RAM with synchronous read
module XILINX_SYNC_RAM_DP(q0, d0, addr0, we0, q1, d1, addr1, we1, clk, rst);
    parameter DWIDTH = 8;               // Data width
    parameter AWIDTH = 8;               // Address width
    parameter DEPTH = 256;              // Memory depth
    parameter MEM_INIT_HEX_FILE = "";
    parameter MEM_INIT_BIN_FILE = "";
    input clk;
    input rst;
    input [DWIDTH-1:0] d0;               // Data input
    input [AWIDTH-1:0] addr0;            // Address input
    input 	           we0;
    output [DWIDTH-1:0] q0;

    input [DWIDTH-1:0] d1;               // Data input
    input [AWIDTH-1:0] addr1;            // Address input
    input 	           we1;
    output [DWIDTH-1:0] q1;
    (* ram_style = "block" *) reg [DWIDTH-1:0] mem [DEPTH-1:0];

    integer i;
    initial begin
        if (MEM_INIT_HEX_FILE != "") begin
	          $readmemh(MEM_INIT_HEX_FILE, mem);
        end
        else if (MEM_INIT_BIN_FILE != "") begin
	          $readmemb(MEM_INIT_BIN_FILE, mem);
        end
        else begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] = 0;
            end
        end
    end

    reg [DWIDTH-1:0] read0_reg_val;
    reg [DWIDTH-1:0] read1_reg_val;
    always @(posedge clk) begin
        if (we0)
            mem[addr0] <= d0;
        if (rst)
            read0_reg_val <= 0;
        else
            read0_reg_val <= mem[addr0];
    end

    always @(posedge clk) begin
        if (we1)
            mem[addr1] <= d1;
        if (rst)
            read1_reg_val <= 0;
        else
            read1_reg_val <= mem[addr1];
    end

    assign q0 = read0_reg_val;
    assign q1 = read1_reg_val;

endmodule // XILINX_SYNC_RAM_DP

