// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Physical Register File
// Author:  Li Shi
// Date:    2021/06/21

`include "src/common/micro_op.svh"

module prf_data (
  input                                         clock,
  input                                         reset,
  input  [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0]  rs1_index,
  input  [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0]  rs2_index,
  input  [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0]  rs3_index,
  input  [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0]  rd_index,
  input  [`PRF_WAYS-1:0] [63:0]                 rd_data,
  input  [`PRF_WAYS-1:0]                        rd_en,
  output logic [`PRF_WAYS-1:0] [63:0]           rs1_data,
  output logic [`PRF_WAYS-1:0] [63:0]           rs2_data,
  output logic [`PRF_WAYS-1:0] [63:0]           rs3_data
);

  // multi-bank register file
  reg   [63:0] rf [`PRF_WAYS-1:0][`PRF_SIZE-1:0];

  logic [`PRF_WAYS-1:0] [`PRF_WAYS-1:0] rs1_from_rd;
  logic [`PRF_WAYS-1:0] [`PRF_WAYS-1:0] rs2_from_rd;
  logic [`PRF_WAYS-1:0] [`PRF_WAYS-1:0] rs3_from_rd;

  // generate bypass logic (rs1/rs2 <- rd)
  generate
    for(genvar i = 0; i < `PRF_WAYS; i++) begin
      for(genvar j = 0; j < `PRF_WAYS; j++) begin
        assign rs1_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs1_index[i]) && (rs1_index[i] != 0);
        assign rs2_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs2_index[i]) && (rs2_index[i] != 0);
        assign rs3_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs3_index[i]) && (rs3_index[i] != 0);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `PRF_WAYS; i++) begin
      rs1_data[i] = (rs1_index[i] != 0) ? rf[i][rs1_index[i]] : 0;
      rs2_data[i] = (rs2_index[i] != 0) ? rf[i][rs2_index[i]] : 0;
      rs3_data[i] = (rs3_index[i] != 0) ? rf[i][rs3_index[i]] : 0;
      for (int j = 0; j < `PRF_WAYS; j++) begin
        if(rs1_from_rd[i][j])
          rs1_data[i] = rd_data[j];
        if(rs2_from_rd[i][j])
          rs2_data[i] = rd_data[j];
        if(rs3_from_rd[i][j])
          rs3_data[i] = rd_data[j];
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (int i = 0; i < `PRF_WAYS; i++)
        for (int j = 0; j < `PRF_SIZE; j++)
          rf[i][j] <= 0;
    end else begin
      for (int i = 0; i < `PRF_WAYS; i++)
        if (rd_en[i] && rd_index[i] != 0)
          for (int j = 0; j < `PRF_WAYS; j++)
            rf[j][rd_index[i]] <= rd_data[i];
    end
  end

endmodule


module prf (
  input                                         clock,
  input                                         reset,
  input  micro_op_t [`PRF_WAYS-1:0]             uop_in,

  input  [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0]  rd_index,
  input  [`PRF_WAYS-1:0] [63:0]                 rd_data,
  input  [`PRF_WAYS-1:0]                        rd_en,

  output micro_op_t [`PRF_WAYS-1:0]             uop_out,
  output reg [`PRF_WAYS-1:0] [63:0]             rs1_data,
  output reg [`PRF_WAYS-1:0] [63:0]             rs2_data,
  output reg [`PRF_WAYS-1:0] [63:0]             rs3_data
);

  logic [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0]   rs1_index, rs2_index, rs3_index;
  wire  [`PRF_WAYS-1:0] [63:0]                  rs1_data_tmp, rs2_data_tmp, rs3_data_tmp;

  // Input source (PRF Index) selection
  always_comb begin
    for (int i = 0; i < `PRF_WAYS; i++) begin
      case (uop_in[i].rs1_source)
        RS_INVALID  : rs1_index[i] = 0;
        RS_FROM_RF  : rs1_index[i] = uop_in[i].rs1_prf_index;
        RS_FROM_IMM : rs1_index[i] = 0;
        RS_FROM_ZERO: rs1_index[i] = 0;
        RS_FROM_PC  : rs1_index[i] = 0;
        RS_FROM_NPC : rs1_index[i] = 0;
        default:      rs1_index[i] = 0;
      endcase
      case (uop_in[i].rs2_source)
        RS_INVALID  : rs2_index[i] = 0;
        RS_FROM_RF  : rs2_index[i] = uop_in[i].rs2_prf_index;
        RS_FROM_IMM : rs2_index[i] = 0;
        RS_FROM_ZERO: rs2_index[i] = 0;
        RS_FROM_PC  : rs2_index[i] = 0;
        RS_FROM_NPC : rs2_index[i] = 0;
        default:      rs2_index[i] = 0;
      endcase
      case (uop_in[i].rs3_source)
        RS_INVALID  : rs3_index[i] = 0;
        RS_FROM_RF  : rs3_index[i] = uop_in[i].rs3_prf_index;
        RS_FROM_IMM : rs3_index[i] = 0;
        RS_FROM_ZERO: rs3_index[i] = 0;
        RS_FROM_PC  : rs3_index[i] = 0;
        RS_FROM_NPC : rs3_index[i] = 0;
        default:      rs3_index[i] = 0;
      endcase
    end
  end

  // Output source selection
  always_comb begin
    for (int i = 0; i < `PRF_WAYS; i++) begin
      case (uop_in[i].rs1_source)
        RS_INVALID  : rs1_data[i] = 0;
        RS_FROM_RF  : rs1_data[i] = rs1_data_tmp[i];
        RS_FROM_IMM : rs1_data[i] = uop_in[i].imm;
        RS_FROM_ZERO: rs1_data[i] = 0;
        RS_FROM_PC  : rs1_data[i] = uop_in[i].pc;
        RS_FROM_NPC : rs1_data[i] = uop_in[i].npc;
        default:      rs1_data[i] = 0;
      endcase
      case (uop_in[i].rs2_source)
        RS_INVALID  : rs2_data[i] = 0;
        RS_FROM_RF  : rs2_data[i] = rs2_data_tmp[i];
        RS_FROM_IMM : rs2_data[i] = uop_in[i].imm;
        RS_FROM_ZERO: rs2_data[i] = 0;
        RS_FROM_PC  : rs2_data[i] = uop_in[i].pc;
        RS_FROM_NPC : rs2_data[i] = uop_in[i].npc;
        default:      rs2_data[i] = 0;
      endcase
      case (uop_in[i].rs3_source)
        RS_INVALID  : rs3_data[i] = 0;
        RS_FROM_RF  : rs3_data[i] = rs3_data_tmp[i];
        RS_FROM_IMM : rs3_data[i] = uop_in[i].imm;
        RS_FROM_ZERO: rs3_data[i] = 0;
        RS_FROM_PC  : rs3_data[i] = uop_in[i].pc;
        RS_FROM_NPC : rs3_data[i] = uop_in[i].npc;
        default:      rs3_data[i] = 0;
      endcase
    end
  end

  prf_data prf_data_inst (
    .clock      (clock),
    .reset      (reset),
    .rs1_index  (rs1_index),
    .rs2_index  (rs2_index),
    .rs3_index  (rs3_index),
    .rd_index   (rd_index),
    .rd_data    (rd_data),
    .rd_en      (rd_en),
    .rs1_data   (rs1_data_tmp),
    .rs2_data   (rs2_data_tmp),
    .rs3_data   (rs3_data_tmp)
  );

  assign uop_out = uop_in;

endmodule
