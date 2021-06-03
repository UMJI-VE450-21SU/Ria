`include "defines.svh"

module prf_int (
  input                                                 clock,
  input                                                 reset,
  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rs1_index,
  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rs2_index,
  input  [`PRF_INT_WAYS-1:0] [`PRF_INT_INDEX_SIZE-1:0]  rd_index,
  input  [`PRF_INT_WAYS-1:0] [31:0]                     rd_data,
  input  [`PRF_INT_WAYS-1:0]                            rd_en,
  output logic [`PRF_INT_WAYS-1:0] [31:0]               rs1_data,
  output logic [`PRF_INT_WAYS-1:0] [31:0]               rs2_datat
);

  reg   [`PRF_INT_SIZE-1:0] [31:0]                rf;
  logic [`PRF_INT_SIZE-1:0] [31:0]                rf_next;

  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_WAYS-1:0]   rs1_from_rd;
  logic [`PRF_INT_WAYS-1:0] [`PRF_INT_WAYS-1:0]   rs2_from_rd;

  generate
    for(genvar i = 0; i < `PRF_INT_WAYS; i = i + 1) begin
      for(genvar j = 0; j < `PRF_INT_WAYS; j = j + 1) begin
        assign rs1_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs1_index[i]);
        assign rs2_from_rd[i][j] = rd_en[j] && (rd_index[j] == rs2_index[i]);
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < `PRF_INT_WAYS; i = i + 1) begin
      rs1_data[i] = rf[rs1_index[i]];
      rs2_datat[i] = rf[rs2_index[i]];
      for (int j = 0; j < `PRF_INT_WAYS; j = j + 1) begin
        if(rs1_from_rd[i][j])
          rs1_data[i] = rd_data[j];  
        if(rs2_from_rd[i][j])
          rs2_data[i] = rd_data[j];
      end
    end
  end

  always_comb begin
    rf_next = rf;
    for (int i = 0; i < `PRF_INT_WAYS; i = i + 1) begin
      if (rd_en[i])
        rf_next[rd_index[i]] = rd_data[i];
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      rf <= 0;
    end else begin
      rf <= rf_next;
    end
  end

endmodule
