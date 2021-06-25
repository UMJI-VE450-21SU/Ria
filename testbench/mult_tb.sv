module mult_tb();
    logic           clock;
    logic           reset;
    micro_op_t      uop;
    logic   [31:0]  in1;
    logic   [31:0]  in2;
    logic   [31:0]  out; // have a delay of 5 cycles

    mult mult_0 (
    .clock,
    .reset,
    .uop,
    .in1,
    .in2,
    .out
    );

    always begin
        #5;
        clock = ~clock;
    end
    
    initial begin
        clock = 0;
        reset = 1;
        uop = 0;
        uop.valid = 1;
        @(negedge clock);
        uop.mult_type = MULT;
        in1 = 32'd10;
        in2 = 32'd11;
        @(negedge clock);
        uop.mult_type = MULH;
        in1 = 32'd100;
        in2 = 32'd111;
        @(negedge clock);
        uop.mult_type = MULHSU;
        in1 = 32'd1000;
        in2 = 32'd1111;
        @(negedge clock);
        uop.mult_type = MULHU;
        in1 = 32'd10000;
        in2 = 32'd11111;
        @(negedge clock);


        $finish;
    end

    
endmodule
