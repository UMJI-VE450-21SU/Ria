// Project: RISC-V SoC Microarchitecture Design & Optimization
// Module:  Core (No cache/memory involved)
// Author:  Li Shi, Jian Shi, Yichao Yuan, Yiqiu Sun, Zhiyuan Liu
// Date:    2021/06/21

`include "src/common/micro_op.svh"

module core (
  input clock,
  input reset,

  // ======= icache related ==================
  input        [127:0] icache2core_data,
  input                icache2core_data_valid,
  output logic [31:0]  core2icache_addr,

  // ======= dcache related ==================
  input        [63:0]  dcache2core_data,
  input                dcache2core_data_valid,
  output logic [63:0]  core2dcache_data,
  output logic         core2dcache_data_we,
  output mem_size_t    core2dcache_data_size,
  output logic [31:0]  core2dcache_addr
);

  logic                           stall = 0;
  logic                           clear = 0;

  /* CM ~ Recover Pipeline Registers */

  logic                           cm_recover;
  micro_op_t                      cm_uop_recover;
  micro_op_t  [`COMMIT_WIDTH-1:0] cm_uop_retire;

  logic                           recover;
  micro_op_t                      uop_recover;
  micro_op_t  [`COMMIT_WIDTH-1:0] uop_retire;

  always_ff @(posedge clock) begin
    if (reset) begin
      recover     <= 0;
      uop_recover <= 0;
      uop_retire  <= 0;
    end else begin
      recover     <= cm_recover;
      uop_recover <= cm_uop_recover;
      uop_retire  <= cm_uop_retire;
    end
  end

  assign clear = cm_recover;

  /* Stage Stall Signal */
  logic   if_stall;
  logic   fb_full = 0;
  logic   rr_full;
  logic   cm_full;
  logic   iq_full;
  logic   rr_allocatable;
  logic   cm_allocatable;

  /* Stage 1: IF - Instruction Fetch */

  fb_entry_t [`FETCH_WIDTH-1:0] if_insts_out;
  logic                         if_insts_out_valid;

  assign if_stall = rr_full | fb_full;

  inst_fetch if0 (
    .clock                  (clock                  ),
    .reset                  (reset                  ),
    .stall                  (if_stall               ),
    .uop_retire             (cm_uop_retire          ),
    .icache2core_data       (icache2core_data       ),
    .icache2core_data_valid (icache2core_data_valid ),
    .core2icache_addr       (core2icache_addr       ),
    .insts_out              (if_insts_out           ),
    .insts_out_valid        (if_insts_out_valid     )
  );

  /* IF ~ FB Pipeline Registers */
  
  // Skip FB in T1 version

  /* Stage 2: FB - Fetch Buffer */

  // Skip FB in T1 version

  /* FB ~ ID Pipeline Registers */

  fb_entry_t [`DECODE_WIDTH-1:0]  id_insts_in;
  logic      [`DECODE_WIDTH-1:0]  id_insts_in_valid;

  assign rr_full = cm_full | (~rr_allocatable);

  reg id_stall_reg; // todo: Only for debug purpose
  always_ff @(posedge clock) begin
    if (reset)
      id_stall_reg <= 0;
    else
      id_stall_reg <= if_stall;
  end

  always_ff @(posedge clock) begin
    if (reset | clear | rr_full) begin
      id_insts_in        <= 0;
      id_insts_in_valid  <= 0;
    end else begin
      id_insts_in        <= if_insts_out;
      for (int i = 0; i < `DECODE_WIDTH; i++) begin
        id_insts_in_valid[i] <= if_insts_out_valid & if_insts_out[i].valid;
      end
    end
  end

  /* Stage 3: ID - Instruction Decode */

  micro_op_t [`DECODE_WIDTH-1:0] id_uops_out;

  inst_decode id (
    .clock        (clock              ),
    .reset        (reset              ),
    .insts        (id_insts_in        ),
    .insts_valid  (id_insts_in_valid  ),
    .uops         (id_uops_out        )
  );

  /* ID ~ RR Pipeline Registers */

  micro_op_t [`RENAME_WIDTH-1:0]  rr_uops_in;
  micro_op_t [`DECODE_WIDTH-1:0]  id_uops_out_tmp;
  logic                           rr_stall_prev;

  assign cm_full = iq_full | (~cm_allocatable);

  // todo: consider using switch-case to describe this state machine?
  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rr_uops_in      <= 0;
      id_uops_out_tmp <= 0;
      rr_stall_prev   <= 0;
    end else if (rr_full & (~rr_stall_prev)) begin
      // rr_full = 1; rr_stall_prev = 0;
      // RR stage is full & previous cycle is not stall
      // -> Store data from ID stage
      rr_uops_in      <= 0;
      id_uops_out_tmp <= id_uops_out;
      rr_stall_prev   <= 1;
    end else if (rr_stall_prev & (~rr_full)) begin
      // rr_full = 0; rr_stall_prev = 1;
      // RR Stage is not full & previous cycle is stall
      // -> Output stored data
      rr_uops_in      <= id_uops_out_tmp;
      id_uops_out_tmp <= 0;
      rr_stall_prev   <= 0;
    end else if (rr_full) begin
      // rr_full = 1; rr_stall_prev = 1;
      rr_uops_in      <= 0;
    end else begin
      // rr_full = 0; rr_stall_prev = 0;
      rr_uops_in      <= id_uops_out;
    end
  end

  /* Stage 4: RR - Register Renaming */

  micro_op_t  [`RENAME_WIDTH-1:0] rr_uops_out;

  rat rr (
    .clock        (clock          ),
    .reset        (reset          ),
    .recover      (recover        ),
    .uop_recover  (uop_recover    ),
    .uop_retire   (uop_retire     ),
    .uop_in       (rr_uops_in     ),
    .uop_out      (rr_uops_out    ),
    .allocatable  (rr_allocatable )
  );

  /* RR ~ DP Pipeline Registers */

  micro_op_t [`DECODE_WIDTH-1:0]   rr_uops_out_tmp;
  logic                            dp_stall_prev;

  micro_op_t [`RENAME_WIDTH-1:0]   rob_uops_in;
  micro_op_t [`RENAME_WIDTH-1:0]   rob_uops_out;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uops_in;

  assign iq_full = iq_mem_full | iq_int_full | iq_fp_full;

  logic iq_full_reg;
  always_ff @(posedge clock) begin
    if (reset)
      iq_full_reg <= 0;
    else
      iq_full_reg <= iq_full;
  end

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rob_uops_in     <= 0;
      rr_uops_out_tmp <= 0;
      dp_stall_prev   <= 0;
    end else if (cm_full & (~dp_stall_prev)) begin
      // cm_full = 1; dp_stall_prev = 0;
      // DP stage is full & previous cycle is not stall
      // -> Store data from RR stage
      rob_uops_in     <= 0;
      rr_uops_out_tmp <= rr_uops_out;
      dp_stall_prev   <= 1;
    end else if (dp_stall_prev & (~cm_full)) begin
      // cm_full = 0; dp_stall_prev = 1;
      // DP Stage is not full & previous cycle is stall
      // -> Output stored data
      rob_uops_in     <= rr_uops_out_tmp;
      rr_uops_out_tmp <= 0;
      dp_stall_prev   <= 0;
    end else if (cm_full) begin
      // cm_full = 1; dp_stall_prev = 1;
      rob_uops_in     <= 0;
    end else begin
      // cm_full = 0; dp_stall_prev = 0;
      rob_uops_in     <= rr_uops_out;
    end
  end

  assign dp_uops_in = rob_uops_out;

  /* Stage 5: DP - Dispatch */

  // ... --> ROB --> Dispatcher --> ...

  micro_op_t [`COMMIT_WIDTH-1:0]  cm_uops_complete;

  rob cm (
    .clock          (clock            ),
    .reset          (reset            ),
    .uop_complete   (cm_uops_complete ),
    .uop_in         (rob_uops_in      ),
    .uop_out        (rob_uops_out     ),
    .recover        (cm_recover       ),
    .uop_recover    (cm_uop_recover   ),
    .uop_retire     (cm_uop_retire    ),
    .allocatable    (cm_allocatable   )
  );

  micro_op_t [`DISPATCH_WIDTH-1:0]  dp_uop_to_int;
  micro_op_t [`DISPATCH_WIDTH-1:0]  dp_uop_to_mem;
  micro_op_t [`DISPATCH_WIDTH-1:0]  dp_uop_to_fp;

  dispatch dp (
    .uop_in     (dp_uops_in     ),
    .uop_to_int (dp_uop_to_int  ),
    .uop_to_mem (dp_uop_to_mem  ),
    .uop_to_fp  (dp_uop_to_fp   )
  );

  wire [`DISPATCH_WIDTH-1:0][`PRF_INDEX_SIZE-1:0] set_busy_index;
  wire [`DISPATCH_WIDTH-1:0]                      set_busy_valid;
  wire [`PRF_WAYS-1:0]      [`PRF_INDEX_SIZE-1:0] clear_busy_index;
  wire [`PRF_WAYS-1:0]                            clear_busy_valid;
  wire [`IQ_INT_SIZE-1:0]   [`PRF_INDEX_SIZE-1:0] rs1_int_index;
  wire [`IQ_INT_SIZE-1:0]   [`PRF_INDEX_SIZE-1:0] rs2_int_index;
  wire [`IQ_INT_SIZE-1:0]                         rs1_int_busy;
  wire [`IQ_INT_SIZE-1:0]                         rs2_int_busy;
  wire [`IQ_MEM_SIZE-1:0]   [`PRF_INDEX_SIZE-1:0] rs1_mem_index;
  wire [`IQ_MEM_SIZE-1:0]   [`PRF_INDEX_SIZE-1:0] rs2_mem_index;
  wire [`IQ_MEM_SIZE-1:0]                         rs1_mem_busy;
  wire [`IQ_MEM_SIZE-1:0]                         rs2_mem_busy;
  wire [`IQ_FP_SIZE-1:0]    [`PRF_INDEX_SIZE-1:0] rs1_fp_index;
  wire [`IQ_FP_SIZE-1:0]    [`PRF_INDEX_SIZE-1:0] rs2_fp_index;
  wire [`IQ_FP_SIZE-1:0]    [`PRF_INDEX_SIZE-1:0] rs3_fp_index;
  wire [`IQ_FP_SIZE-1:0]                          rs1_fp_busy;
  wire [`IQ_FP_SIZE-1:0]                          rs2_fp_busy;
  wire [`IQ_FP_SIZE-1:0]                          rs3_fp_busy;
  
  generate
    for (genvar i = 0; i < `DISPATCH_WIDTH; i++) begin
      assign set_busy_index[i] = dp_uops_in[i].rd_prf_index;
      assign set_busy_valid[i] = dp_uops_in[i].rd_valid;
    end
  endgenerate

  scoreboard sb (
    .clock            (clock            ),
    .reset            (reset            ),
    .clear            (clear            ),
    .set_busy_index   (set_busy_index   ),
    .set_busy_valid   (set_busy_valid   ),
    .clear_busy_index (clear_busy_index ),
    .clear_busy_valid (clear_busy_valid ),
    .rs1_int_index    (rs1_int_index    ),
    .rs2_int_index    (rs2_int_index    ),
    .rs1_int_busy     (rs1_int_busy     ),
    .rs2_int_busy     (rs2_int_busy     ),
    .rs1_mem_index    (rs1_mem_index    ),
    .rs2_mem_index    (rs2_mem_index    ),
    .rs1_mem_busy     (rs1_mem_busy     ),
    .rs2_mem_busy     (rs2_mem_busy     ),
    .rs1_fp_index     (rs1_fp_index     ),
    .rs2_fp_index     (rs2_fp_index     ),
    .rs3_fp_index     (rs3_fp_index     ),
    .rs1_fp_busy      (rs1_fp_busy      ),
    .rs2_fp_busy      (rs2_fp_busy      ),
    .rs3_fp_busy      (rs3_fp_busy      )
  );

  /* DP ~ IS Pipeline Registers */

  micro_op_t [`DISPATCH_WIDTH-1:0] is_int_uop_in;
  micro_op_t [`DISPATCH_WIDTH-1:0] is_mem_uop_in;
  micro_op_t [`DISPATCH_WIDTH-1:0] is_fp_uop_in;

  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_int_tmp;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_mem_tmp;
  micro_op_t [`DISPATCH_WIDTH-1:0] dp_uop_to_fp_tmp;
  logic                            is_stall_prev;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      is_int_uop_in     <= 0;
      is_mem_uop_in     <= 0;
      is_fp_uop_in      <= 0;
      dp_uop_to_int_tmp <= 0;
      dp_uop_to_mem_tmp <= 0;
      dp_uop_to_fp_tmp  <= 0;
      is_stall_prev     <= 0;
    end else if (iq_full & (~is_stall_prev)) begin
      // iq_full = 1; is_stall_prev = 0;
      // IS stage is full & previous cycle is not stall
      // -> Store data from DP stage
      is_int_uop_in     <= 0;
      is_mem_uop_in     <= 0;
      is_fp_uop_in      <= 0;
      dp_uop_to_int_tmp <= dp_uop_to_int;
      dp_uop_to_mem_tmp <= dp_uop_to_mem;
      dp_uop_to_fp_tmp  <= dp_uop_to_fp;
      is_stall_prev     <= 1;
    end else if (is_stall_prev & (~iq_full)) begin
      // iq_full = 0; is_stall_prev = 1;
      // IS Stage is not full & previous cycle is stall
      // -> Output stored data
      is_int_uop_in     <= dp_uop_to_int_tmp;
      is_mem_uop_in     <= dp_uop_to_mem_tmp;
      is_fp_uop_in      <= dp_uop_to_fp_tmp;
      dp_uop_to_int_tmp <= 0;
      dp_uop_to_mem_tmp <= 0;
      is_stall_prev     <= 0;
    end else if (iq_full) begin
      is_int_uop_in     <= 0;
      is_mem_uop_in     <= 0;
      is_fp_uop_in      <= 0;
    end else begin
      is_int_uop_in     <= dp_uop_to_int;
      is_mem_uop_in     <= dp_uop_to_mem;
      is_fp_uop_in      <= dp_uop_to_fp_tmp;
    end
  end

  /* Stage 6: IS - Issue */

  logic      [`ISSUE_WIDTH_INT-1:0] ex_int_busy;
  micro_op_t [`ISSUE_WIDTH_INT-1:0] is_int_uop_out;
  logic                             iq_int_full;

  issue_queue_int iq_int (
    .clock        (clock          ),
    .reset        (reset          ),
    .clear_en     (clear          ),
    .load_en      (!iq_full_reg   ),
    .ex_busy      (ex_int_busy    ),
    .rs1_index    (rs1_int_index  ),
    .rs2_index    (rs2_int_index  ),
    .rs1_busy     (rs1_int_busy   ),
    .rs2_busy     (rs2_int_busy   ),
    .uop_in       (is_int_uop_in  ),
    .uop_out      (is_int_uop_out ),
    .iq_int_full  (iq_int_full    )
  );

  logic      [`ISSUE_WIDTH_MEM-1:0] ex_mem_busy;
  micro_op_t [`ISSUE_WIDTH_MEM-1:0] is_mem_uop_out;
  logic                             iq_mem_full;

  issue_queue_mem iq_mem (
    .clock        (clock          ),
    .reset        (reset          ),
    .clear_en     (clear          ),
    .load_en      (!iq_full_reg   ),
    .ex_busy      (ex_mem_busy    ),
    .rs1_index    (rs1_mem_index  ),
    .rs2_index    (rs2_mem_index  ),
    .rs1_busy     (rs1_mem_busy   ),
    .rs2_busy     (rs2_mem_busy   ),
    .uop_in       (is_mem_uop_in  ),
    .uop_out      (is_mem_uop_out ),
    .iq_mem_full  (iq_mem_full    )
  );

  logic      [`ISSUE_WIDTH_FP-1:0]  ex_fp_busy;
  micro_op_t [`ISSUE_WIDTH_FP-1:0]  is_fp_uop_out;
  logic                             iq_fp_full;

  issue_queue_fp iq_fp (
    .clock        (clock          ),
    .reset        (reset          ),
    .clear_en     (clear          ),
    .load_en      (!iq_full_reg   ),
    .ex_busy      (ex_fp_busy     ),
    .rs1_index    (rs1_fp_index   ),
    .rs2_index    (rs2_fp_index   ),
    .rs3_index    (rs3_fp_index   ),
    .rs1_busy     (rs1_fp_busy    ),
    .rs2_busy     (rs2_fp_busy    ),
    .rs3_busy     (rs3_fp_busy    ),
    .uop_in       (is_fp_uop_in   ),
    .uop_out      (is_fp_uop_out  ),
    .iq_fp_full   (iq_fp_full     )
  );

  /* IS ~ RF Pipeline Registers */

  micro_op_t [`PRF_WAYS-1:0] rf_uop_in;

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      rf_uop_in <= 0;
    end else if (!stall) begin
      rf_uop_in <= {is_int_uop_out, is_mem_uop_out, is_fp_uop_out};
    end
  end

  /* Stage 7: RF - Register File */

  logic [`PRF_WAYS-1:0] [`PRF_INDEX_SIZE-1:0] rf_rd_index_in;
  logic [`PRF_WAYS-1:0] [63:0]  rf_rd_data_in; 
  logic [`PRF_WAYS-1:0]         rf_rd_en_in;

  micro_op_t [`PRF_WAYS-1:0]    rf_uop_out;
  logic [`PRF_WAYS-1:0][63:0]   rf_rs1_data_out;
  logic [`PRF_WAYS-1:0][63:0]   rf_rs2_data_out;
  logic [`PRF_WAYS-1:0][63:0]   rf_rs3_data_out;

  prf rf (
    .clock    (clock            ),
    .reset    (reset            ),
    .uop_in   (rf_uop_in        ),
    .rd_index (rf_rd_index_in   ),
    .rd_data  (rf_rd_data_in    ),
    .rd_en    (rf_rd_en_in      ),
    .uop_out  (rf_uop_out       ),
    .rs1_data (rf_rs1_data_out  ),
    .rs2_data (rf_rs2_data_out  ),
    .rs3_data (rf_rs3_data_out  )
  );

  /* RF ~ EX Pipeline Registers */

  micro_op_t [`ISSUE_WIDTH_INT-1:0]   ex_int_uop_in;
  logic [`ISSUE_WIDTH_INT-1:0][31:0]  ex_int_rs1_data_in;
  logic [`ISSUE_WIDTH_INT-1:0][31:0]  ex_int_rs2_data_in;
  micro_op_t [`ISSUE_WIDTH_MEM-1:0]   ex_mem_uop_in;
  logic [`ISSUE_WIDTH_MEM-1:0][31:0]  ex_mem_rs1_data_in;
  logic [`ISSUE_WIDTH_MEM-1:0][31:0]  ex_mem_rs2_data_in;
  micro_op_t [`ISSUE_WIDTH_FP-1:0]    ex_fp_uop_in;
  logic [`ISSUE_WIDTH_FP-1:0][63:0]   ex_fp_rs1_data_in;
  logic [`ISSUE_WIDTH_FP-1:0][63:0]   ex_fp_rs2_data_in;
  logic [`ISSUE_WIDTH_FP-1:0][63:0]   ex_fp_rs3_data_in;

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
        ex_int_uop_in[i]      <= rf_uop_out[i][31:0];
        ex_int_rs1_data_in[i] <= rf_rs1_data_out[i][31:0];
        ex_int_rs2_data_in[i] <= rf_rs2_data_out[i][31:0];
      end
      for (int i = `ISSUE_WIDTH_INT; i < `ISSUE_WIDTH_MEM + `ISSUE_WIDTH_INT; i++) begin
        ex_mem_uop_in[i]      <= rf_uop_out[i];
        ex_mem_rs1_data_in[i] <= rf_rs1_data_out[i];
        ex_mem_rs2_data_in[i] <= rf_rs2_data_out[i];
      end
      for (int i = `ISSUE_WIDTH_MEM + `ISSUE_WIDTH_INT; i < `ISSUE_WIDTH_TATAL; i++) begin
        ex_fp_uop_in[i]      <= rf_uop_out[i];
        ex_fp_rs1_data_in[i] <= rf_rs1_data_out[i];
        ex_fp_rs2_data_in[i] <= rf_rs2_data_out[i];
        ex_fp_rs3_data_in[i] <= rf_rs3_data_out[i];
      end
    end
  end

  /* Stage 8: EX - Execution */

  micro_op_t [`ISSUE_WIDTH_INT-1:0]  ex_int_uop_out;
  logic [`ISSUE_WIDTH_INT-1:0][31:0] ex_int_rd_data_out;
  logic [1:0]                        ex_int_br_taken;

  // ALU + BR
  pipe_0_1 pipe_0 (
    .clock    (clock                  ),
    .reset    (reset                  ),
    .clear    (clear                  ),
    .uop      (ex_int_uop_in      [0] ),
    .in1      (ex_int_rs1_data_in [0] ),
    .in2      (ex_int_rs2_data_in [0] ),
    .uop_out  (ex_int_uop_out     [0] ),
    .br_taken (ex_int_br_taken    [0] ),
    .out      (ex_int_rd_data_out [0] ),
    .busy     (ex_int_busy        [0] )
  );

  // ALU + BR
  pipe_0_1 pipe_1 (
    .clock    (clock                  ),
    .reset    (reset                  ),
    .clear    (clear                  ),
    .uop      (ex_int_uop_in      [1] ),
    .in1      (ex_int_rs1_data_in [1] ),
    .in2      (ex_int_rs2_data_in [1] ),
    .uop_out  (ex_int_uop_out     [1] ),
    .br_taken (ex_int_br_taken    [1] ),
    .out      (ex_int_rd_data_out [1] ),
    .busy     (ex_int_busy        [1] )
  );

  // ALU + IDIV
  pipe_2 pipe_2 (
    .clock    (clock                 ),
    .reset    (reset                 ),
    .clear    (clear                 ),
    .uop      (ex_int_uop_in      [2]),
    .in1      (ex_int_rs1_data_in [2]),
    .in2      (ex_int_rs2_data_in [2]),
    .uop_out  (ex_int_uop_out     [2]),
    .out      (ex_int_rd_data_out [2]),
    .busy     (ex_int_busy        [2])
  );

  micro_op_t [`ISSUE_WIDTH_MEM-1:0]  ex_mem_uop_out;
  logic [`ISSUE_WIDTH_MEM-1:0][31:0] ex_mem_rd_data_out;

  // LOAD / STORE
  pipe_3 pipe_3 (
    .clock                  (clock                 ),
    .reset                  (reset                 ),
    .clear                  (clear                 ),
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
    .core2dcache_addr       (core2dcache_addr      )
  );

  micro_op_t [`ISSUE_WIDTH_FP-1:0]  ex_fp_uop_out;
  logic [`ISSUE_WIDTH_FP-1:0][63:0] ex_fp_rd_data_out;

  /* EX ~ WB Pipeline Registers (inside EX pipes) */
  
  micro_op_t [`COMMIT_WIDTH-1:0] wb_uops;

  assign wb_uops = {ex_int_uop_out, ex_mem_uop_out, ex_fp_uop_out};

  /* Stage 9: WB - Write Back */

  // Note: ex_***_uop_out and ex_***_rd_data_out are sequential logics
  generate
    for (genvar i = 0; i < `ISSUE_WIDTH_INT; i++) begin
      assign rf_rd_index_in[i] = ex_int_uop_out[i].rd_prf_index;
      assign rf_rd_data_in [i] = ex_int_rd_data_out[i];
      assign rf_rd_en_in   [i] = ex_int_uop_out[i].rd_valid;
      assign clear_busy_index  [i] = ex_int_uop_out[i].rd_prf_index;
      assign clear_busy_valid  [i] = ex_int_uop_out[i].rd_valid;
    end
    for (genvar i = 0; i < `ISSUE_WIDTH_MEM; i++) begin
      assign rf_rd_index_in[i + `ISSUE_WIDTH_INT] = ex_mem_uop_out[i].rd_prf_index;
      assign rf_rd_data_in [i + `ISSUE_WIDTH_INT] = ex_mem_rd_data_out[i];
      assign rf_rd_en_in   [i + `ISSUE_WIDTH_INT] = ex_mem_uop_out[i].rd_valid;
      assign clear_busy_index  [i + `ISSUE_WIDTH_INT] = ex_mem_uop_out[i].rd_prf_index;
      assign clear_busy_valid  [i + `ISSUE_WIDTH_INT] = ex_mem_uop_out[i].rd_valid;
    end
  endgenerate

  /* WB ~ CM Pipeline Registers */

  always_ff @(posedge clock) begin
    if (reset | clear) begin
      cm_uops_complete <= 0;
    end else begin
      cm_uops_complete <= wb_uops;
    end
  end

  /* Stage 10: CM - Commit */

  // See Stage 5: DP

  /* Debug Messages        */

  // wire if_id_print = 1;
  // wire id_rr_print = 1;
  // wire rr_dp_print = 1;
  // wire dp_is_print = 1;
  // wire is_rf_print = 1;
  // wire rf_ex_print = 1;
  // wire ex_wb_print = 1;
  // wire wb_cm_print = 1;

  // always_ff @(posedge clock) begin
  //   $display("===== Pipeline Registers =====");
  //   if (if_id_print) begin
  //     $display("[IF-ID] id_insts_in[0].pc=%h, id_insts_in[0].inst=%h, id_insts_in_valid[0]=%b", 
  //             id_insts_in[0].pc, id_insts_in[0].inst, id_insts_in_valid[0]);
  //     $display("[IF-ID] id_insts_in[1].pc=%h, id_insts_in[1].inst=%h, id_insts_in_valid[1]=%b", 
  //             id_insts_in[1].pc, id_insts_in[1].inst, id_insts_in_valid[1]);
  //     $display("[IF-ID] id_insts_in[2].pc=%h, id_insts_in[2].inst=%h, id_insts_in_valid[2]=%b", 
  //             id_insts_in[2].pc, id_insts_in[2].inst, id_insts_in_valid[2]);
  //     $display("[IF-ID] id_insts_in[3].pc=%h, id_insts_in[3].inst=%h, id_insts_in_valid[3]=%b", 
  //             id_insts_in[3].pc, id_insts_in[3].inst, id_insts_in_valid[3]);
  //   end
  //   if (id_rr_print) begin
  //     $display("[ID-RR] rr_uops_in[0]");
  //     print_uop(rr_uops_in[0]);
  //     $display("[ID-RR] rr_uops_in[1]");
  //     print_uop(rr_uops_in[1]);
  //     $display("[ID-RR] rr_uops_in[2]");
  //     print_uop(rr_uops_in[2]);
  //     $display("[ID-RR] rr_uops_in[3]");
  //     print_uop(rr_uops_in[3]);
  //   end
  //   if (rr_dp_print) begin
  //     $display("[RR-DP] rob_uops_in[0]");
  //     print_uop(rob_uops_in[0]);
  //     $display("[RR-DP] rob_uops_in[1]");
  //     print_uop(rob_uops_in[1]);
  //     $display("[RR-DP] rob_uops_in[2]");
  //     print_uop(rob_uops_in[2]);
  //     $display("[RR-DP] rob_uops_in[3]");
  //     print_uop(rob_uops_in[3]);
  //   end
  //   if (dp_is_print) begin
  //     $display("[DP-IS] is_int_uop_in[0]");
  //     print_uop(is_int_uop_in[0]);
  //     $display("[DP-IS] is_int_uop_in[1]");
  //     print_uop(is_int_uop_in[1]);
  //     $display("[DP-IS] is_int_uop_in[2]");
  //     print_uop(is_int_uop_in[2]);
  //     $display("[DP-IS] is_int_uop_in[3]");
  //     print_uop(is_int_uop_in[3]);
  //     $display("[DP-IS] is_mem_uop_in[0]");
  //     print_uop(is_mem_uop_in[0]);
  //     $display("[DP-IS] is_mem_uop_in[1]");
  //     print_uop(is_mem_uop_in[1]);
  //     $display("[DP-IS] is_mem_uop_in[2]");
  //     print_uop(is_mem_uop_in[2]);
  //     $display("[DP-IS] is_mem_uop_in[3]");
  //     print_uop(is_mem_uop_in[3]);
  //   end
  //   if (is_rf_print) begin
  //     $display("[IS-RF] rf_int_uop_in[0]");
  //     print_uop(rf_int_uop_in[0]);
  //     $display("[IS-RF] rf_int_uop_in[1]");
  //     print_uop(rf_int_uop_in[1]);
  //     $display("[IS-RF] rf_int_uop_in[2]");
  //     print_uop(rf_int_uop_in[2]);
  //     $display("[IS-RF] rf_int_uop_in[3]");
  //     print_uop(rf_int_uop_in[3]);
  //   end
  //   if (rf_ex_print) begin
  //     $display("[RF-EX] ex_int_uop_in[0], rs1_data_in=%h, rs2_data_in=%h", ex_int_rs1_data_in[0], ex_int_rs2_data_in[0]);
  //     print_uop(ex_int_uop_in[0]);
  //     $display("[RF-EX] ex_int_uop_in[1], rs1_data_in=%h, rs2_data_in=%h", ex_int_rs1_data_in[1], ex_int_rs2_data_in[1]);
  //     print_uop(ex_int_uop_in[1]);
  //     $display("[RF-EX] ex_int_uop_in[2], rs1_data_in=%h, rs2_data_in=%h", ex_int_rs1_data_in[2], ex_int_rs2_data_in[2]);
  //     print_uop(ex_int_uop_in[2]);
  //     $display("[RF-EX] ex_mem_uop_in[0], rs1_data_in=%h, rs2_data_in=%h", ex_mem_rs1_data_in[0], ex_mem_rs2_data_in[0]);
  //     print_uop(ex_mem_uop_in[0]);
  //   end
  //   if (ex_wb_print) begin
  //     $display("[EX-WB] wb_uops[0], rd_data_in=%h, rd=%h, rd_en=%b", 
  //              rf_int_rd_data_in[0], rf_int_rd_index_in[0], rf_int_rd_en_in[0]);
  //     print_uop(wb_uops[0]);
  //     $display("[EX-WB] wb_uops[1], rd_data_in=%h, rd=%h, rd_en=%b", 
  //              rf_int_rd_data_in[1], rf_int_rd_index_in[1], rf_int_rd_en_in[1]);
  //     print_uop(wb_uops[1]);
  //     $display("[EX-WB] wb_uops[2], rd_data_in=%h, rd=%h, rd_en=%b", 
  //              rf_int_rd_data_in[2], rf_int_rd_index_in[2], rf_int_rd_en_in[2]);
  //     print_uop(wb_uops[2]);
  //     $display("[EX-WB] wb_uops[3], rd_data_in=%h, rd=%h, rd_en=%b", 
  //              rf_int_rd_data_in[3], rf_int_rd_index_in[3], rf_int_rd_en_in[3]);
  //     print_uop(wb_uops[3]);
  //   end
  //   if (wb_cm_print) begin
  //     $display("[WB-CM] cm_uops_complete[0]");
  //     print_uop(cm_uops_complete[0]);
  //     $display("[WB-CM] cm_uops_complete[1]");
  //     print_uop(cm_uops_complete[1]);
  //     $display("[WB-CM] cm_uops_complete[2]");
  //     print_uop(cm_uops_complete[2]);
  //     $display("[WB-CM] cm_uops_complete[3]");
  //     print_uop(cm_uops_complete[3]);
  //   end
  //   $display("==============================");
  //   $display("|---ID---|---RR---(--------)|---DP---(--------)|---IS---(--------)|---RF---|---EX---|---WB---|---CM---|-Retire-|");
  //   $display("|%h|%h(%h)|%h(%h)|%h(%h)|%h|%h|%h|%h|%h|", 
  //            id_insts_in[0].pc, rr_uops_in[0].pc, id_uops_out_tmp[0].pc, rob_uops_in[0].pc, rr_uops_out_tmp[0].pc,
  //            is_int_uop_in[0].pc, dp_uop_to_int_tmp[0].pc,
  //            rf_int_uop_in[0].pc, ex_int_uop_in[0].pc, wb_uops[0].pc, cm_uops_complete[0].pc, uop_retire[0].pc);
  //   $display("|%h|%h(%h)|%h(%h)|%h(%h)|%h|%h|%h|%h|%h|", 
  //            id_insts_in[1].pc, rr_uops_in[1].pc, id_uops_out_tmp[1].pc, rob_uops_in[1].pc, rr_uops_out_tmp[1].pc,
  //            is_int_uop_in[1].pc, dp_uop_to_int_tmp[1].pc,
  //            rf_int_uop_in[1].pc, ex_int_uop_in[1].pc, wb_uops[1].pc, cm_uops_complete[1].pc, uop_retire[1].pc);
  //   $display("|%h|%h(%h)|%h(%h)|%h(%h)|%h|%h|%h|%h|%h|", 
  //            id_insts_in[2].pc, rr_uops_in[2].pc, id_uops_out_tmp[2].pc, rob_uops_in[2].pc, rr_uops_out_tmp[2].pc,
  //            is_int_uop_in[2].pc, dp_uop_to_int_tmp[2].pc,
  //            rf_int_uop_in[2].pc, ex_int_uop_in[2].pc, wb_uops[2].pc, cm_uops_complete[2].pc, uop_retire[2].pc);
  //   $display("|%h|%h(%h)|%h(%h)|%h(%h)|        |        |        |        |%h|", 
  //            id_insts_in[3].pc, rr_uops_in[3].pc, id_uops_out_tmp[3].pc, rob_uops_in[3].pc, rr_uops_out_tmp[3].pc,
  //            is_int_uop_in[3].pc, dp_uop_to_int_tmp[3].pc, uop_retire[3].pc);
  //   $display("|        |                  |                  |%h(%h)|%h|%h|%h|%h|%h|", 
  //            is_mem_uop_in[0].pc, dp_uop_to_mem_tmp[0].pc,
  //            rf_int_uop_in[3].pc, ex_mem_uop_in[0].pc, wb_uops[3].pc, cm_uops_complete[3].pc, uop_retire[4].pc);
  //   $display("|        |                  |                  |%h(%h)|        |        |        |        |%h|", 
  //            is_mem_uop_in[1].pc, dp_uop_to_mem_tmp[1].pc, uop_retire[5].pc);
  //   $display("|        |                  |                  |%h(%h)|        |        |        |        |", 
  //            is_mem_uop_in[2].pc, dp_uop_to_mem_tmp[2].pc);
  //   $display("|        |                  |                  |%h(%h)|        |        |        |        |", 
  //            is_mem_uop_in[3].pc, dp_uop_to_mem_tmp[3].pc);
  //   $display("|full: %h |full: %h           |full: %h           |full: %h           |        |        |        |        |", 
  //            id_stall_reg, rr_stall_prev, dp_stall_prev, iq_full_reg);
  //   $display("|---ID---|---RR---(--------)|---DP---(--------)|---IS---(--------)|---RF---|---EX---|---WB---|---CM---|");
  // end

endmodule
