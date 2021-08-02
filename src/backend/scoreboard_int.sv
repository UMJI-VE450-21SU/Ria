// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Scoreboard for Integer (PRF status for issue queue)
// Author:  Li Shi
// Date:    2021/07/05

module scoreboard_int (
  input clock,
  input reset,
  input clear,
  // Dispatched instructions (last in-order stage)
  input  [`DISPATCH_WIDTH-1:0][`PRF_INT_INDEX_SIZE-1:0] set_busy_index,
  input  [`DISPATCH_WIDTH-1:0]                          set_busy_valid,
  // Write back instructions
  input  [`PRF_INT_WAYS-1:0][`PRF_INT_INDEX_SIZE-1:0] clear_busy_index,
  input  [`PRF_INT_WAYS-1:0]                          clear_busy_valid,
  // Inquiry from int issue queue slots
  input  [`IQ_INT_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs1_int_index,
  input  [`IQ_INT_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs2_int_index,
  output logic [`IQ_INT_SIZE-1:0]                    rs1_int_busy,
  output logic [`IQ_INT_SIZE-1:0]                    rs2_int_busy,
  // Inquiry from mem issue queue slots
  input  [`IQ_MEM_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs1_mem_index,
  input  [`IQ_MEM_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs2_mem_index,
  output logic [`IQ_MEM_SIZE-1:0]                    rs1_mem_busy,
  output logic [`IQ_MEM_SIZE-1:0]                    rs2_mem_busy,
  // Inquiry from ap issue queue slots
  input  [`IQ_AP_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0]  rs1_ap_index,
  input  [`IQ_AP_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0]  rs2_ap_index,
  output logic [`IQ_AP_SIZE-1:0]                     rs1_ap_busy,
  output logic [`IQ_AP_SIZE-1:0]                     rs2_ap_busy
);

  reg [`PRF_INT_SIZE-1:0] sb;

  logic [`PRF_INT_SIZE-1:0] set_busy_req, clear_busy_req;

  logic [`IQ_INT_SIZE-1:0] [`PRF_INT_WAYS-1:0] rs1_int_from_clear;
  logic [`IQ_INT_SIZE-1:0] [`PRF_INT_WAYS-1:0] rs2_int_from_clear;
  logic [`IQ_MEM_SIZE-1:0] [`PRF_INT_WAYS-1:0] rs1_mem_from_clear;
  logic [`IQ_MEM_SIZE-1:0] [`PRF_INT_WAYS-1:0] rs2_mem_from_clear;
  logic [`IQ_AP_SIZE-1:0] [`PRF_INT_WAYS-1:0]  rs1_ap_from_clear;
  logic [`IQ_AP_SIZE-1:0] [`PRF_INT_WAYS-1:0]  rs2_ap_from_clear;

  always_comb begin
    set_busy_req = 0;
    for (integer i = 0; i < `DISPATCH_WIDTH; i++) begin
      if (set_busy_valid[i])
        set_busy_req[set_busy_index[i]] = 1;
    end
  end

  always_comb begin
    clear_busy_req = 0;
    for (integer i = 0; i < `PRF_INT_WAYS; i++) begin
      if (clear_busy_valid[i])
        clear_busy_req[clear_busy_index[i]] = 1;
    end
  end

  // generate bypass logic (rs1/rs2 <- clear_busy)
  generate
    for (genvar i = 0; i < `IQ_INT_SIZE; i++) begin
      for (genvar j = 0; j < `PRF_INT_WAYS; j++) begin
        assign rs1_int_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_int_index[i]);
        assign rs2_int_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_int_index[i]);
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < `IQ_MEM_SIZE; i++) begin
      for (genvar j = 0; j < `PRF_INT_WAYS; j++) begin
        assign rs1_mem_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_mem_index[i]);
        assign rs2_mem_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_mem_index[i]);
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < `IQ_AP_SIZE; i++) begin
      for (genvar j = 0; j < `PRF_INT_WAYS; j++) begin
        assign rs1_ap_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_ap_index[i]);
        assign rs2_ap_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_ap_index[i]);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `IQ_INT_SIZE; i++) begin
      // t0 is never busy
      rs1_int_busy[i] = (rs1_int_index[i] == 0) ? 0 : sb[rs1_int_index[i]];
      rs2_int_busy[i] = (rs2_int_index[i] == 0) ? 0 : sb[rs2_int_index[i]];
      for (int j = 0; j < `PRF_INT_WAYS; j++) begin
        if (rs1_int_from_clear[i][j])
          rs1_int_busy[i] = 0;  
        if (rs2_int_from_clear[i][j])
          rs2_int_busy[i] = 0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `IQ_MEM_SIZE; i++) begin
      // t0 is never busy
      rs1_mem_busy[i] = (rs1_mem_index[i] == 0) ? 0 : sb[rs1_mem_index[i]];
      rs2_mem_busy[i] = (rs2_mem_index[i] == 0) ? 0 : sb[rs2_mem_index[i]];
      for (int j = 0; j < `PRF_INT_WAYS; j++) begin
        if (rs1_mem_from_clear[i][j])
          rs1_mem_busy[i] = 0;  
        if (rs2_mem_from_clear[i][j])
          rs2_mem_busy[i] = 0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `IQ_AP_SIZE; i++) begin
      // t0 is never busy
      rs1_ap_busy[i] = (rs1_ap_index[i] == 0) ? 0 : sb[rs1_ap_index[i]];
      rs2_ap_busy[i] = (rs2_ap_index[i] == 0) ? 0 : sb[rs2_ap_index[i]];
      for (int j = 0; j < `PRF_INT_WAYS; j++) begin
        if (rs1_ap_from_clear[i][j])
          rs1_ap_busy[i] = 0;  
        if (rs2_ap_from_clear[i][j])
          rs2_ap_busy[i] = 0;
      end
    end
  end

  always @(posedge clock)   begin
    if (reset | clear) begin
      sb <= 0;
    end else begin
      sb <= (sb | set_busy_req) & (~clear_busy_req);
    end
  end

  wire sb_int_print = 0;

  always_ff @(posedge clock) begin
    if (sb_int_print) begin
      $display("[SB_INT] sb =%b", sb);
      $display("[SB_INT] set=%b", set_busy_req);
      $display("[SB_INT] clr=%b", clear_busy_req);
    end
  end

endmodule
