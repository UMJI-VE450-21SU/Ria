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
  logic fu_i2f;
  logic fu_f2i;
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
} op_type_t;

typedef struct packed {
  logic op1_rs1;
  logic op1_zero;
  logic op1_pc;
  logic op1_x;      // don't care
} op1_sel_t;

typedef struct packed {
  logic op2_rs2;
  logic op2_imm;
  logic op2_zero;
  logic op2_next;   // constant 4 (for PC+4)
  logic op2_immc;   // for CSR imm found in RS1
  logic op2_x;      // don't care
} op2_sel_t;

type struct packed {
  logic imm_i;
  logic imm_s;
  logic imm_b;
  logic imm_u;
  logic imm_j;
  logic imm_x;      // don't care
} imm_sel_t;

typedef struct packed {
  br_type_t br_type;
  op1_sel_t op1_sel;
  op2_sel_t op2_sel;
  imm_sel_t imm_sel;
  op_type_t op_type;

  logic     is_load;
  logic     is_sta;   // will invoke TLB address lookup
  logic     is_std;   // will invoke TLB address lookup
} ctrl_signal_t;

typedef struct packed {
  inst_t        inst;
  iq_code_t     iq_code;      // which issue unit do we use?
  fu_code_t     fu_code;      // which functional unit do we use?
  ctrl_signal_t ctrl_signal;

  logic         is_br;
  logic         is_jal;
  logic         is_jalr;
} micro_op_t;

`endif  // __MICRO_OP_SVH__
