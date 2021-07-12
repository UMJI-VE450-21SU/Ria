// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Instruction Decode
// Author:  Li Shi, Jian Shi
// Date:    2021/06/02

`include "src/common/micro_op.svh"

module decode (
  input fb_entry_t  fb_entry,
  input             valid,
  output micro_op_t uop
);

  wire [31:0] pc   = fb_entry.pc;
  wire [31:0] inst = fb_entry.inst;

  always_comb begin
    uop = 0;
    uop.pc    = pc;
    uop.npc   = pc + 4;
    uop.inst  = inst;
    uop.valid = valid;
    casez (inst) 
      `RV32_LUI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_ADD;
        uop.imm               = `RV32_signext_U_Imm(inst);
        uop.rs1_source        = RS_FROM_ZERO;
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_AUIPC: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_ADD;
        uop.imm               = `RV32_signext_U_Imm(inst);
        uop.rs1_source        = RS_FROM_PC;
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_JAL: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_JAL;
        uop.imm               = `RV32_signext_J_Imm(inst);
        uop.rs1_source        = RS_FROM_PC;
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_JALR: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_JALR;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_BEQ: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_EQ;
        uop.imm               = `RV32_signext_B_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_BNE: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_NE;
        uop.imm               = `RV32_signext_B_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_BLT: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_LT;
        uop.imm               = `RV32_signext_B_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end 
      `RV32_BGE: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_GE;
        uop.imm               = `RV32_signext_B_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_BLTU: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_LTU;
        uop.imm               = `RV32_signext_B_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_BGEU: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_BR;
        uop.br_type           = BR_GEU;
        uop.imm               = `RV32_signext_B_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_LB: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_LD;
        uop.mem_size          = MEM_BYTE;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_LH: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_LD;
        uop.mem_size          = MEM_HALF;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_LW: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_LD;
        uop.mem_size          = MEM_WORD;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_LBU: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_LDU;
        uop.mem_size          = MEM_BYTE;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_LHU: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_LDU;
        uop.mem_size          = MEM_HALF;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SB: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_ST;
        uop.mem_size          = MEM_BYTE;
        uop.imm               = `RV32_signext_S_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_SH: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_ST;
        uop.mem_size          = MEM_HALF;
        uop.imm               = `RV32_signext_S_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_SW: begin
        uop.iq_code           = IQ_MEM;
        uop.fu_code           = FU_MEM;
        uop.mem_type          = MEM_ST;
        uop.mem_size          = MEM_WORD;
        uop.imm               = `RV32_signext_S_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
      end
      `RV32_ADDI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_ADD;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SLTI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SLT;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SLTIU: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SLTU;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_ANDI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_AND;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_ORI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_OR;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_XORI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_XOR;
        uop.imm               = `RV32_signext_I_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SLLI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SLL;
        uop.imm               = `RV32_shamt_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SRLI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SRL;
        uop.imm               = `RV32_shamt_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SRAI: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SRA;
        uop.imm               = `RV32_shamt_Imm(inst);
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_IMM;
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_ADD: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_ADD;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SUB: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SUB;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SLL: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SLL;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SLT: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SLT;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SLTU: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SLTU;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_XOR: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_XOR;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SRL: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SRL;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_SRA: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_SRA;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_OR: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_OR;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_AND: begin
        uop.iq_code           = IQ_INT;
        uop.fu_code           = FU_ALU;
        uop.alu_type          = ALU_AND;
        uop.rs1_source        = RS_FROM_RF;
        uop.rs1_arf_int_index = `RV32_RS1(inst);
        uop.rs2_source        = RS_FROM_RF;
        uop.rs2_arf_int_index = `RV32_RS2(inst);
        uop.rd_arf_int_index  = `RV32_RD(inst);
        uop.rd_valid          = 1;
      end
      `RV32_FENCE: begin
        // todo
      end
      `RV32_ECALL: begin
        // todo
      end
      `RV32_EBREAK: begin
        // todo
      end
      default:
        uop = 0;
    endcase
    if (uop.rd_arf_int_index == 0)
      uop.rd_valid = 0;
  end
    
endmodule

module inst_decode (
  input                                 clock,
  input                                 reset,

  input  fb_entry_t [`FETCH_WIDTH-1:0]  insts,
  input             [`FETCH_WIDTH-1:0]  insts_valid,
  output micro_op_t [`DECODE_WIDTH-1:0] uops
);

  decode decode_inst [`DECODE_WIDTH-1:0] (
    .fb_entry (insts),
    .valid    (insts_valid),
    .uop      (uops)
  );

endmodule
