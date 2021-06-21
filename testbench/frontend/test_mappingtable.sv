//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Jian Shi
// Reviewer: 
// Module Name: mappingtable_tb
// Target Devices: testbench for mapping table
// Description: 
// testbench for mapping table
// Dependencies: 
// src/frontend/mappingtable.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mappingtable_tb;
parameter half_clk_cycle = 1;

reg  clock, reset, check, recover, stall;

reg  [`RAT_CP_INDEX_SIZE-1:0]                         check_idx;
reg  [`RENAME_WIDTH-1:0]                              check_flag;
reg  [`RAT_CP_INDEX_SIZE-1:0]                         recover_idx;
reg  [`ARF_INT_SIZE-1:0]                              arf_recover;

reg  [`RENAME_WIDTH-1:0]                              rd_valid;

reg  [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]    rs1;
reg  [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]    rs2;
reg  [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]    rd;

reg  [`RENAME_WIDTH-1:0]                              replace_req;
reg  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    replace_prf;

wire [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    prs1;
wire [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    prs2;
wire [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    prd;

wire [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]    prev_rd;
wire [`RENAME_WIDTH-1:0]                              prev_rd_valid;

wire                                                  allocatable;

always #half_clk_cycle clock = ~clock;

mappingtable UTT(
  .clock              (clock            ),
  .reset              (reset            ),
  .stall              (stall            ),
  .check              (check            ),
  .recover            (recover          ),
  .arf_recover        (arf_recover      ),
  .check_idx          (check_idx        ),
  .check_flag         (check_flag       ),
  .recover_idx        (recover_idx      ),
  .rd_valid           (rd_valid         ),
  .rs1                (rs1              ),
  .rs2                (rs2              ),
  .rd                 (rd               ),
  .replace_req        (replace_req      ),
  .replace_prf        (replace_prf      ),
  .prs1               (prs1             ),
  .prs2               (prs2             ),
  .prd                (prd              ),
  .prev_rd            (prev_rd          ),
  .prev_rd_valid      (prev_rd_valid    ),
  .allocatable        (allocatable      )
);

initial begin
  #0 clock = 0; reset = 1; check = 0; recover = 0; check_flag = 0;
  check_idx = 0; recover_idx = 0; arf_recover = 0; stall = 0;
  rd_valid = 0; rs1 = 0; rs2 = 0; rd = 0; replace_req = 0; replace_prf = 0;
  #2 reset = 0;
  #2 rd_valid = 4'b1111; rs1 = 0; rs2 = 0; rd = 20'h8864; stall = 1;
  #4 rd_valid = 4'b0; rs1 = 20'h8864; rs2 = 20'h8864; rd = 0; stall = 0;
  #2 rd_valid = 4'b1111; rs1 = 0; rs2 = 0; rd = 20'h8864;
  #10 rd_valid = 4'b0; rs1 = 20'h8864; rs2 = 20'h8864; rd = 0;
  #2 replace_req = 4'b1111; replace_prf = 24'h420C4;
  #2 check = 1; check_idx = 2'b1; replace_req = 4'b0; replace_prf = 24'h0;
  check_flag = 4'b0010; rd_valid = 4'b1101; rd = 20'h8864;
  #2 check = 0; rd_valid = 4'b1111; rs1 = 0; rs2 = 0;
  #2 rd_valid = 4'b0;
  #2 recover = 1; rd_valid = 4'b0; recover_idx = 2'b1;
  #10 $stop;
end

endmodule
