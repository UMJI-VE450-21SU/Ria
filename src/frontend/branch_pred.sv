// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Branch Predictor
// Author:  Yiqiu Sun, Jian Shi
// Date:    2021/07/17

`include "src/common/micro_op.svh"

module branch_pred (
    input clock,
    input reset,

  // Input to make prediction(s)
    input               [31:0]                  PC,
    input               [`FETCH_WIDTH-1:0]      is_branch,
    input               [`FETCH_WIDTH-1:0]      is_valid,

  // Input to update state based on committed branch(es)
    input   micro_op_t  [`COMMIT_WIDTH-1:0]     uop_retire,
    output logic                                mispredict,

  // Output
    output logic        [31:0]                  next_PC,
    output logic        [`FETCH_WIDTH-1:0]      predictions
);

  // Internal register declarations (BHT and PHT and BTB and LRU)
  // Branch History Table
  // stores 7 bits of recent branch history, and 128 entries
    reg   [`PHT_INDEX_SIZE-1:0]   BHT             [`BHT_SIZE-1:0];

  // Pattern History Table
    reg   [1:0]                   PHT             [`PHT_SIZE-1:0];

  // Branch Target Buffer
    reg   [`BTB_WIDTH-1:0]                        BTB_valid       [`BTB_SIZE-1:0];
    reg   [`BTB_WIDTH-1:0] [`BTB_TAG_SIZE-1:0]    BTB_PC_tag      [`BTB_SIZE-1:0];
    reg   [`BTB_WIDTH-1:0] [31:0]                 BTB_target      [`BTB_SIZE-1:0];


    logic [`PHT_INDEX_SIZE-1:0]                   BHT_next        [`BHT_SIZE-1:0];
    logic [1:0]                                   PHT_next        [`PHT_SIZE-1:0];
    logic [`BTB_WIDTH-1:0]                        BTB_valid_next  [`BTB_SIZE-1:0];
    logic [`BTB_WIDTH-1:0] [`BTB_TAG_SIZE-1:0]    BTB_PC_tag_next [`BTB_SIZE-1:0];
    logic [`BTB_WIDTH-1:0] [31:0]                 BTB_target_next [`BTB_SIZE-1:0];

    // Least Recently Used
    logic [`BTB_WIDTH_INDEX-1:0]  LRU;

    logic branch;
    logic [1:0]                 PHT_tmp;

    logic [`BHT_INDEX_SIZE-1:0] BHT_PC_entry;
    logic [`BTB_INDEX_SIZE-1:0] BTB_PC_entry;
    logic [`BHT_INDEX_SIZE-1:0] BHT_entry        [`COMMIT_WIDTH-1:0];
    logic [`BTB_INDEX_SIZE-1:0] BTB_entry        [`COMMIT_WIDTH-1:0];
    logic [31:0]                PC_update        [`COMMIT_WIDTH-1:0];
    logic [31:0]                target_update    [`COMMIT_WIDTH-1:0];

    generate
        assign BHT_PC_entry = PC[`BHT_INDEX_SIZE+1:2];
        assign BTB_PC_entry = PC[`BTB_INDEX_SIZE+1:2];
        for (genvar i = 0; i < `COMMIT_WIDTH; i++) begin
            assign BHT_entry[i]     = uop_retire[i].pc[`BHT_INDEX_SIZE+1:2];
            assign BTB_entry[i]     = uop_retire[i].pc[`BTB_INDEX_SIZE+1:2];
            assign PC_update[i]     = uop_retire[i].pc;
            assign target_update[i] = uop_retire[i].br_addr;
        end
    endgenerate

  // Combinational/Output logic
    always_comb begin
    // Default output is all not taken
        branch      = 0;
        predictions = 4'b0;
        for (int i = 0; i < `BHT_SIZE; i++) begin
            BHT_next[i] = BHT[i];
        end
        for (int i = 0; i < `PHT_SIZE; i++) begin
            PHT_next[i] = PHT[i];
        end
        for (int i = 0; i < `BTB_SIZE; i++) begin
            BTB_valid_next[i]   = BTB_valid[i];
            BTB_PC_tag_next[i]  = BTB_PC_tag[i];
            BTB_target_next[i]  = BTB_target[i];
        end

        mispredict = 0;
        next_PC = PC + 4*`FETCH_WIDTH;

        for (int i = 0; i < `COMMIT_WIDTH; i++) begin
            if (uop_retire[i].valid && uop_retire[i].br_type != BR_X) begin
                // Branch-type uop or Jump-type uop
                BHT_next[BHT_entry[i]]    = BHT_next[BHT_entry[i]] << 1;
                BHT_next[BHT_entry[i]][0] = uop_retire[i].br_taken;
                PHT_tmp = PHT_next[BHT_next[BHT_entry[i]]];
                if(uop_retire[i].br_taken && PHT_tmp < 2'b11) begin
                    PHT_next[BHT_next[BHT_entry[i]]] = PHT_tmp + 1;
                end
                if(~uop_retire[i].br_taken && PHT_tmp > 2'b0) begin
                    PHT_next[BHT_next[BHT_entry[i]]] = PHT_tmp - 1;
                end
                
                LRU = `BTB_WIDTH-1;

                for (int j = 0; j < `BTB_WIDTH; j++) begin
                    if (BTB_valid_next[BTB_entry[i]][j]) begin
                        if (BTB_PC_tag_next[BTB_entry[i]][j] == PC_update[i][31:32-`BTB_TAG_SIZE]) begin
                            LRU = j;
                            break;
                        end
                    end
                end
    
                BTB_PC_tag_next[BTB_entry[i]][0] = PC_update[i][31:32-`BTB_TAG_SIZE];
                BTB_target_next[BTB_entry[i]][0] = target_update[i];
                BTB_valid_next[BTB_entry[i]][0]  = 1'b1;
            
                for (int j = 1; j < `BTB_WIDTH; j++)begin
                    if (j < LRU + 1) begin
                        BTB_PC_tag_next[BTB_entry[i]][j] = BTB_PC_tag_next[BTB_entry[i]][j-1];
                        BTB_target_next[BTB_entry[i]][j] = BTB_target_next[BTB_entry[i]][j-1];
                        BTB_valid_next[BTB_entry[i]][j]  = BTB_valid_next[BTB_entry[i]][j-1];
                    end
                end

                if (uop_retire[i].pred_taken != uop_retire[i].br_taken && ~mispredict) begin
                    mispredict = 1;
                    next_PC = target_update[i];
                    break;
                end
            end
        end

        // See if something should be predicted taken
        if(~mispredict) begin
            for (int i = 0; i < `FETCH_WIDTH; i++) begin
                // only need to examine the current 4 insts
                if (PHT_next[BHT_next[(BHT_PC_entry + i)%`BHT_SIZE]][1] & is_branch[i] & is_valid[i]) begin
                // the current PC is a branch
                    for (int j = 0; j < `BTB_WIDTH; j++) begin
                        if (BTB_valid_next[(BTB_PC_entry + i)%`BTB_SIZE][j] && BTB_PC_tag_next[(BTB_PC_entry + i)%`BTB_SIZE][j] == PC[31:32-`BTB_TAG_SIZE])begin
                            // predicted taken
                            next_PC = BTB_target_next[(BTB_PC_entry+i)%`BTB_SIZE][j];
                            branch  = 1;
                            predictions[i] = 1;
                            break;
                        end
                    end
                    if(branch) break;
                end
            end
        end
    end

  // Sequential Logic
    always_ff @(posedge clock) begin
        if (reset) begin
            // Upon reset, clear everything stored
            for (int i = 0; i < `BHT_SIZE; i++) begin
                BHT[i] <= 0;
            end
            for (int i = 0; i < `BTB_SIZE; i++) begin
                BTB_valid[i]  <= 0;
                BTB_PC[i]     <= 0;
                BTB_target[i] <= 0;
            end
        // The initial prediction stage are weakly not taken
            for (int i = 0; i < `PHT_SIZE; i++) begin
                PHT[i] <= 2'b01;
            end
        end else begin
            for (int i = 0; i < `BHT_SIZE; i++) begin
                BHT[i] <= BHT_next[i];
            end
            for (int i = 0; i < `BTB_SIZE; i++) begin
                BTB_valid[i]  <= BTB_valid_next[i];
                BTB_PC[i]     <= BTB_PC_next[i];
                BTB_target[i] <= BTB_target_next[i];
            end
            for (int i = 0; i < `PHT_SIZE; i++) begin
                PHT[i] <= PHT_next[i];
            end
        end
    end

endmodule
