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
  output logic [31:0]  core2icache_addr,

  // ======= dcache related ==================
  input        [63:0]  dcache2core_data,
  input                dcache2core_data_valid,
  output logic [63:0]  core2dcache_data,
  output logic         core2dcache_data_we,
  output mem_size_t    core2dcache_data_size,
  input                dcache2core_data_w_ack,
  output logic [31:0]  core2dcache_addr
);

  logic                           stall;

  logic                           recover;
  logic       [`ARF_INT_SIZE-1:0] arf_recover;
  logic       [`PRF_INT_SIZE-1:0] prf_recover;
  micro_op_t                      uop_recover;
  micro_op_t  [`COMMIT_WIDTH-1:0] uop_retire;

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
    .insts_out_valid        (if_insts_out_valid)
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

  assign rr_uops_in = id_uops_out;

  /* Stage 4: RR - Register Renaming */

  micro_op_t  [`RENAME_WIDTH-1:0] rr_uops_out;
  logic                           rr_allocatable;
  logic                           rr_ready;

  rat rr (
    .clock        (clock          ),
    .reset        (reset          ),
    .input_valid  (1              ),
    .recover      (recover        ),
    .arf_recover  (arf_recover    ),
    .prf_recover  (prf_recover    ),
    .uop_recover  (uop_recover    ),
    .uop_retire   (uop_retire     ),
    .uop_in       (rr_uops_in     ),
    .uop_out      (rr_uops_out    ),
    .allocatable  (rr_allocatable ),
    .ready        (rr_ready       )
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

  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_int;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_mem;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_fp;
  micro_op_t [`DISPATCH_WIDTH-1:0] is_int_uop_in;
  micro_op_t [`DISPATCH_WIDTH-1:0] is_mem_uop_in;
  micro_op_t [`DISPATCH_WIDTH-1:0] is_fp_uop_in;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      is_int_uop_in <= 0;
      is_mem_uop_in <= 0;
      is_fp_uop_in  <= 0;
    end else if (!stall) begin
      is_int_uop_in <= dp_uop_to_int;
      is_mem_uop_in <= dp_uop_to_mem;
      is_fp_uop_in  <= dp_uop_to_fp;
    end
  end

  /* Stage 6: IS - Issue */

  logic [`ISSUE_WIDTH_INT-1:0] [`PRF_INT_INDEX_SIZE-1:0] ctb_prf_int_index;
  logic [`ISSUE_WIDTH_INT-1:0]      ctb_valid;

  logic      [`ISSUE_WIDTH_INT-1:0] ex_int_busy;
  micro_op_t [`ISSUE_WIDTH_INT-1:0] is_int_uop_out;
  logic                             iq_int_full;

  issue_queue_int is_int (
    .clock              (clock),
    .reset              (reset),
    .ctb_prf_int_index  (ctb_prf_int_index),
    .ctb_valid          (ctb_valid),
    .ex_busy            (ex_int_busy),
    .uop_in             (is_int_uop_in),
    .uop_out            (is_int_uop_out),
    .iq_int_full        (iq_int_full)
  );

  logic      [`ISSUE_WIDTH_MEM-1:0] ex_mem_busy;
  micro_op_t [`ISSUE_WIDTH_MEM-1:0] is_mem_uop_out;
  logic                             iq_mem_full;

  issue_queue_mem is_mem (
    .clock              (clock),
    .reset              (reset),
    .ctb_prf_int_index  (ctb_prf_int_index),
    .ctb_valid          (ctb_valid),
    .ex_busy            (ex_mem_busy),
    .uop_in             (is_mem_uop_in),
    .uop_out            (is_mem_uop_out),
    .iq_mem_full        (iq_mem_full)
  );

  /* IS ~ RF Pipeline Registers */

  micro_op_t [`PRF_INT_WAYS-1:0] rf_int_uop_in;
  // micro_op_t [`ISSUE_WIDTH_FP-1:0]  rf_fp_uop_in;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rf_int_uop_in <= 0;
      rf_mem_uop_in <= 0;
      // rf_fp_uop_in  <= 0;
    end else if (!stall) begin
      for (int i = 0; i < `ISSUE_WIDTH_INT; i++)
        rf_int_uop_in[i] <= is_int_uop_out[i];
      for (int i = 0; i < `ISSUE_WIDTH_MEM; i++)
        rf_int_uop_in[i + `ISSUE_WIDTH_INT] <= is_mem_uop_out[i];
    end
  end

  /* Stage 7: RF - Register File */

  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0] rf_int_rd_index_in;
  logic [`PRF_INT_WAYS-1:0] [31:0]  rf_int_rd_data_in; 
  logic [`PRF_INT_WAYS-1:0]         rf_int_rd_en_in;

  micro_op_t [`PRF_INT_WAYS-1:0]    rf_int_uop_out;
  logic [`PRF_INT_WAYS-1:0][31:0]   rf_int_rs1_data_out;
  logic [`PRF_INT_WAYS-1:0][31:0]   rf_int_rs2_data_out;

  prf_int rf_int (
    .clock    (clock),
    .reset    (reset),
    .uop_in   (rf_int_uop_in),
    .rd_index (rf_int_rd_index_in),
    .rd_data  (rf_int_rd_data_in),
    .rd_en    (rf_int_rd_en_in),
    .uop_out  (rf_int_uop_out),
    .rs1_data (rf_int_rs1_data_out),
    .rs2_data (rf_int_rs2_data_out)
  );

  /* RF ~ EX Pipeline Registers */

  micro_op_t [`ISSUE_WIDTH_INT-1:0]  ex_int_uop_in;
  logic [`ISSUE_WIDTH_INT-1:0][31:0] ex_int_rs1_data_in;
  logic [`ISSUE_WIDTH_INT-1:0][31:0] ex_int_rs2_data_in;
  micro_op_t [`ISSUE_WIDTH_MEM-1:0]  ex_mem_uop_in;
  logic [`ISSUE_WIDTH_MEM-1:0][31:0] ex_mem_rs1_data_in;
  logic [`ISSUE_WIDTH_MEM-1:0][31:0] ex_mem_rs2_data_in;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      ex_int_uop_in      <= 0;
      ex_int_rs1_data_in <= 0;
      ex_int_rs2_data_in <= 0;
      ex_mem_uop_in      <= 0;
      ex_mem_rs1_data_in <= 0;
      ex_mem_rs2_data_in <= 0;
    end else if (!stall) begin
      for (int i = 0; i < `ISSUE_WIDTH_INT; i++) begin
        ex_int_uop_in[i]      <= rf_int_uop_out[i];
        ex_int_rs1_data_in[i] <= rf_int_rs1_data_out[i];
        ex_int_rs2_data_in[i] <= rf_int_rs2_data_out[i];
      end
      for (int i = 0; i < `ISSUE_WIDTH_MEM; i++) begin
        ex_mem_uop_in[i]      <= rf_int_uop_out[i + `ISSUE_WIDTH_INT];
        ex_mem_rs1_data_in[i] <= rf_int_rs1_data_out[i + `ISSUE_WIDTH_INT];
        ex_mem_rs2_data_in[i] <= rf_int_rs2_data_out[i + `ISSUE_WIDTH_INT];
      end
    end
  end

  /* Stage 8: EX - Execution */

  micro_op_t [`ISSUE_WIDTH_INT-1:0]  ex_int_uop_out;
  logic [`ISSUE_WIDTH_INT-1:0][31:0] ex_int_rd_data_out;

  pipe_0 pipe_0 (
    .clock    (clock                 ),
    .reset    (reset                 ),
    .uop      (ex_int_uop_in      [0]),
    .in1      (ex_int_rs1_data_in [0]),
    .in2      (ex_int_rs2_data_in [0]),
    .uop_out  (ex_int_uop_out     [0]),
    .out      (ex_int_rd_data_out [0]),
    .busy     (ex_int_busy        [0])
  );

  pipe_1 pipe_1 (
    .clock    (clock                 ),
    .reset    (reset                 ),
    .uop      (ex_int_uop_in      [1]),
    .in1      (ex_int_rs1_data_in [1]),
    .in2      (ex_int_rs2_data_in [1]),
    .uop_out  (ex_int_uop_out     [1]),
    .out      (ex_int_rd_data_out [1]),
    .busy     (ex_int_busy        [1])
  );

  pipe_2 pipe_2 (
    .clock    (clock                 ),
    .reset    (reset                 ),
    .uop      (ex_int_uop_in      [2]),
    .in1      (ex_int_rs1_data_in [2]),
    .in2      (ex_int_rs2_data_in [2]),
    .uop_out  (ex_int_uop_out     [2]),
    .out      (ex_int_rd_data_out [2]),
    .busy     (ex_int_busy        [2])
  );

  micro_op_t [`ISSUE_WIDTH_MEM-1:0]  ex_mem_uop_out;
  logic [`ISSUE_WIDTH_MEM-1:0][31:0] ex_mem_rd_data_out;

  pipe_3 pipe_3 (
    .clock                  (clock                 ),
    .reset                  (reset                 ),
    .uop                    (ex_mem_uop_in      [0]),
    .in1                    (ex_mem_rs1_data_in [0]),
    .in2                    (ex_mem_rs2_data_in [0]),
    .uop_out                (ex_mem_uop_out     [0]),
    .out                    (ex_mem_rd_data_out [0]),
    .busy                   (ex_mem_busy        [0]),
    .dcache2core_data       (dcache2core_data      ),
    .dcache2core_data_valid (dcache2core_data_valid),
    .core2dcache_data       (core2dcache_data      ),
    .core2dcache_data_we    (core2dcache_data_we   ),
    .core2dcache_data_size  (core2dcache_data_size ),
    .dcache2core_data_w_ack (dcache2core_data_w_ack),
    .core2dcache_addr       (core2dcache_addr      )
  );

  /* EX ~ WB Pipeline Registers */



  /* Stage 9: WB - Write Back */

  /* WB ~ CM Pipeline Registers */

  /* RR ~ CM Pipeline Registers */

  logic                           cm_in_valid;
  micro_op_t [`COMMIT_WIDTH-1:0]  cm_uop_complete;
  micro_op_t [`RENAME_WIDTH-1:0]  cm_uops_in;

  assign cm_in_valid  = rr_ready & rr_allocatable;
  assign cm_uops_in   = rr_uops_out;

  /* Stage 10: CM - Commit */

  micro_op_t  [`RENAME_WIDTH-1:0] cm_uops_out;
  logic                           cm_allocatable;
  logic                           cm_ready;

  rob cm (
    .clock        (clock            ),
    .reset        (reset            ),
    .input_valid  (cm_in_valid      ),
    .uop_complete (cm_uop_complete  ),
    .uop_in       (cm_uops_in       ),
    .uop_out      (cm_uops_out      ),
    .recover      (recover          ),
    .uop_recover  (uop_recover      ),
    .arf_recover  (arf_recover      ),
    .prf_recover  (prf_recover      ),
    .allocatable  (cm_allocatable   ),
    .ready        (cm_ready         )
  );

endmodule
