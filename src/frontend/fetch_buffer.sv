//////////////////////////////////////////////////////////////////////////////////
// Project Name: RIA
// Create Date: 2021/06/01
// Contributor: Zhiyuan Liu
// Reviewer: 
// Module Name: 
// Target Devices: instruction buffer
// Description: 
// instruction buffer
// Dependencies: 
// ../common/defines.svh
//////////////////////////////////////////////////////////////////////////////////
`include "../common/defines.svh"

module fetch_buffer(
    input          [`INST_PACK-1:0]        inst_value,
    input          [`INST_FETCH_NUM-1:0]   inst_valid,
    input                                  reset,
    output  logic                          full,
    output  logic  [`INST_INDEX_SIZE-1:0]  inst0,
    output  logic  [`INST_INDEX_SIZE-1:0]  inst1,
    output  logic  [`INST_INDEX_SIZE-1:0]  inst2,
    output  logic  [`INST_INDEX_SIZE-1:0]  inst3,
    output  logic  [`INST_FETCH_NUM-1:0]   valid

);

    logic [`INST_INDEX_SIZE-1:0] inst_buffer [`IB_SIZE-1:0];

logic                         empty;   
reg [`IB_ADDR-1:0]            front;
logic  [`IB_ADDR-1:0]         next_front;
reg [`IB_ADDR-1:0]            rear;
logic  [`IB_ADDR-1:0]         next_rear;
logic [`INST_PACK-1:0]        temp_inst_buffer;
    reg [`IB_ADDR-1:0]        num_free;
    logic [`IB_ADDR-1:0]      next_num_free;

assign full = (next_num_free < `INST_FETCH_NUM);
    
assign {inst3,inst2,inst1,inst0} = temp_inst_buffer;
    
always_ff @ (posedge clock) begin
    if (reset) begin
        front <= 0;
        rear <= 0;
        num_free <= `IB_SIZE;
    end
    else begin
        front <= next_front;
        rear <= next_rear;
        num_free <= next_num_free;
    end
end
        
always_comb begin
    // out
    if (num_free > ) 
    // in
end
      
        
        
        //if slot < 4, then output buffer full 
        if (rear >= front) begin
            full <= ~ (empty |   ((rear - front) + 1 <= `IB_SIZE - 4));
        end else begin
            full <= ~ ((`IB_SIZE - (front - rear) + 1) <= `IB_SIZE -4);
        end
        
        //enqueue the valid instruction: no need to consider buffer full, handle above
        generate
            for (genvar i = 0; i < `INST_FETCH_NUM; i++) begin
                if (inst_valid[i]) begin
                    if (empty) begin
                        empty <= 1'b0;
                        inst_buffer[rear] <= inst_value[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*i:`INST_INDEX_SIZE*i];
                    end else begin
                        rear <= (rear + 1) % `IB_SIZE;
                        inst_buffer[rear] <= inst_value[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*i:`INST_INDEX_SIZE*i];
                    end
                end else begin
                    pass
                end
            end
        endgenerate

        //dequeue the instructions
        if (empty) begin
            inst0 <= `INST_INDEX_SIZE'd0;
            inst1 <= `INST_INDEX_SIZE'd0;
            inst2 <= `INST_INDEX_SIZE'd0;
            inst3 <= `INST_INDEX_SIZE'd0;
            valid <= `INST_FETCH_NUM'd0;
        end else begin

           generate
               for (genvar j = 0; j <`INST_FETCH_NUM; j++) begin

                   if (empty) begin
                       temp_inst_buffer[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*i:`INST_INDEX_SIZE*i] <= `INST_INDEX_SIZE'd0;
                       valid[j] <= 1'b0;
                   end else begin

                       if (front == rear) begin
                           temp_inst_buffer[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*i:`INST_INDEX_SIZE*i] <= inst_buffer[front];
                           empty <= 1'b1;
                           valid[j] <= 1'b1;
                       end else begin
                           temp_inst_buffer[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*i:`INST_INDEX_SIZE*i] <= inst_buffer[front];
                           front <= (front+1) % `IB_SIZE;
                           valid[j] <= 1'b1;
                       end

                   end
                   
               end
           endgenerate

           inst0 <= temp_inst_buffer[`INST_INDEX_SIZE-1:0];
           inst1 <= temp_inst_buffer[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE:`INST_INDEX_SIZE];
           inst2 <= temp_inst_buffer[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*2:`INST_INDEX_SIZE*2];
           inst3 <= temp_inst_buffer[`INST_INDEX_SIZE-1+`INST_INDEX_SIZE*3:`INST_INDEX_SIZE*3];

        end
        
    end

end
    
endmodule
