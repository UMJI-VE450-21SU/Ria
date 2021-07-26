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
  logic         valid;
  // branch prediction
  logic         pred_taken;
  logic [31:0]  pred_addr;
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

typedef enum logic [3:0] {
  BR_X    = 4'h0,
  BR_EQ   = 4'h1,
  BR_NE   = 4'h2,
  BR_LT   = 4'h3,
  BR_GE   = 4'h4,
  BR_LTU  = 4'h5,
  BR_GEU  = 4'h6,
  BR_JAL  = 4'h7,
  BR_JALR = 4'h8
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
  FP_F  = 2'h0,
  FP_D  = 2'h1,
  FP_Q  = 2'h2
} fp_type_t;

typedef enum logic [4:0] {
  FPU_X     = 5'h0,
  FPU_ADD   = 5'h1,
  FPU_SUB   = 5'h2,
  FPU_SQRT  = 5'h3,
  FPU_SGNJ  = 5'h4,
  FPU_SGNJN = 5'h5,
  FPU_SGNJX = 5'h6,
  FPU_MIN   = 5'h7,
  FPU_MAX   = 5'h8,
  FPU_CVTW  = 5'h9,
  FPU_CVTWU = 5'ha,
  FPU_MVX   = 5'hb,
  FPU_EQ    = 5'hc,
  FPU_LT    = 5'hd,
  FPU_LE    = 5'he,
  FPU_CLASS = 5'hf,
  FPU_CVTS  = 5'h10,
  FPU_CVTSU = 5'h11,
  FPU_MVW   = 5'h12,
  FPU_MADD  = 5'h13,
  FPU_MSUB  = 5'h14,
  FPU_NMSUB = 5'h15,
  FPU_NMADD = 5'h16
} fpu_type_t;

typedef enum logic [2:0] {
  RM_RNE  = 3'h0,
  RM_RTZ  = 3'h1,
  RM_RDN  = 3'h2,
  RM_RUP  = 3'h3,
  RM_RMM  = 3'h4,
  RM_DYN  = 3'h7
} rm_type_t;

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
  RS_FROM_IRF   = 3'h1,
  RS_FROM_FRF   = 3'h2,
  RS_FROM_IMM   = 3'h3,
  RS_FROM_ZERO  = 3'h4,
  RS_FROM_PC    = 3'h5,
  RS_FROM_NPC   = 3'h6          // PC +2/+4
} rs_source_t;

typedef struct packed {
  logic [31:0]    pc;
  logic [31:0]    npc;          // Next PC = PC +2/+4
  inst_t          inst;

  rob_index_t     rob_index;

  iq_code_t       iq_code;      // which issue unit do we use?
  fu_code_t       fu_code;      // which functional unit do we use?

  br_type_t       br_type;

  alu_type_t      alu_type;
  imul_type_t     imul_type;
  idiv_type_t     idiv_type;

  fp_type_t       fp_type;
  fpu_type_t      fpu_type;
  rm_type_t       rm_type;

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
  arf_fp_index_t  rs1_arf_fp_index;
  prf_fp_index_t  rs1_prf_fp_index;

  rs_source_t     rs2_source;
  arf_int_index_t rs2_arf_int_index;
  prf_int_index_t rs2_prf_int_index;
  arf_fp_index_t  rs2_arf_fp_index;
  prf_fp_index_t  rs2_prf_fp_index;

  rs_source_t     rs3_source;
  arf_int_index_t rs3_arf_int_index;
  prf_int_index_t rs3_prf_int_index;
  arf_fp_index_t  rs3_arf_fp_index;
  prf_fp_index_t  rs3_prf_fp_index;

  arf_int_index_t rd_arf_int_index;
  prf_int_index_t rd_prf_int_index;
  prf_int_index_t rd_prf_int_index_prev;
  logic           rd_prf_int_index_prev_valid;
  logic           rd_int_valid;

  arf_fp_index_t  rd_arf_fp_index;
  prf_fp_index_t  rd_prf_fp_index;
  prf_fp_index_t  rd_prf_fp_index_prev;
  logic           rd_prf_fp_index_prev_valid;
  logic           rd_fp_valid;

  logic           valid;
  logic           complete;
} micro_op_t;

task print_uop(input micro_op_t uop);
  $display("        pc=%h, iq_code=%h, fu_code=%h, imm=%h, rs1_arf=%h, rs1_prf=%h, rs2_arf=%h, rs2_prf=%h, rd_arf=%h, rd_prf=%h, rd_int_valid=%b, valid=%b",
           uop.pc, uop.iq_code, uop.fu_code, uop.imm, uop.rs1_arf_int_index, uop.rs1_prf_int_index,
           uop.rs2_arf_int_index, uop.rs2_prf_int_index, uop. rd_arf_int_index, uop.rd_prf_int_index, 
           uop.rd_int_valid, uop.valid);
endtask

`endif  // __MICRO_OP_SVH__
