// Project: RISC-V SoC Microarchitecture Design & Optimization
// Header:  Project Macros Definition
// Author:  Yiqiu Sun, Li Shi, Jian Shi
// Date:    2021/05/19

`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__

`define INST_NUM            40

`define FRONTEND_WIDTH      4
`define FETCH_WIDTH         `FRONTEND_WIDTH
`define DECODE_WIDTH        `FRONTEND_WIDTH
`define RENAME_WIDTH        `FRONTEND_WIDTH
`define DISPATCH_WIDTH      `FRONTEND_WIDTH

`define INST_PACK           32 * `FETCH_WIDTH

`define BHT_SIZE            128
`define BHT_INDEX_SIZE      7   // log2(BHT_SIZE)
`define PHT_SIZE            128
`define PHT_INDEX_SIZE      7   // log2(PHT_SIZE)
`define BTB_SIZE            32
`define BTB_INDEX_SIZE      5   // log2(BTB_SIZE)
`define BTB_WIDTH           4
`define BTB_WIDTH_INDEX     2   // log2(BTB_WIDTH)
`define BTB_TAG_SIZE        (`BTB_SIZE - 2 - `BTB_INDEX_SIZE - `BTB_WIDTH_INDEX) // 32-2-7=23

`define FB_SIZE             16
`define FB_ADDR             4

`define ROB_SIZE            64
`define ROB_INDEX_SIZE      6   // log2(ROB_SIZE)

`define ISSUE_WIDTH_INT     3
`define ISSUE_WIDTH_MEM     1
`define ISSUE_WIDTH_FP      2
`define ISSUE_WIDTH_TATAL   (`ISSUE_WIDTH_INT + `ISSUE_WIDTH_MEM + `ISSUE_WIDTH_FP)

`define COMMIT_WIDTH        `ISSUE_WIDTH_TATAL

`define IQ_INT_SIZE         32
`define IQ_MEM_SIZE         16
`define IQ_FP_SIZE          16

`define ARF_INT_SIZE        32
`define ARF_INT_INDEX_SIZE  5

`define ARF_FP_SIZE         32
`define ARF_FP_INDEX_SIZE   5

`define ARF_SIZE            (`ARF_INT_SIZE + `ARF_FP_SIZE)
`define ARF_INDEX_SIZE      6   // log2(ARF_SIZE)

`define PRF_SIZE            128
`define PRF_INDEX_SIZE      7   // log2(PRF_SIZE)
`define PRF_WAYS            `ISSUE_WIDTH_TATAL

`define IMUL_LATENCY        5
`define IDIV_LATENCY        32

typedef logic [`ARF_INDEX_SIZE-1:0] arf_index_t;
typedef logic [`PRF_INDEX_SIZE-1:0] prf_index_t;

typedef logic [`ROB_INDEX_SIZE-1:0] rob_index_t;

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
    logic [4:0]   rs3;
    logic [1:0]   funct2;
    logic [4:0]   rs2;
    logic [4:0]   rs1;
    logic [2:0]   funct3;
    logic [4:0]   rd;
    logic [6:0]   opcode;
  } r4;
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
