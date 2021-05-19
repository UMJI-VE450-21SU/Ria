`define PRF_FP_SIZE        64
`define PRF_FP_INDEX_SIZE  6  // log2(64)
`define PRF_FP_WAYS        2

module prf_fp (
  input                                                 clock,
  input                                                 reset,
  input  [`PRF_FP_WAYS-1:0] [`PRF_FP_INDEX_SIZE-1:0]    rda_idx,
  input  [`PRF_FP_WAYS-1:0] [`PRF_FP_INDEX_SIZE-1:0]    rdb_idx,
  input  [`PRF_FP_WAYS-1:0] [`PRF_FP_INDEX_SIZE-1:0]    wr_idx,
  input  [`PRF_FP_WAYS-1:0] [31:0]                      wr_dat,
  input  [`PRF_FP_WAYS-1:0]                             wr_en,
  output logic [`PRF_FP_WAYS-1:0] [31:0]                rda_dat,
  output logic [`PRF_FP_WAYS-1:0] [31:0]                rdb_dat
);

  reg   [`PRF_FP_SIZE-1:0] [31:0]                 rf;
  logic [`PRF_FP_SIZE-1:0] [31:0]                 rf_next;

  logic [`PRF_FP_WAYS-1:0] [`PRF_FP_WAYS-1:0]     opa_is_from_wr;
  logic [`PRF_FP_WAYS-1:0] [`PRF_FP_WAYS-1:0]     opb_is_from_wr;

  generate
    for(genvar i = 0; i < `PRF_FP_WAYS; i = i + 1) begin
      for(genvar j = 0; j < `PRF_FP_WAYS; j = j + 1) begin
        assign opa_is_from_wr[i][j] = wr_en[j] && (wr_idx[j] == rda_idx[i]);
        assign opb_is_from_wr[i][j] = wr_en[j] && (wr_idx[j] == rdb_idx[i]);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `PRF_FP_WAYS; i = i + 1) begin
      rda_dat[i] = rf[rda_idx[i]];
      rdb_dat[i] = rf[rdb_idx[i]];
      for (int j = 0; j < `PRF_FP_WAYS; j = j + 1) begin
        if(opa_is_from_wr[i][j])
          rda_dat[i] = wr_dat[j];  
        if(opb_is_from_wr[i][j])
          rdb_dat[i] = wr_dat[j];
      end
    end
  end

  always_comb begin
    rf_next = rf;
    for (int i = 0; i < `PRF_FP_WAYS; i = i + 1) begin
      if (wr_en[i])
        rf_next[wr_idx[i]] = wr_dat[i];
    end
  end

  always_ff @(posedge clock) begin
    if (reset)
      rf <= 0;
    else
      rf <= rf_next;
  end

endmodule
