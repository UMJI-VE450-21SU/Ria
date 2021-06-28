// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Core (No cache/memory involved)
// Author:  Li Shi, Jian Shi, Yichao Yuan, Yiqiu Sun, Zhiyuan Liu
// Date:    2021/06/21

module core (
  input clock,
  input reset,

  // ======= icache related ==================
  input        [31:0]  icache2core_data,
  input                icache2core_data_valid,
  output logic [31:0]  core2icache_addr
);

  logic except;
  logic stall;


  /* Stage 1: IF - Instruction Fetch */

  fb_entry_t [`FECTH_WIDTH-1:0] if_insts_out;
  logic                         if_insts_out_valid;
  logic                         fb_full;

  inst_fetch if (
    .clock                  (clock),
    .reset                  (reset),
    .stall                  (stall | fb_full),
    .pc_predicted           (0),
    .branch_taken           (0),
    .branch_pc              (0),
    .icache2core_data       (icache2core_data),
    .icache2core_data_valid (icache2core_data_valid),
    .core2icache_addr       (core2icache_addr),
    .insts_out              (if_insts_out),
    .insts_out_valid        (if_insts_out_valid),
  );

  /* IF ~ FB Pipeline Registers */

  fb_entry_t [`FECTH_WIDTH-1:0] fb_insts_in;
  logic                         fb_insts_in_valid;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      fb_insts_in        <= 0;
      fb_insts_in_valid  <= 0;
    end else if (!stall) begin
      fb_insts_in        <= if_insts_out;
      fb_insts_in_valid  <= if_insts_out_valid;
    end
  end

  /* Stage 2: FB - Fetch Buffer */

  fb_entry_t [`FECTH_WIDTH-1:0] fb_insts_out;
  logic      [`FECTH_WIDTH-1:0] fb_insts_out_valid;

  fetch_buffer fb (
    .clock            (clock),
    .reset            (reset),
    .insts_in         (fb_insts_in),
    .insts_in_valid   (fb_insts_in_valid),
    .insts_out        (fb_insts_out),
    .insts_out_valid  (fb_insts_out_valid),
    .full             (fb_full)
  );

  /* FB ~ ID Pipeline Registers */

  fb_entry_t [`DECODE_WIDTH-1:0] id_insts_in;
  logic      [`DECODE_WIDTH-1:0] id_insts_in_valid;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      id_insts_in        <= 0;
      id_insts_in_valid  <= 0;
    end else if (!stall) begin
      id_insts_in        <= fb_insts_out;
      id_insts_in_valid  <= fb_insts_out_valid;
    end
  end

  /* Stage 3: ID - Instruction Decode */

  micro_op_t [`DECODE_WIDTH-1:0] id_uops_out;

  inst_decode id (
    .clock        (clock),
    .reset        (reset),
    .insts        (id_insts_in),
    .insts_valid  (id_insts_in_valid),
    .uops         (id_uops_out)
  );

  /* ID ~ RR Pipeline Registers */

  micro_op_t [`RENAME_WIDTH-1:0] rr_uops_in;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rr_uops_in <= 0;
    end else if (!stall) begin
      rr_uops_in <= id_uops_out;
    end
  end

  /* Stage 4: RR - Register Renaming */

  micro_op_t [`RENAME_WIDTH-1:0] rr_uops_out;
  logic rr_allocatable;
  logic rr_ready;

  // todo: check i/o connnections @Jian
  rat rr (
    .clock        (clock),
    .reset        (reset),
    .input_valid  (1),
    .recover      (0),
    .arf_recover  (0),
    .prf_recover  (0),
    .retire_valid (0),
    .pc_recover   (0),
    .pc_retire    (0),
    .uop_in       (rr_uops_in),
    .uop_out      (rr_uops_out),
    .allocatable  (rr_allocatable),
    .ready        (rr_ready)
  );

  /* RR ~ DP Pipeline Registers */

  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uops_in;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      dp_uops_in <= 0;
    end else if (!stall) begin
      dp_uops_in <= rr_uops_out;
    end
  end

  /* Stage 5: DP - Dispatch */

  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_int;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_mem;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_fp;

  dispatch dp (
    .uop_in     (dp_uops_in),
    .uop_to_int (dp_uop_to_int),
    .uop_to_mem (dp_uop_to_mem),
    .uop_to_fp  (dp_uop_to_fp)
  );

  /* DP ~ IS Pipeline Registers */

  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_int,
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_mem,
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_fp,
  micro_op_t [`DISPATCH_WIDTH-1:0] is_uop_to_int,
  micro_op_t [`DISPATCH_WIDTH-1:0] is_uop_to_mem,
  micro_op_t [`DISPATCH_WIDTH-1:0] is_uop_to_fp

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      is_uop_to_int <= 0;
      is_uop_to_mem <= 0;
      is_uop_to_fp  <= 0;
    end else if (!stall) begin
      is_uop_to_int <= dp_uop_to_int;
      is_uop_to_mem <= dp_uop_to_mem;
      is_uop_to_fp  <= dp_uop_to_fp;
    end
  end

  /* Stage 6: IS - Issue */

  /* IS ~ RF Pipeline Registers */

  /* Stage 7: RF - Register File */

  /* RF ~ EX Pipeline Registers */

  /* Stage 8: EX - Execution */

  /* EX ~ CM Pipeline Registers */

  /* Stage 9: CM - Commit */

  // todo: check i/o connnections @Jian
  rob cm (
    .clock        (clock),
    .reset        (reset),
    .input_valid  (1),
    .recover      (0),
    .uop_recover  (0),
    .uop_retire   (0),
    .retire_valid (0),
    .uop_in       (0),
    .in_valid     (0),
    .uop_out      (0),
    .arf_recover  (0),
    .prf_recover  (0),
    .retire_ready (0),
    .out_valid    (0),
    .ready        (0),
    .allocatable  (0)
  );

endmodule
