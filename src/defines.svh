`ifndef __DEFINES_SVH__
`define __DEFINES_SVH__


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
		logic [7:0]   imm_2;	// imm[19:12]
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
} INST;

// NOP = ADDI x0, x0, 0
`define RV32_NOP        32'h00000013



`endif  // __DEFINES_SVH__
