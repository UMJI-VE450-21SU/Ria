`ifndef __MICRO_OP_SVH__
`define __MICRO_OP_SVH__

`include "defines.svh"
`include "isa.svh"

typedef struct packed {
  logic iq_int;
  logic iq_mem;
  logic iq_fp;
} iq_code_t;

typedef struct packed {
  logic fu_x;   // None of fu is used
  logic fu_alu;
  logic fu_br;
  logic fu_mem;
  logic fu_mul;
  logic fu_div;
  logic fu_csr;
  logic fu_fpu;
  logic fu_fdiv;
} fu_code_t;

typedef struct packed {
  logic br_x;     // Don't care, not a branch instruction
  logic br_eq;
  logic br_ne;
  logic br_lt;
  logic br_ge;
  logic br_ltu;
  logic br_geu;
} br_type_t;

typedef struct packed {
  logic fn_x;     // Don't care
  logic fn_add;
  logic fn_sub;
  logic fn_slt;
  logic fn_sltu;
  logic fn_xor;
  logic fn_or;
  logic fn_and;
  logic fn_sll;
  logic fn_srl;
  logic fn_sra;
} alu_type_t;

typedef struct packed {
  logic [31:0]    pc;
  inst_t          inst;
  iq_code_t       iq_code;      // which issue unit do we use?
  fu_code_t       fu_code;      // which functional unit do we use?
  
  br_type_t       br_type;
  alu_type_t      alu_type;

  logic [31:0]    imm;

  arf_int_index_t rs1_arf_int_index;
  prf_int_index_t rs1_prf_int_index;
  logic           rs1_valid;

  arf_int_index_t rs2_arf_int_index;
  prf_int_index_t rs2_prf_int_index;
  logic           rs2_valid;

  arf_int_index_t rd_arf_int_index;
  prf_int_index_t rd_prf_int_index;
  prf_int_index_t rd_prf_int_index_prev;
  logic           rd_valid;

  logic           valid;
} micro_op_t;

`define CP_NUM          2   // amount of check point
`define CP_INDEX_SIZE   1   // log2(CP_NUM)

`endif  // __MICRO_OP_SVH__
