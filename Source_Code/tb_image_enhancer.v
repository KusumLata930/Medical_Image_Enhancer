// Testbench for Medical Image Enhancer (contrast stretching)
// Reads  : output_filtered.txt (the median-filtered image from tb_salt_pepper_removal)
// Writes : output_contrast.txt

`timescale 1ns/1ps

module tb_image_enhancer;

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
    wire done;
    wire [PIXEL_BITS-1:0] enhanced_pixel;
    wire enhanced_valid;
    wire [16:0] pixel_addr;

    // Internal DUT signals made visible at top level for the waveform window
    wire [2:0]  dut_state   = dut.state;
    wire [16:0] dut_counter = dut.pixel_counter;
    wire [7:0]  dut_min_val = dut.min_val;
    wire [7:0]  dut_max_val = dut.max_val;

    // Instantiate the design under test
    image_enhancer #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITS(PIXEL_BITS),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
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
        rst   = 1;
        start = 0;

        $dumpfile("image_enhancer.vcd");
        $dumpvars(1, tb_image_enhancer);

        $display("===========================================");
        $display("Medical Image Enhancer - Contrast Stretching");
        $display("===========================================");
        $display("Loading input image...");
        dut.load_image("output_filtered.txt");

        // Reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD * 2);

        // Start processing
        $display("Starting image enhancement...");
        start = 1;
        #CLK_PERIOD;
        start = 0;

        // Wait for processing to complete
        wait(done);
        $display("Image enhancement completed!");

        // Save enhanced image
        #(CLK_PERIOD * 10);
        dut.save_image("output_contrast.txt");

        $display("\n=== Enhancement Statistics ===");
        $display("Total pixels processed: %0d", TOTAL_PIXELS);
        $display("Input min value       : %0d (0x%h)", dut.min_val, dut.min_val);
        $display("Input max value       : %0d (0x%h)", dut.max_val, dut.max_val);
        $display("================================\n");

        #(CLK_PERIOD * 10);
        $display("Testbench completed successfully");
        $finish;
    end

    // Monitor enhanced pixel output
    always @(posedge clk) begin
        if (enhanced_valid && (pixel_addr % 10000 == 0))
            $display("Progress: %0d/%0d pixels streamed out", pixel_addr, TOTAL_PIXELS);
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * TOTAL_PIXELS * 10);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
