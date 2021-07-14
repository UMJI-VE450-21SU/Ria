// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Issue Queue for Integer
// Author:  Li Shi
// Date:    2021/05/28

`include "src/common/micro_op.svh"

`timescale 1ns / 1ps
module issue_slot_int (
  input             clock,
  input             reset,
  input             clear,

  input             load,   // when load is 1, load uop_in into the slot
  input  micro_op_t uop_in,
  output micro_op_t uop,    // current uop in this slot

  output logic [`PRF_INT_INDEX_SIZE-1:0] rs1_index,
  output logic [`PRF_INT_INDEX_SIZE-1:0] rs2_index,
  input             rs1_busy,
  input             rs2_busy,

  output            ready,
  output            free
);

  wire rs1_ready, rs2_ready;

  always_comb begin
    if (load & uop_in.valid) begin
      rs1_index = (uop_in.rs1_source == RS_FROM_RF) ? uop_in.rs1_prf_int_index : 0;
      rs2_index = (uop_in.rs2_source == RS_FROM_RF) ? uop_in.rs2_prf_int_index : 0;
    end else begin
      rs1_index = (uop.rs1_source == RS_FROM_RF) ? uop.rs1_prf_int_index : 0;
      rs2_index = (uop.rs2_source == RS_FROM_RF) ? uop.rs2_prf_int_index : 0;
    end
  end

  always_ff @ (posedge clock) begin
    if (reset | clear) begin
      uop <= 0;
    end else if (load & uop_in.valid) begin
      uop <= uop_in;
    end
  end

  assign free = ~uop.valid;
  assign rs1_ready = ~rs1_busy;
  assign rs2_ready = ~rs2_busy;
  assign ready = rs1_ready & rs2_ready & uop.valid;

endmodule


module issue_queue_int_selector (ready, sel, sel_valid);

  parameter REQS  = `DISPATCH_WIDTH;
  parameter WIDTH = `IQ_INT_SIZE;

  input      [WIDTH-1:0]                    ready;
  output reg [REQS-1:0] [$clog2(WIDTH)-1:0] sel;
  output reg [REQS-1:0]                     sel_valid;

  logic [REQS-1:0] [WIDTH-1:0] readys;

  assign readys[0] = ready;

  generate
    for (genvar i = 1; i < REQS; i++) begin
      assign readys[i] = readys[i-1] & ~(sel_valid[i-1] << sel[i-1]);
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < REQS; i++) begin
      sel_valid[i] = 1;
      casez (readys[i])
        16'b???????????????1: sel[i] = 4'b0000;
        16'b??????????????10: sel[i] = 4'b0001;
        16'b?????????????100: sel[i] = 4'b0010;
        16'b????????????1000: sel[i] = 4'b0011;
        16'b???????????10000: sel[i] = 4'b0100;
        16'b??????????100000: sel[i] = 4'b0101;
        16'b?????????1000000: sel[i] = 4'b0110;
        16'b????????10000000: sel[i] = 4'b0111;
        16'b???????100000000: sel[i] = 4'b1000;
        16'b??????1000000000: sel[i] = 4'b1001;
        16'b?????10000000000: sel[i] = 4'b1010;
        16'b????100000000000: sel[i] = 4'b1011;
        16'b???1000000000000: sel[i] = 4'b1100;
        16'b??10000000000000: sel[i] = 4'b1101;
        16'b?100000000000000: sel[i] = 4'b1110;
        16'b1000000000000000: sel[i] = 4'b1111;
        default: begin
          sel[i] = 4'b0000;
          sel_valid[i] = 0;
        end
      endcase
    end
  end

endmodule


// Input:  From dispatch,    width = DISPATCH_WIDTH  = 4
// Output: To PRF & Ex Unit, width = ISSUE_WIDTH_INT = 3
`timescale 1ns / 1ps
module issue_queue_int (
  input  clock,
  input  reset,

  output [`IQ_INT_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs1_index,
  output [`IQ_INT_SIZE-1:0][`PRF_INT_INDEX_SIZE-1:0] rs2_index,
  input  [`IQ_INT_SIZE-1:0]                          rs1_busy,
  input  [`IQ_INT_SIZE-1:0]                          rs2_busy,

  input  [`ISSUE_WIDTH_INT-1:0]             ex_busy,

  input  micro_op_t [`DISPATCH_WIDTH-1:0]   uop_in,
  output micro_op_t [`ISSUE_WIDTH_INT-1:0]  uop_out,

  output iq_int_full
);

  logic [$clog2(`IQ_INT_SIZE):0] uop_in_count, uop_out_count;
  logic [$clog2(`IQ_INT_SIZE):0] free_count;
  reg   [$clog2(`IQ_INT_SIZE):0] free_count_reg;

  logic [`DISPATCH_WIDTH-1:0] [$clog2(`IQ_INT_SIZE)-1:0] input_select;
  logic [`DISPATCH_WIDTH-1:0]                            input_select_valid;

  logic [`IQ_INT_SIZE-1:0] free, load;

  logic [`IQ_INT_SIZE-1:0] ready, ready_alu_br, ready_imul_idiv;
  logic [`IQ_INT_SIZE-1:0] clear;

  logic [1:0][$clog2(`IQ_INT_SIZE)-1:0] clear_alu_br;         // Pipe 0/1 for alu/br
  logic [1:0]                           clear_alu_br_valid;
  logic [$clog2(`IQ_INT_SIZE)-1:0]      clear_imul_idiv;      // Pipe 2 for imul/idiv
  logic                                 clear_imul_idiv_valid;

  micro_op_t [`IQ_INT_SIZE-1:0] uop_to_slot, uop_to_issue;

  // If #free slots < dispatch width, set the issue queue as full
  assign free_count = free_count_reg - uop_in_count + uop_out_count;
  assign iq_int_full = free_count < `DISPATCH_WIDTH;

  always_ff @(posedge clock) begin
    if (reset) begin
      free_count_reg <= `IQ_INT_SIZE;
    end else begin
      free_count_reg <= free_count;
    end
  end

  generate
    for (genvar k = 0; k < `IQ_INT_SIZE; k++) begin
      issue_slot_int issue_slot_int_inst (
        .clock      (clock),
        .reset      (reset),
        .clear      (clear[k]),
        .load       (load[k]),
        .uop_in     (uop_to_slot[k]),
        .uop        (uop_to_issue[k]),
        .rs1_index  (rs1_index[k]),
        .rs2_index  (rs2_index[k]),
        .rs1_busy   (rs1_busy[k]),
        .rs2_busy   (rs2_busy[k]),
        .ready      (ready[k]),
        .free       (free[k])
      );
      assign ready_alu_br[k]    = ready[k] & 
                                  ((uop_to_issue[k].fu_code == FU_ALU) | 
                                   (uop_to_issue[k].fu_code == FU_BR));
      assign ready_imul_idiv[k] = ready[k] & 
                                  ((uop_to_issue[k].fu_code == FU_IMUL) | 
                                   (uop_to_issue[k].fu_code == FU_IDIV));
    end
  endgenerate

  wire iq_int_print = 0;

  always_ff @(posedge clock) begin
    if (iq_int_print) begin
      for (integer i = 0; i < `IQ_INT_SIZE; i++) begin
        $display("[IQ_INT] slot %d (ready=%b)", i, ready[i]);
        print_uop(uop_to_issue[i]);
      end
      $display("[IQ_INT] free_count_reg=%d", free_count_reg);
    end
  end

  // Input selector
  issue_queue_int_selector #(
    /*REQS=*/ `DISPATCH_WIDTH,
    /*WIDTH=*/`IQ_INT_SIZE
  ) input_selector (
    .ready      (free),
    .sel        (input_select),
    .sel_valid  (input_select_valid)
  );

  always_comb begin
    uop_in_count = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      if (uop_in[i].valid) begin
        uop_in_count = uop_in_count + 1;
      end
    end
  end

  // Allocate input uops to each free issue slots
  always_comb begin
    uop_to_slot = 0;
    load = 0;
    for (int i = 0; i < `DISPATCH_WIDTH; i++) begin
      for (int j = 0; j < `IQ_INT_SIZE; j++) begin
        if ((input_select[i] == j) & input_select_valid[i] & uop_in[i].valid) begin
          uop_to_slot[j] = uop_in[i];
          load[j] = 1'b1;
        end
      end
    end
  end

  // Output selector
  issue_queue_int_selector #(
    /*REQS=*/  2,
    /*WIDTH=*/ `IQ_INT_SIZE
  ) output_selector_alu_br (
    .ready      (ready_alu_br),
    .sel        (clear_alu_br),
    .sel_valid  (clear_alu_br_valid)
  );

  issue_queue_int_selector #(
    /*REQS=*/  1,
    /*WIDTH=*/ `IQ_INT_SIZE
  ) output_selector_imul_idiv (
    .ready      (ready_imul_idiv),
    .sel        (clear_imul_idiv),
    .sel_valid  (clear_imul_idiv_valid)
  );

  always_comb begin
    uop_out_count = 0;
    for (int i = 0; i < `IQ_INT_SIZE; i++) begin
      if (clear[i]) begin
        uop_out_count = uop_out_count + 1;
      end
    end
  end

  // Select part of ready instructions to be issued
  always_comb begin
    uop_out[0] = clear_alu_br_valid[0] ? uop_to_issue[clear_alu_br[0]] : 0;
    uop_out[1] = clear_alu_br_valid[1] ? uop_to_issue[clear_alu_br[1]] : 0;
    uop_out[2] = clear_imul_idiv_valid ? uop_to_issue[clear_imul_idiv] : 0;
    clear = 0;
    clear[clear_alu_br[0]] = clear_alu_br_valid[0];
    clear[clear_alu_br[1]] = clear_alu_br_valid[1];
    clear[clear_imul_idiv] = clear_imul_idiv_valid;
  end

endmodule
