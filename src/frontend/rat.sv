//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/05/23
// Contributor: Jian Shi
// Reviewer: 
// Module Name: rat
// Target Devices: register renaming
// Description: 
// rename ARF to PRF
// Dependencies: 
// src/common/micro_op.svh, src/frontend/mappingtable.sv
//////////////////////////////////////////////////////////////////////////////////
`include "../common/micro_op.svh"

module rat (
  input   clock,
  input   reset,

  input   recover,
  input   pause,

  input   micro_op_t                        pc_recover,
  input   micro_op_t    [`RENAME_WIDTH-1:0] uop_in,
  output  micro_op_t    [`RENAME_WIDTH-1:0] uop_out,

  output  allocatable,
  output  checkable,

  output  ready
);

  // Info for check point table
  reg   [`RAT_CP_INDEX_SIZE-1:0]  check_head;
  reg   [`RAT_CP_INDEX_SIZE-1:0]  check_size;
  reg   [31:0]                    check_map[`RAT_CP_SIZE-1:0];

  logic [`RAT_CP_INDEX_SIZE:0]    check_head_next;
  logic [`RAT_CP_INDEX_SIZE:0]    check_size_next;

  // Store Several Branch info in same clk cycle
  logic [`RAT_CP_INDEX_SIZE-1:0]  check_tar[`RAT_CP_SIZE-1:0];
  logic [`RAT_CP_SIZE-1:0]        check_valid;
  logic                           check;

  logic                           allocatable_next;

mappingtable mapping_tb(
  .clock          (clock),
  .reset          (reset),
  .check          (check),
  .recover        (recover),
  .check_idx      (),
  .recover_idx    (),
  .rd_valid       (),
  .rs1            (),
  .rs2            (),
  .rd             (),
  .replace_req    (),
  .replace_prf    (),
  .prs1           (),
  .prs2           (),
  .prd            (),
  .prev_rd        (),
  .prev_rd_valid  (),
  .allocatable    (),
  .ready          ()
);

  always_comb begin
    check_head_next = check_head;
    check_size_next = check_size;
    if (recover) begin
      for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
        // Find Target Check Point
        if (pc_recover.pc == check_map[i]) begin
          check_head_next = i;
        end
      end
    end
  end

  always_comb begin
    check_valid = 0;
    for (int i = 0; i < `RENAME_WIDTH; i = i + 1 )  begin
      if (~(uop_in[i].br_type.br_x)) begin
        
      end
    end
    for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
      check_tar[i] = 0;
    end
    // Check point table is full
    if (check_size >= `RAT_CP_SIZE) begin
      check             = 0;
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
        check_map[i] <= 0;
      end
    end else if (check) begin
      check_size <= check_size_next;
      for (int i = 0; i < `RAT_CP_SIZE; i = i + 1 )  begin
        if (check_valid[i]) begin
          check_map[i] <= check_tar[i];
        end
      end
    end else if (recover) begin
      check_head <= check_head_next;
    end
  end

endmodule
