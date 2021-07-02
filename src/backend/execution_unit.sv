// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Execution Units (3 INT + 1 MEM + 2 FP)
// Author:  Li Shi
// Date:    2021/06/21

// Pipe 0: ALU + BR
module pipe_0 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output micro_op_t uop_out,
  output [31:0]     out,
  output            busy
);

  logic [31:0]  alu_out;
  logic         br_out;

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
    .out      (br_out)
  );

  always_ff @(posedge clock) begin
    if (reset) begin
      uop_out <= 0;
    end else begin
      uop_out <= uop;
    end
  end

  assign out = ({32{uop.fu_code == FU_ALU}} & alu_out) |
               ({32{uop.fu_code == FU_BR}} & {32{br_out}});

  assign busy = 1'b0;

endmodule


// Pipe 1: ALU + IMUL
module pipe_1 (
  input             clock,
  input             reset,
  input  micro_op_t uop,
  input  [31:0]     in1,
  input  [31:0]     in2,
  output micro_op_t uop_out,
  output [31:0]     out,
  output            busy
);

  wire                            input_valid = uop.valid;
  micro_op_t [`IMUL_LATENCY-1:0]  uop_fifo;
  logic [31:0]                    alu_out, imul_out;

  always_ff @(posedge clock) begin
    if (reset) begin
      uop_fifo <= 0;
    end else begin
      if (input_valid & (uop.fu_code == FU_ALU)) begin
        uop_fifo[0] <= uop;
      end else begin
        uop_fifo[0] <= uop_fifo[1];
      end
      for (int i = 1; i < `IMUL_LATENCY - 1; i++) begin
        uop_fifo[i] <= uop_fifo[i + 1];
      end
      if (input_valid & (uop.fu_code == FU_IMUL)) begin
        uop_fifo[`IMUL_LATENCY - 1] <= uop;
      end else begin
        uop_fifo[`IMUL_LATENCY - 1] <= 0;
      end
    end
  end

  alu alu_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (alu_out)
  );

  imul imul_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (imul_out)
  );

  assign out = ({32{uop_fifo[0].fu_code == FU_ALU}}  & alu_out) |
               ({32{uop_fifo[0].fu_code == FU_IMUL}} & imul_out);

  assign busy = 1'b0;

endmodule


// Pipe 2: ALU + IDIV
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

  wire                            input_valid = uop.valid;
  micro_op_t [`IDIV_LATENCY-1:0]  uop_fifo;
  logic [31:0]                    alu_out, idiv_out;

  always_ff @(posedge clock) begin
    if (reset) begin
      uop_fifo <= 0;
    end else begin
      if (input_valid & (uop.fu_code == FU_ALU)) begin
        uop_fifo[0] <= uop;
      end else begin
        uop_fifo[0] <= uop_fifo[1];
      end
      for (int i = 1; i < `IDIV_LATENCY - 1; i++) begin
        uop_fifo[i] <= uop_fifo[i + 1];
      end
      if (input_valid & (uop.fu_code == FU_IDIV)) begin
        uop_fifo[`IDIV_LATENCY - 1] <= uop;
      end else begin
        uop_fifo[`IDIV_LATENCY - 1] <= 0;
      end
    end
  end

  alu alu_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (alu_out)
  );

  // todo: Add a idiv module
  imul idiv_inst (
    .clock    (clock),
    .reset    (reset),
    .uop      (uop),
    .in1      (in1),
    .in2      (in2),
    .out      (idiv_out)
  );

  assign out = ({32{uop_fifo[0].fu_code == FU_ALU}}  & alu_out) |
               ({32{uop_fifo[0].fu_code == FU_IDIV}} & idiv_out);

  assign busy = 1'b0;

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

  // Data memory / cache input
  always_comb begin
    core2dcache_addr = 0;
    core2dcache_data = 0;
    core2dcache_data_we = 0;
    if (busy_reg) begin
      core2dcache_addr = in1 + uop.imm;
      if (is_st) begin
        core2dcache_data = in2;
        core2dcache_data_we = 1;
      end
    end
  end

  assign core2dcache_data_size = uop.mem_size;

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
    if (reset)
      busy_reg <= 0;
    else if (!busy_reg & input_valid)
      busy_reg <= 1;
    else if (busy_reg & (is_ld | is_ldu) & dcache2core_data_valid)
      busy_reg <= 0;
    else if (busy_reg & is_st)
      busy_reg <= 0;
  end

  always_ff @(posedge clock) begin
    if (reset)
      out <= 0;
    else
      out <= data_out;
  end

  assign busy = busy_reg;

endmodule
