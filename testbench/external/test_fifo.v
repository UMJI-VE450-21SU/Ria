`timescale 1ns/100ps

`define CLOCK_PERIOD 10 
`define CLOCK_FREQ 100_000_000

module test_fifo;
    localparam WIDTH = 32;
    localparam LOGDEPTH = 3;
    localparam DEPTH = (1 << LOGDEPTH);

    reg clk = 0;
    reg rst = 0;

    always #(`CLOCK_PERIOD/2) clk <= ~clk;

    // Reg filled with test vectors for the testbench
    reg [WIDTH-1:0] test_values[50-1:0];
    // Reg used to collect the data read from the FIFO
    reg [WIDTH-1:0] received_values[50-1:0];

    // Enqueue signals (Write to FIFO)
    reg enq_valid;
    reg [WIDTH-1:0] enq_data;
    wire enq_ready;

    // Dequeue signals (Read from FIFO)
    wire deq_valid;
    wire [WIDTH-1:0] deq_data;
    reg deq_ready;

    fifo #(
        .WIDTH(WIDTH),
        .LOGDEPTH(LOGDEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .enq_valid(enq_valid), // input
        .enq_data(enq_data),   // input
        .enq_ready(enq_ready), // output

        .deq_valid(deq_valid), // output
        .deq_data(deq_data),   // output
        .deq_ready(deq_ready)  // input
    );

    ////////////////////////////////////////////////////////////////////////////////
    // add print values here
    // if you want to see the value inside your fifo,
    // use "dut.xxx"
    // e.g. print the value of wire "full" in your fifo, use "dut.full"
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        $display("At time %d, enq_valid=%d, enq_ready=%d, enq_data=%d, deq_valid=%d, deq_ready=%d, deq_data=%d, WRITE=%d, READ=%d",
            $time,
            enq_valid, enq_ready, enq_data,
            deq_valid, deq_ready, deq_data,
            (enq_valid && enq_ready ? enq_data : 32'dX),
            (deq_valid && deq_ready ? deq_data : 32'dX));
    end

    // This task will push some data to the FIFO through the write interface
    // If violate_interface == 1'b1, we will force 'enq_valid' high even if the FIFO indicates it is full
    // If violate_interface == 1'b0, we won't write if the FIFO indicates it is full
    wire full  = !enq_ready;
    wire empty = !deq_valid;
    task write_to_fifo;
        input [WIDTH-1:0] write_data;
        input violate_interface;
        begin
            // If we want to not violate the interface agreement, if we are already full, don't write
            if (!violate_interface && full) begin
                enq_valid <= 1'b0;
            end
            // In all other cases, we will force a write
            else begin
                enq_valid <= 1'b1;
            end

            // Write should be performed when enq_ready and enq_valid are HIGH
            enq_data <= write_data;

            // Wait for the clock edge to perform the write
            @(posedge clk); #1;

            // Deassert write
            enq_valid <= 1'b0;
        end
    endtask

    // This task will read some data from the FIFO through the read interface
    // violate_interface does the same as for the write_to_fifo task
    task read_from_fifo;
        input violate_interface;
        output [WIDTH-1:0] read_data;
        begin
            if (!violate_interface && empty) begin
                deq_ready <= 1'b0;
            end
            else begin
                deq_ready <= 1'b1;
            end
            // Read data should be available when deq_ready and deq_valid are HIGH
            read_data <= deq_data;

            // Deassert read
            @(posedge clk); #1;
            deq_ready <= 1'b0;
        end
    endtask

    reg [31:0] write_idx = 0;
    reg write_start = 0;

    always @(posedge clk) begin
        if (write_start && enq_valid && enq_ready) begin
            write_idx <= write_idx + 1;
        end
    end

    // This task will attempt to write 'num_items' from the 'test_values' to the FIFO
    task writes_to_fifo;
        input [31:0] num_items;
        input [31:0] delay;
        begin
            write_idx = 0;
            write_start = 1;

            while (write_idx < num_items) begin
                @(posedge clk); #1;

                enq_valid <= 1'b1;
                enq_data <= test_values[write_idx];

                repeat (delay) begin
                    @(posedge clk); #1;
                    enq_valid <= 1'b0;
                end
            end

            write_start = 0;
            enq_valid <= 1'b0;
        end
    endtask

    reg [31:0] read_idx = 0;
    reg read_start = 0;

    always @(posedge clk) begin
        if (read_start && deq_valid && deq_ready) begin
            read_idx <= read_idx + 1;
            received_values[read_idx] <= deq_data;
        end
    end

    // This task will attempt to read 'num_items' from the FIFO to the 'received_values'
    task reads_from_fifo;
        input [31:0] num_items;
        input [31:0] delay;
        begin
            read_idx = 0;
            read_start = 1;
            while (read_idx < num_items) begin
                @(posedge clk); #1;

                deq_ready <= 1'b1;
                repeat (delay) begin
                    @(posedge clk); #1;
                    deq_ready <= 1'b0;
                end
            end

            read_start = 0;
            deq_ready <= 1'b0;
        end
    endtask

    integer i, j;
    integer num_mismatches;
    integer num_items = 50;
    integer write_delay, read_delay;
    initial begin: TB
        $display("This testbench was run with these params:");
        $display("CLOCK_PERIOD = %d, DATA_WIDTH = %d, FIFO_DEPTH = %d", `CLOCK_PERIOD, WIDTH, DEPTH);

        // Generate data to write to the FIFO
        for (i = 0; i < 50; i = i + 1) begin
            test_values[i] <= i + 1000;
        end

        enq_valid = 0;
        enq_data  = 0;
        deq_ready = 0;

        rst = 1'b1;
        @(posedge clk); #1;
        rst = 1'b0;
        @(posedge clk); #1;

        // ==================== Basic tests ===================================
        // Let's begin with a simple complete write and read sequence to the FIFO

        // Check initial conditions, verify that the FIFO is not full, it is empty
        if (empty !== 1'b1) begin
            $display("Failure: After reset, the FIFO isn't empty. empty = %b", empty);
            $finish();
        end

        if (full !== 1'b0) begin
            $display("Failure: After reset, the FIFO is full. full = %b", full);
            $finish();
        end

        @(posedge clk);

        // Begin pushing data into the FIFO with a 1 cycle delay in between each write operation
        for (i = 0; i < DEPTH - 1; i = i + 1) begin
            write_to_fifo(test_values[i], 1'b0);

            // Perform checks on empty, full 
            if (empty === 1'b1) begin
                $display("Failure: While being filled, FIFO said it was empty");
                $finish();
            end
            if (full === 1'b1) begin
                $display("Failure: While being filled, FIFO was full before all entries were written");
                $finish();
            end

            // Insert single-cycle delay between each write
            @(posedge clk);
        end

        // Perform the final write
        write_to_fifo(test_values[DEPTH-1], 1'b0);

        // Check that the FIFO is now full
        if (full !== 1'b1 || empty === 1'b1) begin
            $display("Failure: FIFO wasn't full or empty went high after writing all values. full = %b, empty = %b", full, empty);
            $finish();
        end

        // Cycle the clock, the FIFO should still be full!
        repeat (10) @(posedge clk);
        // The FIFO should still be full!
        if (full !== 1'b1 || empty == 1'b1) begin
            $display("Failure: Cycling the clock while the FIFO is full shouldn't change its state! full = %b, empty = %b", full, empty);
            $finish();
        end

        // Try stuffing the FIFO with more data while it's full (overflow protection check)
        repeat (20) begin
            write_to_fifo(0, 1'b1);
            // Check that the FIFO is still full, has the max num of entries, and isn't empty
            if (full !== 1'b1 || empty == 1'b1) begin
                $display("Failure: Overflowing the FIFO changed its state (your FIFO should have overflow protection) full = %b, empty = %b", full, empty);
                $finish();
            end
        end

        repeat (5) @(posedge clk);

        // Read from the FIFO one by one with a 1 cycle delay in between reads
        for (i = 0; i < DEPTH - 1; i = i + 1) begin
            read_from_fifo(1'b0, received_values[i]);

            // Perform checks on empty, full
            if (empty === 1'b1) begin
                $display("Failure: FIFO was empty as its being drained");
                $finish();
            end
            if (full === 1'b1) begin
                $display("Failure: FIFO was full as its being drained");
                $finish();
            end

            @(posedge clk);
        end

        // Perform the final read
        read_from_fifo(1'b0, received_values[DEPTH-1]);
        // Check that the FIFO is now empty
        if (full !== 1'b0 || empty !== 1'b1) begin
            $display("Failure: FIFO wasn't empty or full is high after the FIFO has been drained. full = %b, empty = %b", full, empty);
            $finish();
        end

        // Cycle the clock and perform the same checks
        repeat (10) @(posedge clk);
        if (full !== 1'b0 || empty !== 1'b1) begin
            $display("Failure: FIFO should be empty after it has been drained. full = %b, empty = %b", full, empty);
            $finish();
        end

        // Finally, let's check that the data we received from the FIFO equals the data that we wrote to it
        num_mismatches = 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (test_values[i] !== received_values[i]) begin
                $display("Failure: Data received from FIFO not equal to data written. Entry %d, got %d, expected %d", i, received_values[i], test_values[i]);
                num_mismatches = num_mismatches + 1;
            end
        end
        if (num_mismatches > 0)
            $finish();

        // Now attempt a read underflow
        repeat (10) read_from_fifo(1'b1, received_values[0]);
        // Nothing should change, perform the same checks on full and empty
        if (full !== 1'b0 || empty !== 1'b1) begin
            $display("Failure: Empty FIFO wasn't empty or full went high when trying to read. full = %b, empty = %b", full, empty);
            $finish();
        end

        #100;
        $display("All the basic tests passed!");

        // ==================== Harder tests ==================================
        // Begin pushing data into the FIFO in successive cycles
        for (i = 0; i < DEPTH; i = i + 1) begin
            write_to_fifo(test_values[i], 1'b0);
        end

        // Add some delay
        repeat (5) @(posedge clk);

        // Read from the FIFO in successive cycles
        for (i = 0; i < DEPTH; i = i + 1) begin
            read_from_fifo(1'b0, received_values[i]);
        end

        num_mismatches = 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (test_values[i] !== received_values[i]) begin
                $display("Failure: Data received from FIFO not equal to data written. Entry %d, got %d, expected %d", i, received_values[i], test_values[i]);
                num_mismatches = num_mismatches + 1;
            end
        end
        if (num_mismatches > 0)
            $finish();

        #100;

        // Write and Read from FIFO for some number of items concurrently
        // Test with different combinations of the following variables
        num_items   = 50; // number of items to be sent and received
        write_delay = 0; // number of cycles to the next write
        read_delay  = 0; // number of cycles to the next read
        fork
            begin
                writes_to_fifo(num_items, write_delay);

            end
            begin
                reads_from_fifo(num_items, read_delay);
            end
        join

        repeat (3) @(posedge clk);

        num_mismatches = 0;
        for (i = 0; i < num_items; i = i + 1) begin
            if (test_values[i] !== received_values[i]) begin
                $display("Failure: Data received from FIFO not equal to data written. Entry %d, got %d, expected %d", i, received_values[i], test_values[i]);
                num_mismatches = num_mismatches + 1;
            end
        end
        if (num_mismatches > 0)
            $finish();

        $display("All the hard tests passed!");

        $finish();
    end
endmodule
