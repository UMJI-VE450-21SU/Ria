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
// src/frontend/rat.sv
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module mappingtable_tb;
parameter half_clk_cycle = 1;

reg  clock, reset, check, recover;

reg   [`RAT_CP_INDEX_SIZE-1:0]                        check_idx;
reg   [`RAT_CP_INDEX_SIZE-1:0]                        recover_idx;

reg   [`RENAME_WIDTH-1:0]                             rd_valid;

reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs1;
reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rs2;
reg   [`RENAME_WIDTH-1:0] [`ARF_INT_INDEX_SIZE-1:0]   rd;

reg   [`RENAME_WIDTH-1:0]                             retire_req;
reg   [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   retire_prf;

wire  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs1;
wire  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prs2;
wire  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prd;

wire  [`RENAME_WIDTH-1:0] [`PRF_INT_INDEX_SIZE-1:0]   prev_rd;
wire  [`RENAME_WIDTH-1:0]                             prev_rd_valid;

wire                                                  allocatable;

always #half_clk_cycle clock = ~clock;

mappingtable UTT(
  .clock              (clock            ),
  .reset              (reset            ),
  .check              (check            ),
  .recover            (recover          ),
  .check_idx          (check_idx        ),
  .recover_idx        (recover_idx      ),
  .rd_valid           (rd_valid         ),
  .rs1                (rs1              ),
  .rs2                (rs2              ),
  .rd                 (rd               ),
  .retire_req         (retire_req       ),
  .retire_prf         (retire_prf       ),
  .prs1               (prs1             ),
  .prs2               (prs2             ),
  .prd                (prd              ),
  .prev_rd            (prev_rd          ),
  .prev_rd_valid      (prev_rd_valid    ),
  .allocatable        (allocatable      )
);

initial begin
    #0 clock = 0; reset = 1; check = 0; recover = 0; check_idx = 0; recover_idx = 0;
    rd_valid = 0; rs1 = 0; rs2 = 0; rd = 0; retire_req = 0; retire_prf = 0;
    #2 reset = 0;
end

endmodule
