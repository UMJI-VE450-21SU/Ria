// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Scoreboard (PRF status for issue queue)
// Author:  Li Shi
// Date:    2021/07/05

module scoreboard (
  input clock,
  input reset,
  input clear,
  // Dispatched instructions (last in-order stage)
  input  [`DISPATCH_WIDTH-1:0][`PRF_INDEX_SIZE-1:0] set_busy_index,
  input  [`DISPATCH_WIDTH-1:0]                      set_busy_valid,
  // Write back instructions
  input  [`PRF_WAYS-1:0][`PRF_INDEX_SIZE-1:0]       clear_busy_index,
  input  [`PRF_WAYS-1:0]                            clear_busy_valid,
  // Inquiry from int issue queue slots
  input  [`IQ_INT_SIZE-1:0][`PRF_INDEX_SIZE-1:0]    rs1_int_index,
  input  [`IQ_INT_SIZE-1:0][`PRF_INDEX_SIZE-1:0]    rs2_int_index,
  output logic [`IQ_INT_SIZE-1:0]                   rs1_int_busy,
  output logic [`IQ_INT_SIZE-1:0]                   rs2_int_busy,
  // Inquiry from mem issue queue slots
  input  [`IQ_MEM_SIZE-1:0][`PRF_INDEX_SIZE-1:0]    rs1_mem_index,
  input  [`IQ_MEM_SIZE-1:0][`PRF_INDEX_SIZE-1:0]    rs2_mem_index,
  output logic [`IQ_MEM_SIZE-1:0]                   rs1_mem_busy,
  output logic [`IQ_MEM_SIZE-1:0]                   rs2_mem_busy,
  // Inquiry from fp issue queue slots
  input  [`IQ_FP_SIZE-1:0][`PRF_INDEX_SIZE-1:0]     rs1_fp_index,
  input  [`IQ_FP_SIZE-1:0][`PRF_INDEX_SIZE-1:0]     rs2_fp_index,
  input  [`IQ_FP_SIZE-1:0][`PRF_INDEX_SIZE-1:0]     rs3_fp_index,
  output logic [`IQ_FP_SIZE-1:0]                    rs1_fp_busy,
  output logic [`IQ_FP_SIZE-1:0]                    rs2_fp_busy,
  output logic [`IQ_FP_SIZE-1:0]                    rs3_fp_busy
);

  reg [`PRF_SIZE-1:0] sb;

  logic [`PRF_SIZE-1:0] set_busy_req, clear_busy_req;

  logic [`IQ_INT_SIZE-1:0] [`PRF_WAYS-1:0] rs1_int_from_clear;
  logic [`IQ_INT_SIZE-1:0] [`PRF_WAYS-1:0] rs2_int_from_clear;
  logic [`IQ_MEM_SIZE-1:0] [`PRF_WAYS-1:0] rs1_mem_from_clear;
  logic [`IQ_MEM_SIZE-1:0] [`PRF_WAYS-1:0] rs2_mem_from_clear;
  logic [`IQ_FP_SIZE-1:0]  [`PRF_WAYS-1:0] rs1_fp_from_clear;
  logic [`IQ_FP_SIZE-1:0]  [`PRF_WAYS-1:0] rs2_fp_from_clear;
  logic [`IQ_FP_SIZE-1:0]  [`PRF_WAYS-1:0] rs3_fp_from_clear;

  always_comb begin
    set_busy_req = 0;
    for (integer i = 0; i < `DISPATCH_WIDTH; i++) begin
      if (set_busy_valid[i])
        set_busy_req[set_busy_index[i]] = 1;
    end
  end

  always_comb begin
    clear_busy_req = 0;
    for (integer i = 0; i < `PRF_WAYS; i++) begin
      if (clear_busy_valid[i])
        clear_busy_req[clear_busy_index[i]] = 1;
    end
  end

  // generate bypass logic (rs1/rs2 <- clear_busy)
  generate
    for (genvar i = 0; i < `IQ_INT_SIZE; i++) begin
      for (genvar j = 0; j < `PRF_WAYS; j++) begin
        assign rs1_int_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_int_index[i]);
        assign rs2_int_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_int_index[i]);
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < `IQ_MEM_SIZE; i++) begin
      for (genvar j = 0; j < `PRF_WAYS; j++) begin
        assign rs1_mem_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_mem_index[i]);
        assign rs2_mem_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_mem_index[i]);
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < `IQ_FP_SIZE; i++) begin
      for (genvar j = 0; j < `PRF_WAYS; j++) begin
        assign rs1_fp_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs1_fp_index[i]);
        assign rs2_fp_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs2_fp_index[i]);
        assign rs3_fp_from_clear[i][j] = clear_busy_valid[j] && (clear_busy_index[j] == rs3_fp_index[i]);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `IQ_INT_SIZE; i++) begin
      // t0 is never busy
      rs1_int_busy[i] = (rs1_int_index[i] == 0) ? 0 : sb[rs1_int_index[i]];
      rs2_int_busy[i] = (rs2_int_index[i] == 0) ? 0 : sb[rs2_int_index[i]];
      for (int j = 0; j < `PRF_WAYS; j++) begin
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
      for (int j = 0; j < `PRF_WAYS; j++) begin
        if (rs1_mem_from_clear[i][j])
          rs1_mem_busy[i] = 0;  
        if (rs2_mem_from_clear[i][j])
          rs2_mem_busy[i] = 0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < `IQ_MEM_SIZE; i++) begin
      // t0 is never busy
      rs1_fp_busy[i] = (rs1_fp_index[i] == 0) ? 0 : sb[rs1_fp_index[i]];
      rs2_fp_busy[i] = (rs2_fp_index[i] == 0) ? 0 : sb[rs2_fp_index[i]];
      rs3_fp_busy[i] = (rs3_fp_index[i] == 0) ? 0 : sb[rs3_fp_index[i]];
      for (int j = 0; j < `PRF_WAYS; j++) begin
        if (rs1_fp_from_clear[i][j])
          rs1_fp_busy[i] = 0;  
        if (rs2_fp_from_clear[i][j])
          rs2_fp_busy[i] = 0;
        if (rs3_fp_from_clear[i][j])
          rs3_fp_busy[i] = 0;
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

  wire sb_print = 1;

  always_ff @(posedge clock) begin
    if (sb_print) begin
      $display("[SB] sb =%b", sb);
      $display("[SB] set=%b", set_busy_req);
      $display("[SB] clr=%b", clear_busy_req);
    end
  end

endmodule
