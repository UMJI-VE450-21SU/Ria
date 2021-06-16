module if_stage_tb();
    logic                   clock;
    logic                   reset;
    logic                   stall;
    logic [`INST_WIDTH-1:0] pc_predicted;
    logic                   take_branch;
    logic [`INST_WIDTH-1:0] branch_pc;
  // ======= cache related ===================
    logic [`INST_PACK-1:0]  Icache2proc_data;
    logic                   Icache2proc_data_valid;
    logic [`INST_WIDTH-1:0] proc2Icache_addr; // one addr is enough
  // ======= inst buffer related =============
    ib_entry_t [`INST_FETCH_NUM-1:0] insts_out;
    logic                            valid;

    if_stage if_stage_0 (
    .clock,
    .reset,
    .stall,
    .pc_predicted,
    .take_branch,
    .branch_pc,
    .Icache2proc_data,
    .Icache2proc_data_valid,
    .proc2Icache_addr, // one addr is enough
    .insts_out,
    .valid,
    );

    always begin
        #5;
        clock = ~clock;
    end
    
    initial begin
        clock = 0;
        reset = 1;
        stall = 0;
        pc_predicted = 0;
        take_branch = 0;
        Icache2proc_data = 0;
        Icache2proc_data_valid = 0;
        @(negedge clock);
        reset = 0;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);


        $finish;
    end

    
endmodule