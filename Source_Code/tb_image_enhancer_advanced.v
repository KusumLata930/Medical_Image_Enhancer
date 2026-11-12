// Testbench for Medical Image Enhancer with Histogram Equalization / Thresholding
// Reads  : output_filtered.txt (median-filtered image)
// Writes : output_histeq.txt      (mode 01: histogram equalization)
//          output_threshold.txt   (mode 00: binary threshold)
//          output_thr_histeq.txt  (mode 10: threshold + histogram equalization)

`timescale 1ns/1ps

module tb_image_enhancer_advanced;

    // Parameters (must match the size of the input file)
    parameter WIDTH = 256;
    parameter HEIGHT = 256;
    parameter PIXEL_BITS = 8;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLK_PERIOD = 10;

    // Signals
    reg clk;
    reg rst;
    reg start;
    reg [1:0] mode;
    reg [PIXEL_BITS-1:0] threshold_value;
    wire done;
    wire [PIXEL_BITS-1:0] enhanced_pixel;
    wire enhanced_valid;
    wire [16:0] pixel_addr;

    // Internal DUT signals made visible at top level for the waveform window
    wire [3:0]  dut_state   = dut.state;
    wire [16:0] dut_counter = dut.pixel_counter;
    wire [31:0] dut_cdf_min = dut.cdf_min;

    // Instantiate the design under test
    image_enhancer_advanced #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITS(PIXEL_BITS),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .threshold_value(threshold_value),
        .done(done),
        .enhanced_pixel(enhanced_pixel),
        .enhanced_valid(enhanced_valid),
        .pixel_addr(pixel_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test sequence
    initial begin
        rst             = 1;
        start           = 0;
        mode            = 2'b01;
        threshold_value = 8'h30;

        $dumpfile("image_enhancer_advanced.vcd");
        $dumpvars(1, tb_image_enhancer_advanced);

        $display("===========================================");
        $display("Medical Image Enhancement - Histogram Equalization");
        $display("===========================================");
        $display("Loading input image...");
        dut.load_image("output_filtered.txt");

        // Reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD * 2);

        // ===== Run 1: Histogram Equalization (mode 01) =====
        $display("\n--- Run 1: Histogram Equalization (mode 01) ---");
        mode  = 2'b01;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #(CLK_PERIOD * 10);
        dut.save_image("output_histeq.txt");

        $display("\n=== Histogram Statistics ===");
        display_histogram_stats;

        // ===== Run 2: Binary threshold (mode 00) =====
        $display("\n--- Run 2: Threshold only (mode 00, threshold = %0d) ---", threshold_value);
        #(CLK_PERIOD * 5);
        mode  = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(!done);          // done is cleared when the new run starts
        wait(done);
        #(CLK_PERIOD * 10);
        dut.save_image("output_threshold.txt");

        // ===== Run 3: Threshold + histogram equalization (mode 10) =====
        $display("\n--- Run 3: Threshold + Histogram Equalization (mode 10) ---");
        #(CLK_PERIOD * 5);
        mode  = 2'b10;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(!done);
        wait(done);
        #(CLK_PERIOD * 10);
        dut.save_image("output_thr_histeq.txt");

        #(CLK_PERIOD * 10);
        $display("\n===========================================");
        $display("All enhancement runs completed successfully!");
        $display("===========================================");
        $display("Output files generated:");
        $display("  - output_histeq.txt");
        $display("  - output_threshold.txt");
        $display("  - output_thr_histeq.txt");
        $finish;
    end

    // Task to display histogram statistics (valid after a mode-01 run)
    task display_histogram_stats;
        integer n, nonzero_bins;
        reg [16:0] max_count;
        reg [7:0] max_bin;
        begin
            nonzero_bins = 0;
            max_count = 0;
            max_bin = 0;

            for (n = 0; n < 256; n = n + 1) begin
                if (dut.histogram[n] > 0) begin
                    nonzero_bins = nonzero_bins + 1;
                    if (dut.histogram[n] > max_count) begin
                        max_count = dut.histogram[n];
                        max_bin = n;
                    end
                end
            end

            $display("Non-zero bins     : %0d / 256", nonzero_bins);
            $display("Most frequent value: 0x%h (count: %0d)", max_bin, max_count);
            $display("CDF min           : %0d", dut.cdf_min);
            $display("Total pixels      : %0d", TOTAL_PIXELS);
        end
    endtask

    // Monitor progress
    always @(posedge clk) begin
        if (enhanced_valid && (pixel_addr % 10000 == 0))
            $display("Progress: %0d/%0d pixels streamed out", pixel_addr, TOTAL_PIXELS);
    end

    // Timeout watchdog (three full runs)
    initial begin
        #(CLK_PERIOD * TOTAL_PIXELS * 40);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
