`ifndef __MICRO_OP_SVH__
`define __MICRO_OP_SVH__

`include "defines.svh"
`include "isa.svh"

typedef enum logic [1:0] {
  IQ_X    = 2'h0,
  IQ_INT  = 2'h1,
  IQ_MEM  = 2'h2,
  IQ_FP   = 2'h3
} iq_code_t;

typedef enum logic [3:0] {
  FU_X    = 4'h0,
  FU_ALU  = 4'h1,
  FU_BR   = 4'h2,
  FU_IMUL = 4'h3,
  FU_IDIV = 4'h4,
  FU_MEM  = 4'h5,
  FU_FPU  = 4'h6,
  FU_FMUL = 4'h7,
  FU_FDIV = 4'h8,
  FU_CSR  = 4'h9
} fu_code_t;

typedef enum logic [2:0] {
  BR_X    = 3'h0,
  BR_EQ   = 3'h1,
  BR_NE   = 3'h2,
  BR_LT   = 3'h3,
  BR_GE   = 3'h4,
  BR_LTU  = 3'h5,
  BR_GEU  = 3'h6,
} br_type_t;

typedef enum logic [3:0] {
  ALU_X    = 4'h0,
  ALU_ADD  = 4'h1,
  ALU_SUB  = 4'h2,
  ALU_SLT  = 4'h3,
  ALU_SLTU = 4'h4,
  ALU_XOR  = 4'h5,
  ALU_OR   = 4'h6,
  ALU_AND  = 4'h7,
  ALU_SLL  = 4'h8,
  ALU_SRL  = 4'h9,
  ALU_SRA  = 4'ha
} alu_type_t;

typedef enum logic [2:0] { 
  RS_INVALID    = 3'h0;
  RS_FROM_RF    = 3'h1;
  RS_FROM_IMM   = 3'h2;
  RS_FROM_ZERO  = 3'h3;
  RS_FROM_PC    = 3'h4;
  RS_FROM_NPC   = 3'h5;  // PC +2/+4
} rs_source_t;

typedef struct packed {
  logic [31:0]    pc;
  inst_t          inst;
  iq_code_t       iq_code;      // which issue unit do we use?
  fu_code_t       fu_code;      // which functional unit do we use?
  
  br_type_t       br_type;
  alu_type_t      alu_type;

  logic [31:0]    imm;

  rs_source_t     rs1_source;
  arf_int_index_t rs1_arf_int_index;
  prf_int_index_t rs1_prf_int_index;
  logic           rs1_from_ctb;       // rs1 prf index from common tag bus

  rs_source_t     rs2_source;
  arf_int_index_t rs2_arf_int_index;
  prf_int_index_t rs2_prf_int_index;
  logic           rs2_from_ctb;       // rs2 prf index from common tag bus

  arf_int_index_t rd_arf_int_index;
  prf_int_index_t rd_prf_int_index;
  prf_int_index_t rd_prf_int_index_prev;
  logic           rd_valid;

  logic           valid;
} micro_op_t;

`endif  // __MICRO_OP_SVH__