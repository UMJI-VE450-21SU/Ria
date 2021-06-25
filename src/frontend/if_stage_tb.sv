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
    .valid
    );

    always begin
        #5;
        clock = ~clock;
    end
    
    integer f1;
    always @(posedge clock) begin
        f1 = $fopen("result.txt","a");
        $fwrite(f1,"%x\n",insts_out[0].inst);
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
        Icache2proc_data = `INST_PACK'habcdef0123456789;
        Icache2proc_data[31:0]=32'habcdef01;
        Icache2proc_data_valid = 1;
        @(negedge clock);
        Icache2proc_data = `INST_PACK'h0123456789abcdef;
        Icache2proc_data[31:0]=32'h12345678;

        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
            $fclose(f1);

        $finish;
    end

    
endmodule