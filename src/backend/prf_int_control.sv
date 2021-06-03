`include "defines.svh"

module prf_int_control (
  input                                                 clock,
  input                                                 reset,
  input  micro_op_t [`PRF_INT_WAYS]                     uop_in,

  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rd_index,
  input  [`PRF_INT_WAYS-1:0] [31:0]                     rd_data,
  input  [`PRF_INT_WAYS-1:0]                            rd_en,
  
  output micro_op_t [`PRF_INT_WAYS]                     uop_out,
  output reg [`PRF_INT_WAYS-1:0] [31:0]                 rs1_data,
  output reg [`PRF_INT_WAYS-1:0] [31:0]                 rs2_data,
);

  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0] rs1_index, rs2_index;
  wire  [`PRF_INT_WAYS-1:0] [31:0]                    rs1_data_tmp, rs2_data_tmp;

  // Input source (PRF Index) selection
  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i++) begin
      case (uop_in[i].rs1_source)
        RS_INVALID  : rs1_index[i] = 0;
        RS_FROM_RF  : rs1_index[i] = uop_in[i].prf_int_index;
        RS_FROM_IMM : rs1_index[i] = 0;
        RS_FROM_ZERO: rs1_index[i] = 0;
        RS_FROM_PC  : rs1_index[i] = 0;
        RS_FROM_NPC : rs1_index[i] = 0;
      endcase
      case (uop_in[i].rs2_source)
        RS_INVALID  : rs2_index[i] = 0;
        RS_FROM_RF  : rs2_index[i] = uop_in[i].prf_int_index;
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
        RS_INVALID  : rs1_data[i] = 0；
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

  prf_int prf_int_inst (
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

endmodule
