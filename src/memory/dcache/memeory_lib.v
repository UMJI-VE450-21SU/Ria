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

