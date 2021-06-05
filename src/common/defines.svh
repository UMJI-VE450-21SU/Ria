`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__

`define FRONTEND_WIDTH      4

`define DECODE_WIDTH        `FRONTEND_WIDTH
`define RENAME_WIDTH        `FRONTEND_WIDTH
`define DISPATCH_WIDTH      `FRONTEND_WIDTH
`define COMMIT_WIDTH        `FRONTEND_WIDTH

`define RAT_CP_SIZE         2
`define RAT_CP_INDEX_SIZE   1   // log2(RAT_CP_SIZE)

`define ISSUE_WIDTH_INT     3
`define ISSUE_WIDTH_MEM     1
`define ISSUE_WIDTH_FP      2

`define IQ_INT_SIZE         16
`define IQ_MEM_SIZE         16
`define IQ_FP_SIZE          16

`define ARF_INT_SIZE        32
`define ARF_INT_INDEX_SIZE  5

`define ARF_FP_SIZE         32
`define ARF_FP_INDEX_SIZE   5

`define PRF_INT_SIZE        64
`define PRF_INT_INDEX_SIZE  6  // log2(PRF_INT_SIZE)
`define PRF_INT_WAYS        3

`define PRF_FP_SIZE         64
`define PRF_FP_INDEX_SIZE   6  // log2(PRF_FP_SIZE)
`define PRF_FP_WAYS         2

typedef logic [`ARF_INT_INDEX_SIZE-1:0] arf_int_index_t;
typedef logic [`ARF_FP_INDEX_SIZE-1:0]  arf_fp_index_t;

typedef logic [`PRF_INT_INDEX_SIZE-1:0] prf_int_index_t;
typedef logic [`PRF_FP_INDEX_SIZE-1:0]  prf_fp_index_t;

// RISCV ISA SPEC
typedef union packed {
  logic [31:0] inst;
  struct packed {
    logic [6:0]   funct7;
    logic [4:0]   rs2;
    logic [4:0]   rs1;
    logic [2:0]   funct3;
    logic [4:0]   rd;
    logic [6:0]   opcode;
  } r;
  struct packed {
    logic [11:0]  imm;
    logic [4:0]   rs1;
    logic [2:0]   funct3;
    logic [4:0]   rd;
    logic [6:0]   opcode;
  } i;
  struct packed {
    logic [6:0]   imm1;   // imm[11:5]
    logic [4:0]   rs2;
    logic [4:0]   rs1;
    logic [2:0]   funct3;
    logic [4:0]   imm0;   // imm[4:0]
    logic [6:0]   opcode;
  } s;
  struct packed {
    logic         imm_3;  // imm[12]
    logic [5:0]   imm_1;  // imm[10:5]
    logic [4:0]   rs2;
    logic [4:0]   rs1;
    logic [2:0]   funct3;
    logic [3:0]   imm_0;  // imm[4:1]
    logic         imm_2;  // imm[11]
    logic [6:0]   opcode;
  } b;
  struct packed {
    logic [19:0]  imm;    // imm[31:12]
    logic [4:0]   rd;
    logic [6:0]   opcode;
  } u;
  struct packed {
    logic         imm_3;  // imm[20]
    logic [9:0]   imm_0;  // imm[10:1]
    logic         imm_1;  // imm[11]
    logic [7:0]   imm_2;  // imm[19:12]
    logic [4:0]   rd;
    logic [6:0]   opcode;
  } j;
  struct packed {
    logic [4:0] funct5;
    logic       aq;
    logic       rl;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;
    logic [6:0] opcode;
  } a;
  struct packed {
    logic [11:0] csr;
    logic [4:0]  rs1;
    logic [2:0]  funct3;
    logic [4:0]  rd;
    logic [6:0]  opcode;
  } sys;
} inst_t;



`endif  // __DEFINES_SVH__
