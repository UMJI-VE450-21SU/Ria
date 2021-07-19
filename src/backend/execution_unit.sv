// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Execution Units (3 INT + 1 MEM + 2 FP)
// Author:  Li Shi
// Date:    2021/06/21

// Pipe 0/1: ALU + BR
module pipe_0_1 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output micro_op_t uop_out,
  output logic      br_taken,
  output [31:0]     out,
  output            busy
);

  logic [31:0]  alu_out;
  logic [31:0]  br_out;
  micro_op_t    br_uop;
  micro_op_t    uop_next;

  alu alu_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (alu_out)
  );

  branch branch_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .br_taken (br_taken),
    .br_out   (br_out),
    .br_uop   (br_uop)
  );

  always_ff @(posedge clock) begin
    if (reset) begin
      uop_out <= 0;
    end else begin
      uop_out <= uop_next;
    end
  end

  assign out = ({32{uop_out.fu_code == FU_ALU}} & alu_out) |
               ({32{uop_out.fu_code == FU_BR}} & br_out);

  assign uop_next = {uop.fu_code == FU_BR} ? br_uop : uop;

  assign busy = 1'b0;

endmodule


// Pipe 2: IMUL + IDIV
module pipe_2 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output micro_op_t uop_out,
  output [31:0]     out,
  output            busy
);

  micro_op_t   uop_reg;
  logic [31:0] imul_out, idiv_out;
  logic        imul_busy, idiv_busy, ready;

  imul imul_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (imul_out),
    .busy     (imul_busy)
  );

  idiv idiv_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (idiv_out),
    .busy     (idiv_busy)
  );

  always_ff @(posedge clock) begin
    if (reset)
      uop_reg <= 0;
    else if (!busy && uop.valid)
      uop_reg <= uop;
  end

  assign out = ({32{uop_out.fu_code == FU_IMUL}} & imul_out) |
               ({32{uop_out.fu_code == FU_IDIV}} & idiv_out);

  assign busy = imul_busy | idiv_busy;  // busy is synchronous signal
  assign uop_out = busy ? 0 : uop_reg;  // uop_out is synchronous signal

endmodule


// Pipe 3: Memory load/store
module pipe_3 (
  input               clock,
  input               reset,
  input  micro_op_t   uop,
  input  [31:0]       in1,
  input  [31:0]       in2,
  output micro_op_t   uop_out,
  output logic [31:0] out,
  output              busy,

  // ======= dcache related ==================
  input        [63:0]  dcache2core_data,
  input                dcache2core_data_valid,
  output logic [63:0]  core2dcache_data,
  output logic         core2dcache_data_we,
  output mem_size_t    core2dcache_data_size,
  output logic [31:0]  core2dcache_addr
);
  
  micro_op_t uop_reg;
  wire input_valid = uop.valid & (uop.fu_code == FU_MEM);
  reg  is_ld, is_ldu, is_st;
  reg  busy_reg;
  logic [63:0] data_out;

  always_ff @(posedge clock) begin
    if (reset) begin
      is_ld  <= 0;
      is_ldu <= 0;
      is_st  <= 0;
    end else if (input_valid) begin
      is_ld  <= (uop.mem_type == MEM_LD);
      is_ldu <= (uop.mem_type == MEM_LDU);
      is_st  <= (uop.mem_type == MEM_ST);
    end
  end

  // Data memory / cache output (only for ld/ldu)
  always_comb begin
    data_out = 0;
    if (busy_reg & dcache2core_data_valid) begin
      if (is_ld) begin
        case (uop.mem_size)
          MEM_BYTE:  data_out = {{56{dcache2core_data[7]}},  dcache2core_data[7:0]};
          MEM_HALF:  data_out = {{48{dcache2core_data[15]}}, dcache2core_data[15:0]};
          MEM_WORD:  data_out = {{32{dcache2core_data[31]}}, dcache2core_data[31:0]};
          MEM_DWORD: data_out = dcache2core_data;
        endcase
      end
      if (is_ldu) begin
        case (uop.mem_size)
          MEM_BYTE:  data_out = {56'b0, dcache2core_data[7:0]};
          MEM_HALF:  data_out = {48'b0, dcache2core_data[15:0]};
          MEM_WORD:  data_out = {32'b0, dcache2core_data[31:0]};
          MEM_DWORD: data_out = dcache2core_data;
        endcase
      end
    end
  end

  // actually a 2-state FSM (IDLE, BUSY)
  always_ff @(posedge clock) begin
    if (reset) begin
      busy_reg <= 0;
      uop_reg  <= 0;
      core2dcache_addr <= 0;
      core2dcache_data <= 0;
      core2dcache_data_we   <= 0;
      core2dcache_data_size <= 0;
    end else if (!busy_reg & input_valid) begin
      busy_reg <= 1;
      uop_reg  <= uop;
      core2dcache_addr <= in1 + uop.imm;
      core2dcache_data <= {32'b0, in2};
      core2dcache_data_we   <= (uop.mem_type == MEM_ST);
      core2dcache_data_size <= uop.mem_size;
    end else if (busy_reg & (((is_ld | is_ldu) & dcache2core_data_valid) | is_st)) begin
      busy_reg <= 0;
      uop_reg  <= 0;
      core2dcache_addr <= 0;
      core2dcache_data <= 0;
      core2dcache_data_we   <= 0;
      core2dcache_data_size <= 0;
    end
  end

  always_ff @(posedge clock) begin
    if (reset)
      out <= 0;
    else
      out <= data_out[31:0];
    $display("[EX-MEM] c2d_addr=%h, c2d_data=%h, c2d_we=%b, c2d_size=%h", 
             core2dcache_addr, core2dcache_data, core2dcache_data_we, core2dcache_data_size);
  end
  assign uop_out = uop_reg;

  assign busy = busy_reg;

endmodule
