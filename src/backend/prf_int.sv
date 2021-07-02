// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Physical Register File for Integers
// Author:  Li Shi
// Date:    2021/06/21

`include "src/common/micro_op.svh"

module prf_int_data (
  input                                                 clock,
  input                                                 reset,
  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rs1_index,
  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rs2_index,
  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rd_index,
  input  [`PRF_INT_WAYS-1:0] [31:0]                     rd_data,
  input  [`PRF_INT_WAYS-1:0]                            rd_en,
  output logic [`PRF_INT_WAYS-1:0] [31:0]               rs1_data,
  output logic [`PRF_INT_WAYS-1:0] [31:0]               rs2_data
);

  // multi-bank register file
  reg   [31:0] rf [`PRF_INT_WAYS-1:0][`PRF_INT_SIZE-1:0];

  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_WAYS-1:0] rs1_from_rd;
  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_WAYS-1:0] rs2_from_rd;

  // generate bypass logic (rs1/rs2 <- rd)
  generate
    for(genvar i = 0; i < `PRF_INT_WAYS; i++) begin
      for(genvar j = 0; j < `PRF_INT_WAYS; j++) begin
        assign rs1_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs1_index[i]);
        assign rs2_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs2_index[i]);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i++) begin
      rs1_data[i] = rf[i][rs1_index[i]];
      rs2_data[i] = rf[i][rs2_index[i]];
      for (int j = 0; j < `PRF_INT_WAYS; j++) begin
        if(rs1_from_rd[i][j])
          rs1_data[i] = rd_data[j];  
        if(rs2_from_rd[i][j])
          rs2_data[i] = rd_data[j];
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `PRF_INT_WAYS; i++)
        for (int j = 0; j < `PRF_INT_SIZE; j++)
          rf[i][j] <= 0;
    end else begin
      for (int i = 0; i < `PRF_INT_WAYS; i++)
        if (rd_en[i])
          for (int j = 0; j < `PRF_INT_WAYS; j++)
            rf[j][rd_index[i]] <= rd_data[i];
    end
  end

endmodule


module prf_int (
  input                                                 clock,
  input                                                 reset,
  input  micro_op_t [`PRF_INT_WAYS-1:0]                 uop_in,

  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rd_index,
  input  [`PRF_INT_WAYS-1:0] [31:0]                     rd_data,
  input  [`PRF_INT_WAYS-1:0]                            rd_en,
  
  output micro_op_t [`PRF_INT_WAYS-1:0]                 uop_out,
  output reg [`PRF_INT_WAYS-1:0] [31:0]                 rs1_data,
  output reg [`PRF_INT_WAYS-1:0] [31:0]                 rs2_data
);

  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0] rs1_index, rs2_index;
  wire  [`PRF_INT_WAYS-1:0] [31:0]                    rs1_data_tmp, rs2_data_tmp;

  // Input source (PRF Index) selection
  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i++) begin
      case (uop_in[i].rs1_source)
        RS_INVALID  : rs1_index[i] = 0;
        RS_FROM_RF  : rs1_index[i] = uop_in[i].rs1_prf_int_index;
        RS_FROM_IMM : rs1_index[i] = 0;
        RS_FROM_ZERO: rs1_index[i] = 0;
        RS_FROM_PC  : rs1_index[i] = 0;
        RS_FROM_NPC : rs1_index[i] = 0;
      endcase
      case (uop_in[i].rs2_source)
        RS_INVALID  : rs2_index[i] = 0;
        RS_FROM_RF  : rs2_index[i] = uop_in[i].rs2_prf_int_index;
        RS_FROM_IMM : rs2_index[i] = 0;
        RS_FROM_ZERO: rs2_index[i] = 0;
        RS_FROM_PC  : rs2_index[i] = 0;
        RS_FROM_NPC : rs2_index[i] = 0;
      endcase
    end
  end

  // Output source selection
  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i++) begin
      case (uop_in[i].rs1_source)
        RS_INVALID  : rs1_data[i] = 0;
        RS_FROM_RF  : rs1_data[i] = rs1_data_tmp[i];
        RS_FROM_IMM : rs1_data[i] = uop_in[i].imm;
        RS_FROM_ZERO: rs1_data[i] = 0;
        RS_FROM_PC  : rs1_data[i] = uop_in[i].pc;
        RS_FROM_NPC : rs1_data[i] = uop_in[i].npc;
      endcase
      case (uop_in[i].rs2_source)
        RS_INVALID  : rs2_data[i] = 0;
        RS_FROM_RF  : rs2_data[i] = rs2_data_tmp[i];
        RS_FROM_IMM : rs2_data[i] = uop_in[i].imm;
        RS_FROM_ZERO: rs2_data[i] = 0;
        RS_FROM_PC  : rs2_data[i] = uop_in[i].pc;
        RS_FROM_NPC : rs2_data[i] = uop_in[i].npc;
      endcase
    end
  end

  prf_int_data prf_int_data_inst (
    .clock      (clock),
    .reset      (reset),
    .rs1_index  (rs1_index),
    .rs2_index  (rs2_index),
    .rd_index   (rd_index),
    .rd_data    (rd_data),
    .rd_en      (rd_en),
    .rs1_data   (rs1_data_tmp),
    .rs2_data   (rs2_data_tmp)
  );

  assign uop_out = uop_in;

endmodule
