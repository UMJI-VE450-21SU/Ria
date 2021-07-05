// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Scoreboard (PRF status for issue queue)
// Author:  Li Shi
// Date:    2021/07/05

module scoreboard_int (
  input clock,
  input reset,
  input clear,
  // Dispatched instructions (last in-order stage)
  input  [`PRF_INT_WAYS-1:0][`PRF_INT_INDEX_SIZE-1:0] set_busy_index,
  input  [`PRF_INT_WAYS-1:0]                          set_busy_valid,
  // Write back instructions
  input  [`PRF_INT_WAYS-1:0][`PRF_INT_INDEX_SIZE-1:0] clear_busy_index,
  input  [`PRF_INT_WAYS-1:0]                          clear_busy_valid,
  // Inquiry from issue queue entry
  input  [`PRF_INT_WAYS-1:0][`PRF_INT_INDEX_SIZE-1:0] rs1_index,
  input  [`PRF_INT_WAYS-1:0][`PRF_INT_INDEX_SIZE-1:0] rs2_index,
  output [`PRF_INT_WAYS-1:0]                          rs1_busy,
  output [`PRF_INT_WAYS-1:0]                          rs2_busy
);

  // multi-bank scoreboard
  reg [`PRF_INT_SIZE-1:0] sb [`PRF_INT_WAYS-1:0];

  logic [`PRF_INT_SIZE-1:0] set_busy_req, clear_busy_req;

  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_WAYS-1:0] rs1_from_clear;
  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_WAYS-1:0] rs2_from_clear;

  always_comb begin
    set_busy_req = 0;
    clear_busy_req = 0;
    for (integer i = 0; i < `PRF_INT_SIZE; i++) begin
      if (set_busy_valid[i])
        set_busy_req[set_busy_index[i]] = 1;
      if (clear_busy_valid[i])
        clear_busy_req[clear_busy_index[i]] = 1;
    end
  end

  // generate bypass logic (rs1/rs2 <- clear_busy)
  generate
    for (genvar i = 0; i < `PRF_INT_WAYS; i++) begin
      for (genvar j = 0; j < `PRF_INT_WAYS; j++) begin
        assign rs1_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_index[i]);
        assign rs2_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_index[i]);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i++) begin
      rs1_busy[i] = sb[i][rs1_index[i]];
      rs2_busy[i] = sb[i][rs2_index[i]];
      for (int j = 0; j < `PRF_INT_WAYS; j++) begin
        if (rs1_from_clear[i][j])
          rs1_busy[i] = 0;  
        if (rs2_from_clear[i][j])
          rs2_busy[i] = 0;
      end
    end
  end

  always @(posedge clk)   begin
    if (reset | clear) begin
      for (integer i = 0; i < `PRF_INT_WAYS; i++)
        sb[i] <= 0;
    end else begin
      for (integer i = 0; i < `PRF_INT_WAYS; i++)
        sb[i] <= (sb[i] | set_busy_req) & (~clear_busy_req);
    end
  end

endmodule
