// Project: RISC-V SoC Microarchitecture Design & Optimization
// Header:  Micro-operation (uop) Definition
// Author:  Yiqiu Sun, Li Shi, Jian Shi
// Date:    2021/05/19

`ifndef __MICRO_OP_SVH__
`define __MICRO_OP_SVH__

`include "src/common/defines.svh"
`include "src/common/isa.svh"

typedef struct packed {
  logic [31:0]  pc;
  inst_t        inst;   // fetched instruction
} fb_entry_t;

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
  BR_GEU  = 3'h6
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

typedef enum logic [1:0] {
  IMUL_MUL    = 2'h0,           // signed x signed
  IMUL_MULH   = 2'h1,           // signed x signed
  IMUL_MULHSU = 2'h2,           // unsigned x signed
  IMUL_MULHU  = 2'h3            // unsigned x unsigned
} imul_type_t;

typedef enum logic [1:0] {
  IDIV_DIV    = 2'h0,
  IDIV_DIVU   = 2'h1,
  IDIV_REM    = 2'h2,
  IDIV_REMU   = 2'h3
} idiv_type_t;

typedef enum logic [1:0] {
  MEM_LD  = 2'h0,
  MEM_LDU = 2'h1,
  MEM_ST  = 2'h2
} mem_type_t;

typedef enum logic [1:0] {
  MEM_BYTE  = 2'h0,
  MEM_HALF  = 2'h1,
  MEM_WORD  = 2'h2,
  MEM_DWORD = 2'h3
} mem_size_t;

typedef enum logic [2:0] { 
  RS_INVALID    = 3'h0,
  RS_FROM_RF    = 3'h1,
  RS_FROM_IMM   = 3'h2,
  RS_FROM_ZERO  = 3'h3,
  RS_FROM_PC    = 3'h4,
  RS_FROM_NPC   = 3'h5          // PC +2/+4
} rs_source_t;

typedef struct packed {
  logic [31:0]    pc;
  logic [31:0]    npc;          // Next PC = PC +2/+4
  inst_t          inst;

  cp_index_t      cp_index;
  rob_index_t     rob_index;

  iq_code_t       iq_code;      // which issue unit do we use?
  fu_code_t       fu_code;      // which functional unit do we use?

  br_type_t       br_type;
  alu_type_t      alu_type;
  imul_type_t     imul_type;
  idiv_type_t     idiv_type;
  mem_type_t      mem_type;
  mem_size_t      mem_size;

  logic           br_taken;
  logic [31:0]    br_addr;

  logic           pred_taken;
  logic [31:0]    pred_addr;

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
  logic           rd_prf_int_index_prev_valid;
  logic           rd_valid;

  logic           valid;
  logic           complete;
} micro_op_t;

task print_uop(input micro_op_t uop);
  $display("        pc=%h, iq_code=%h, fu_code=%h, imm=%h, rs1_arf=%h, rs1_prf=%h, rs2_arf=%h, rs2_prf=%h, rd_arf=%h, rd_prf=%h, rd_valid=%b, valid=%b",
           uop.pc, uop.iq_code, uop.fu_code, uop.imm, uop.rs1_arf_int_index, uop.rs1_prf_int_index,
           uop.rs2_arf_int_index, uop.rs2_prf_int_index, uop. rd_arf_int_index, uop.rd_prf_int_index, 
           uop.rd_valid, uop.valid);
endtask

`endif  // __MICRO_OP_SVH__
