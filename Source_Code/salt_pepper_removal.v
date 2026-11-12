`timescale 1ns/1ps

// Salt and Pepper Noise Removal using 3x3 Median Filter
// Image Size: WIDTH x HEIGHT grayscale (8-bit pixels), default 256x256
// Border pixels are handled by replicating the nearest edge pixel.

module salt_pepper_removal #(
    parameter WIDTH = 256,
    parameter HEIGHT = 256,
    parameter PIXEL_BITS = 8,
    parameter TOTAL_PIXELS = WIDTH * HEIGHT
)(
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,
    output reg [PIXEL_BITS-1:0] filtered_pixel,
    output reg filtered_valid,
    output reg [16:0] pixel_addr
);

    // Memory for input and output images
    reg [PIXEL_BITS-1:0] input_image [0:TOTAL_PIXELS-1];
    reg [PIXEL_BITS-1:0] output_image [0:TOTAL_PIXELS-1];

    // State machine
    localparam IDLE   = 2'd0;
    localparam FILTER = 2'd1;
    localparam OUTPUT = 2'd2;
    localparam DONE   = 2'd3;

    reg [1:0]  state;
    reg [16:0] pixel_counter;

    // Helper variables (driven only with blocking assignments)
    integer row, col;

    // 3x3 window for median filter
    reg [PIXEL_BITS-1:0] window [0:8];
    reg [PIXEL_BITS-1:0] sorted [0:8];
    integer i, j;
    reg [PIXEL_BITS-1:0] temp;
    reg [PIXEL_BITS-1:0] median;

    // ------------------------------------------------------------------
    // Task to load image from a text file (one hex pixel per line)
    // ------------------------------------------------------------------
    task load_image;
        input [8*100:1] filename;
        integer file, k, scan_result;
        reg [PIXEL_BITS-1:0] pixel_data;
        begin
            file = $fopen(filename, "r");
            if (file == 0) begin
                $display("Error: Cannot open file %0s", filename);
                $finish;
            end else begin
                for (k = 0; k < TOTAL_PIXELS; k = k + 1) begin
                    scan_result = $fscanf(file, "%h", pixel_data);
                    if (scan_result != 1) begin
                        $display("Error reading pixel %0d", k);
                        input_image[k] = 8'h00;
                    end else begin
                        input_image[k] = pixel_data;
                    end
                end
                $fclose(file);
                $display("Image loaded successfully: %0d pixels", TOTAL_PIXELS);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Task to save filtered image
    // ------------------------------------------------------------------
    task save_image;
        input [8*100:1] filename;
        integer file, k;
        begin
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("Error: Cannot create file %0s", filename);
            end else begin
                for (k = 0; k < TOTAL_PIXELS; k = k + 1) begin
                    $fwrite(file, "%h\n", output_image[k]);
                end
                $fclose(file);
                $display("Filtered image saved to %0s", filename);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Pixel fetch with border replication.
    // Arguments are 32-bit; row-1 at row 0 wraps to 0xFFFFFFFF, which is
    // -1 when copied into the signed integer below.
    // ------------------------------------------------------------------
    function [PIXEL_BITS-1:0] get_pixel;
        input [31:0] r;
        input [31:0] c;
        integer rr, cc;
        begin
            rr = r;
            cc = c;
            if (rr < 0)        rr = 0;
            if (rr >= HEIGHT)  rr = HEIGHT - 1;
            if (cc < 0)        cc = 0;
            if (cc >= WIDTH)   cc = WIDTH - 1;
            get_pixel = input_image[rr * WIDTH + cc];
        end
    endfunction

    // Task to extract 3x3 window
    task extract_window;
        input [31:0] center_row;
        input [31:0] center_col;
        begin
            window[0] = get_pixel(center_row - 1, center_col - 1);  // Top-left
            window[1] = get_pixel(center_row - 1, center_col);      // Top-center
            window[2] = get_pixel(center_row - 1, center_col + 1);  // Top-right
            window[3] = get_pixel(center_row,     center_col - 1);  // Middle-left
            window[4] = get_pixel(center_row,     center_col);      // Center
            window[5] = get_pixel(center_row,     center_col + 1);  // Middle-right
            window[6] = get_pixel(center_row + 1, center_col - 1);  // Bottom-left
            window[7] = get_pixel(center_row + 1, center_col);      // Bottom-center
            window[8] = get_pixel(center_row + 1, center_col + 1);  // Bottom-right
        end
    endtask

    // Task to sort 9 values and find the median (bubble sort)
    task find_median;
        output [PIXEL_BITS-1:0] median_value;
        begin
            for (i = 0; i < 9; i = i + 1)
                sorted[i] = window[i];

            for (i = 0; i < 9; i = i + 1) begin
                for (j = 0; j < 8 - i; j = j + 1) begin
                    if (sorted[j] > sorted[j + 1]) begin
                        temp         = sorted[j];
                        sorted[j]    = sorted[j + 1];
                        sorted[j + 1] = temp;
                    end
                end
            end

            // Median is the 5th element (index 4) of the sorted window
            median_value = sorted[4];
        end
    endtask

    // ------------------------------------------------------------------
    // Main processing logic: one output pixel per clock in FILTER state
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            done           <= 1'b0;
            pixel_counter  <= 17'd0;
            filtered_valid <= 1'b0;
            filtered_pixel <= {PIXEL_BITS{1'b0}};
            pixel_addr     <= 17'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state         <= FILTER;
                        pixel_counter <= 17'd0;
                        done          <= 1'b0;
                        $display("[%0d ns] Starting salt & pepper noise removal...", $time);
                    end
                end

                FILTER: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        row = pixel_counter / WIDTH;
                        col = pixel_counter % WIDTH;

                        extract_window(row, col);
                        find_median(median);

                        output_image[pixel_counter] <= median;
                        pixel_counter <= pixel_counter + 1'b1;
                    end else begin
                        $display("[%0d ns] Filtering completed", $time);
                        state         <= OUTPUT;
                        pixel_counter <= 17'd0;
                    end
                end

                OUTPUT: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        filtered_pixel <= output_image[pixel_counter];
                        pixel_addr     <= pixel_counter;
                        filtered_valid <= 1'b1;
                        pixel_counter  <= pixel_counter + 1'b1;
                    end else begin
                        filtered_valid <= 1'b0;
                        state          <= DONE;
                    end
                end

                DONE: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
