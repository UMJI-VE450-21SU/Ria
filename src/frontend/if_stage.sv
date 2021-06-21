`include "../common/micro_op.svh"

module if_stage (
  // ======= basic ===========================
    input                               clock,
    input                               reset,
    input                               stall,
  // ======= branch predictor related ========
    input        [`INST_WIDTH-1:0]      pc_predicted,
    input                               take_branch,
    input        [`INST_WIDTH-1:0]      branch_pc,
  // ======= cache related ===================
    input        [`INST_PACK-1:0]       Icache2proc_data,
    input                               Icache2proc_data_valid,
    output logic [`INST_WIDTH-1:0]      proc2Icache_addr, // one addr is enough
  // ======= inst buffer related =============
    output ib_entry_t [`INST_FETCH_NUM-1:0] insts_out,
    output logic                            valid
);

    ib_entry_t [`INST_FETCH_NUM-1:0]    insts;
    logic                               insts_valid;

    logic                               ib_full;

    inst_fetch instf(
        .clock(clock),
        .reset(reset),
        .stall(stall | ib_full),
        .pc_predicted(pc_predicted),
        .take_branch(take_branch),
        .branch_pc(branch_pc),
        .Icache2proc_data(Icache2proc_data),
        .Icache2proc_data_valid(Icache2proc_data_valid),
        .proc2Icache_addr(proc2Icache_addr),
        .insts_out(insts),
        .insts_out_valid(insts_valid)
    );

    fetch_buffer fb(
        .clk(clock),
        .reset(reset),

        .insts_in(insts),
        .insts_in_valid(insts_valid),

        .insts_out(insts_out),
        .valid(valid),

        .full(ib_full)
);

endmodule
