// Project: RISC-V SoC Microarchitecture Design & Optimization
// Header:  RISC-V ISA Definition
// Author:  Li Shi
// Date:    2021/05/19

`ifndef __ISA_SVH__
`define __ISA_SVH__

// RV32 Instruction Set

// ---------- Opcode ------------------------------------------------------- //
`define RV32_OP_LUI     7'b0110111
`define RV32_OP_AUIPC   7'b0010111
`define RV32_OP_JAL     7'b1101111
`define RV32_OP_JALR    7'b1100111

// BRANCH: BEQ, BNE, BLT, BGE, BLTU, BGEU
`define RV32_OP_BRANCH  7'b1100011

// LOAD: LB, LH, LBU, LHU
`define RV32_OP_LOAD    7'b0000011

// STORE: SB, SH, SW
`define RV32_OP_STORE   7'b0100011

// OP_IMM: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
`define RV32_OP_IMM     7'b0010011

// OP: 
// (I) ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
// (M) MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
`define RV32_OP         7'b0110011

// FENCE: 
// (I) FENCE
// (Zifencei) FENCE.I
`define RV32_OP_FENCE   7'b0001111

// SYSTEM: 
// (I) ECALL, EBREAK
// (Ziscr) CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CRRCI
//         URET, SRET, MRET, WRI
`define RV32_OP_SYSTEM  7'b1110011

// AMO: LR.W, SC.W, AMOSWAP.W, AMOADD.W, AMOXOR.W, AMOAND.W, AMOOR.W,
//      AMOMIN.W, AMOMAX.W, AMOMINU.W, AMOMAXU.W
`define RV32_OP_AMO     7'b0101111

// LOAD_FP: FLW, FLD
`define RV32_OP_LOAD_FP 7'b0000111

// STORE_FP: FSW, FSD
`define RV32_OP_STORE_FP 7'b0100111

`define RV32_OP_FMADD   7'b1000011
`define RV32_OP_FMSUB   7'b1000111
`define RV32_OP_FNMSUB  7'b1001011
`define RV32_OP_FNMADD  7'b1001111

// OP_FP: FADD, FSUB, FMUL, FDIV, FSQRT, FSGNJ, FSGNJN, FSGNJX, FMIN, FMAX, 
//        FCVT, FEQ, FLT, FLE, FCLASS, FMV.X.W, FMV.W.X
`define RV32_OP_FP      7'b1010011


// ---------- Types -------------------------------------------------------- //
`define RV32_R_t(op, funct3, funct7)          {``funct7`` , {5{1'b?}} , {5{1'b?}} , ``funct3``, {5{1'b?}} , ``op``    }
`define RV32_R4_t(op, funct3, funct2)         {{5{1'b?}}  , ``funct2``, {5{1'b?}} , {5{1'b?}} , ``funct3``, {5{1'b?}} , ``op``}
`define RV32_I_t(op, funct3)                  {{12{1'b?}} , {5{1'b?}} , ``funct3``, {5{1'b?}} , ``op``    }
`define RV32_S_t(op, funct3)                  {{7{1'b?}}  , {5{1'b?}} , {5{1'b?}} , ``funct3``, {5{1'b?}} , ``op``    }
`define RV32_B_t(op, funct3)                  {{7{1'b?}}  , {5{1'b?}} , {5{1'b?}} , ``funct3``, {5{1'b?}} , ``op``    }
`define RV32_U_t(op)                          {{20{1'b?}} , {5{1'b?}} , ``op``    }
`define RV32_J_t(op)                          {{20{1'b?}} , {5{1'b?}} , ``op``    }
`define RV32_F_t(op, funct3, funct5, funct7)  {``funct7`` , ``funct5``, {5{1'b?}} , ``funct3``, {5{1'b?}} , ``op``    }


// ---------- Instruction encoding ----------------------------------------- //

// RV32I
`define RV32_LUI        `RV32_U_t(`RV32_OP_LUI)
`define RV32_AUIPC      `RV32_U_t(`RV32_OP_AUIPC)
`define RV32_JAL        `RV32_U_t(`RV32_OP_JAL)
`define RV32_JALR       `RV32_I_t(`RV32_OP_JALR, 3'b000)
`define RV32_BEQ        `RV32_B_t(`RV32_OP_BRANCH, 3'b000)
`define RV32_BNE        `RV32_B_t(`RV32_OP_BRANCH, 3'b001)
`define RV32_BLT        `RV32_B_t(`RV32_OP_BRANCH, 3'b100)
`define RV32_BGE        `RV32_B_t(`RV32_OP_BRANCH, 3'b101)
`define RV32_BLTU       `RV32_B_t(`RV32_OP_BRANCH, 3'b110)
`define RV32_BGEU       `RV32_B_t(`RV32_OP_BRANCH, 3'b111)
`define RV32_LB         `RV32_I_t(`RV32_OP_LOAD, 3'b000)
`define RV32_LH         `RV32_I_t(`RV32_OP_LOAD, 3'b001)
`define RV32_LW         `RV32_I_t(`RV32_OP_LOAD, 3'b010)
`define RV32_LBU        `RV32_I_t(`RV32_OP_LOAD, 3'b100)
`define RV32_LHU        `RV32_I_t(`RV32_OP_LOAD, 3'b101)
`define RV32_SB         `RV32_S_t(`RV32_OP_STORE, 3'b000)
`define RV32_SH         `RV32_S_t(`RV32_OP_STORE, 3'b001)
`define RV32_SW         `RV32_S_t(`RV32_OP_STORE, 3'b010)
`define RV32_ADDI       `RV32_I_t(`RV32_OP_IMM, 3'b000)
`define RV32_SLTI       `RV32_I_t(`RV32_OP_IMM, 3'b010)
`define RV32_SLTIU      `RV32_I_t(`RV32_OP_IMM, 3'b011)
`define RV32_XORI       `RV32_I_t(`RV32_OP_IMM, 3'b100)
`define RV32_ORI        `RV32_I_t(`RV32_OP_IMM, 3'b110)
`define RV32_ANDI       `RV32_I_t(`RV32_OP_IMM, 3'b111)
`define RV32_SLLI       `RV32_R_t(`RV32_OP_IMM, 3'b001, 7'b0000000)
`define RV32_SRLI       `RV32_R_t(`RV32_OP_IMM, 3'b101, 7'b0000000)
`define RV32_SRAI       `RV32_R_t(`RV32_OP_IMM, 3'b101, 7'b0100000)
`define RV32_ADD        `RV32_R_t(`RV32_OP, 3'b000, 7'b0000000)
`define RV32_SUB        `RV32_R_t(`RV32_OP, 3'b000, 7'b0100000)
`define RV32_SLL        `RV32_R_t(`RV32_OP, 3'b001, 7'b0000000)
`define RV32_SLT        `RV32_R_t(`RV32_OP, 3'b010, 7'b0000000)
`define RV32_SLTU       `RV32_R_t(`RV32_OP, 3'b011, 7'b0000000)
`define RV32_XOR        `RV32_R_t(`RV32_OP, 3'b100, 7'b0000000)
`define RV32_SRL        `RV32_R_t(`RV32_OP, 3'b101, 7'b0000000)
`define RV32_SRA        `RV32_R_t(`RV32_OP, 3'b101, 7'b0100000)
`define RV32_OR         `RV32_R_t(`RV32_OP, 3'b110, 7'b0000000)
`define RV32_AND        `RV32_R_t(`RV32_OP, 3'b111, 7'b0000000)
`define RV32_FENCE      `RV32_I_t(`RV32_OP_FENCE, 3'b000)
`define RV32_ECALL      {25'b0, `RV32_OP_SYSTEM}
`define RV32_EBREAK     {11'b0, 1'b1, 13'b0, `RV32_OP_SYSTEM}

// RV32 Zifencei
`define RV32_FENCE_I    `RV32_I_t(`RV32_OP_FENCE, 3'b001)

// RV32 Zicsr
`define RV32_CSRRW      `RV32_I_t(`RV32_OP_SYSTEM, 3'b001)
`define RV32_CSRRS      `RV32_I_t(`RV32_OP_SYSTEM, 3'b010)
`define RV32_CSRRC      `RV32_I_t(`RV32_OP_SYSTEM, 3'b011)
`define RV32_CSRRWI     `RV32_I_t(`RV32_OP_SYSTEM, 3'b101)
`define RV32_CSRRSI     `RV32_I_t(`RV32_OP_SYSTEM, 3'b110)
`define RV32_CSRRCI     `RV32_I_t(`RV32_OP_SYSTEM, 3'b111)

// RV32M
`define RV32_MUL        `RV32_R_t(`RV32_OP, 3'b000, 7'b0000001) 
`define RV32_MULH       `RV32_R_t(`RV32_OP, 3'b001, 7'b0000001) 
`define RV32_MULHSU     `RV32_R_t(`RV32_OP, 3'b010, 7'b0000001) 
`define RV32_MULHU      `RV32_R_t(`RV32_OP, 3'b011, 7'b0000001) 
`define RV32_DIV        `RV32_R_t(`RV32_OP, 3'b100, 7'b0000001) 
`define RV32_DIVU       `RV32_R_t(`RV32_OP, 3'b101, 7'b0000001) 
`define RV32_REM        `RV32_R_t(`RV32_OP, 3'b110, 7'b0000001) 
`define RV32_REMU       `RV32_R_t(`RV32_OP, 3'b111, 7'b0000001) 

// RV32A
`define RV32_LR_W       `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b00010??)
`define RV32_SC_W       `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b00011??)
`define RV32_AMOSWAP_W  `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b00001??)
`define RV32_AMOADD_W   `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b00000??)
`define RV32_AMOXOR_W   `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b00100??)
`define RV32_AMOAND_W   `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b01100??)
`define RV32_AMOOR_W    `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b01000??)
`define RV32_AMOMIN_W   `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b10000??)
`define RV32_AMOMAX_W   `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b10100??)
`define RV32_AMOMINU_W  `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b11000??)
`define RV32_AMOMAXU_W  `RV32_R_t(`RV32_OP_AMO, 3'b010, 7'b11100??)

// RV32F
`define RV32_FLW        `RV32_I_t(`RV32_OP_LOAD_FP, 3'b010)
`define RV32_FSW        `RV32_S_t(`RV32_OP_STORE_FP, 3'b010)
`define RV32_FMADD_S    `RV32_R4_t(`RV32_OP_FMADD, 3'b???, 2'b00)
`define RV32_FMSUB_S    `RV32_R4_t(`RV32_OP_FMSUB, 3'b???, 2'b00)
`define RV32_FNMSUB_S   `RV32_R4_t(`RV32_OP_FNMSUB, 3'b???, 2'b00)
`define RV32_FNMADD_S   `RV32_R4_t(`RV32_OP_FNMADD, 3'b???, 2'b00)
`define RV32_FSUB_S     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0000000)
`define RV32_FMUL_S     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0000100)
`define RV32_FADD_S     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0001000)
`define RV32_FDIV_S     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0001100)
`define RV32_FSQRT_S    `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b0101100)
`define RV32_FSGNJ_S    `RV32_F_t(7'b1010011, 3'b000, 5'b?????, 7'b0010000)
`define RV32_FSGNJN_S   `RV32_F_t(7'b1010011, 3'b001, 5'b?????, 7'b0010000)
`define RV32_FSGNJX_S   `RV32_F_t(7'b1010011, 3'b010, 5'b?????, 7'b0010000)
`define RV32_FMIN_S     `RV32_F_t(7'b1010011, 3'b000, 5'b?????, 7'b0010100)
`define RV32_FMAX_S     `RV32_F_t(7'b1010011, 3'b001, 5'b?????, 7'b0010100)
`define RV32_FCVT_W_S   `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b1100000)
`define RV32_FCVT_WU_S  `RV32_F_t(7'b1010011, 3'b???, 5'b00001, 7'b1100000)
`define RV32_FMV_X_W    `RV32_F_t(7'b1010011, 3'b000, 5'b00000, 7'b1110000)
`define RV32_FEQ_S      `RV32_F_t(7'b1010011, 3'b010, 5'b?????, 7'b1010000)
`define RV32_FLT_S      `RV32_F_t(7'b1010011, 3'b001, 5'b?????, 7'b1010000)
`define RV32_FLE_S      `RV32_F_t(7'b1010011, 3'b000, 5'b?????, 7'b1010000)
`define RV32_FCLASS_S   `RV32_F_t(7'b1010011, 3'b001, 5'b00000, 7'b1110000)
`define RV32_FCVT_S_W   `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b1101000)
`define RV32_FCVT_S_WU  `RV32_F_t(7'b1010011, 3'b???, 5'b00001, 7'b1101000)
`define RV32_FMV_W_X    `RV32_F_t(7'b1010011, 3'b000, 5'b00000, 7'b1111000)

// RV32D
`define RV32_FLD        `RV32_I_t(`RV32_OP_LOAD_FP, 3'b011)
`define RV32_FSD        `RV32_S_t(`RV32_OP_STORE_FP, 3'b011)
`define RV32_FMADD_D    `RV32_R4_t(`RV32_OP_FMADD, 3'b???, 2'b01)
`define RV32_FMSUB_D    `RV32_R4_t(`RV32_OP_FMSUB, 3'b???, 2'b01)
`define RV32_FNMSUB_D   `RV32_R4_t(`RV32_OP_FNMSUB, 3'b???, 2'b01)
`define RV32_FNMADD_D   `RV32_R4_t(`RV32_OP_FNMADD, 3'b???, 2'b01)
`define RV32_FADD_D     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0000001)
`define RV32_FSUB_D     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0000101)
`define RV32_FMUL_D     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0001001)
`define RV32_FDIV_D     `RV32_F_t(7'b1010011, 3'b???, 5'b?????, 7'b0001101)
`define RV32_FSQRT_D    `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b0101101)
`define RV32_FSGNJ_D    `RV32_F_t(7'b1010011, 3'b000, 5'b?????, 7'b0010001)
`define RV32_FSGNJN_D   `RV32_F_t(7'b1010011, 3'b001, 5'b?????, 7'b0010001)
`define RV32_FSGNJX_D   `RV32_F_t(7'b1010011, 3'b010, 5'b?????, 7'b0010001)
`define RV32_FMIN_D     `RV32_F_t(7'b1010011, 3'b000, 5'b?????, 7'b0010101)
`define RV32_FMAX_D     `RV32_F_t(7'b1010011, 3'b001, 5'b?????, 7'b0010101)
`define RV32_FCVT_S_D   `RV32_F_t(7'b1010011, 3'b???, 5'b00001, 7'b1100000)
`define RV32_FCVT_D_S   `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b1100001)
`define RV32_FEQ_D      `RV32_F_t(7'b1010011, 3'b010, 5'b?????, 7'b1010001)
`define RV32_FLT_D      `RV32_F_t(7'b1010011, 3'b001, 5'b?????, 7'b1010001)
`define RV32_FLE_D      `RV32_F_t(7'b1010011, 3'b000, 5'b?????, 7'b1010001)
`define RV32_FCLASS_D   `RV32_F_t(7'b1010011, 3'b001, 5'b00000, 7'b1110001)
`define RV32_FCVT_W_D   `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b1100001)
`define RV32_FCVT_WU_D  `RV32_F_t(7'b1010011, 3'b???, 5'b00001, 7'b1100001)
`define RC32_FCVT_D_W   `RV32_F_t(7'b1010011, 3'b???, 5'b00000, 7'b1101001)
`define RC32_FCVT_D_WU  `RV32_F_t(7'b1010011, 3'b???, 5'b00001, 7'b1101001)

`define RV32_RS1(inst) {``inst``[19:15]}
`define RV32_RS2(inst) {``inst``[24:20]}
`define RV32_RD(inst)  {``inst``[11:7]}

// RV32 Immediate signed/unsigned (U is technically unsigned) extension macros
`define RV32_shamt_Imm(inst)     {{27{1'b0}}, ``inst``[24:20]}
`define RV32_signext_I_Imm(inst) {{21{``inst``[31]}}, ``inst``[30:20]}
`define RV32_signext_S_Imm(inst) {{21{``inst``[31]}}, ``inst``[30:25], ``inst``[11:7]}
`define RV32_signext_B_Imm(inst) {{20{``inst``[31]}}, ``inst``[7], ``inst``[30:25], ``inst``[11:8], {1'b0}}
`define RV32_signext_U_Imm(inst) {``inst``[31:12], {12{1'b0}}}
`define RV32_signext_J_Imm(inst) {{12{``inst``[31]}}, ``inst``[19:12], ``inst``[20], ``inst``[30:21], {1'b0}} 

// RV32 12bit Immediate injection/extraction, replace the Imm content with
// specified value for injection, input immediate value index starting from 1

`define RV32_inject_B_Imm12(inst, v) {``v``[12], ``v``[10:5], ``inst``[24:12], ``v``[4:1], ``v``[11], ``inst``[6:0]}
`define RV32_inject_J_Imm20(inst, v) {``v``[20], ``v``[10:1], ``v``[11], ``v``[19:12], ``inst``[11:0]}

`define RV32_extract_B_Imm12(inst) {``inst``[31], ``inst``[7], ``inst``[30:25], ``inst``[11:8]}
`define RV32_extract_J_Imm20(inst) {``inst``[31], ``inst``[19:12], ``inst``[20],``inst``[30:21]}

`endif  // __ISA_SVH__
