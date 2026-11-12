`timescale 1ns/1ps

// Medical Image Enhancer with Thresholding and Histogram Equalization
// Image Size: WIDTH x HEIGHT grayscale (8-bit pixels), default 256x256
//
// mode = 2'b00 : binary threshold only
// mode = 2'b01 : histogram equalization only
// mode = 2'b10 : threshold, then histogram equalization of the result
//                (2'b11 behaves like 2'b10)

module image_enhancer_advanced #(
    parameter WIDTH = 256,
    parameter HEIGHT = 256,
    parameter PIXEL_BITS = 8,
    parameter TOTAL_PIXELS = WIDTH * HEIGHT
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [1:0] mode,
    input wire [PIXEL_BITS-1:0] threshold_value,
    output reg done,
    output reg [PIXEL_BITS-1:0] enhanced_pixel,
    output reg enhanced_valid,
    output reg [16:0] pixel_addr
);

    // Memory for input and output images
    reg [PIXEL_BITS-1:0] input_image  [0:TOTAL_PIXELS-1];
    reg [PIXEL_BITS-1:0] output_image [0:TOTAL_PIXELS-1];
    reg [PIXEL_BITS-1:0] temp_image   [0:TOTAL_PIXELS-1];

    // Histogram (256 bins) and cumulative distribution function
    reg [16:0] histogram [0:255];   // 17 bits: holds counts up to 65536
    reg [31:0] cdf       [0:255];
    reg [31:0] cdf_min;

    // State machine
    localparam IDLE       = 4'd0;
    localparam THRESHOLD  = 4'd1;
    localparam BUILD_HIST = 4'd2;
    localparam BUILD_CDF  = 4'd3;
    localparam HIST_EQ    = 4'd4;
    localparam OUTPUT     = 4'd5;
    localparam DONE       = 4'd6;

    reg [3:0]  state;
    reg [16:0] pixel_counter;
    reg [8:0]  bin_counter;

    // Working registers (blocking assignments only)
    reg [PIXEL_BITS-1:0] current_pixel;
    reg [31:0] numerator;
    reg [31:0] equalized_value;
    reg [31:0] min_tmp;
    reg        found_min;
    integer    k;

    // Histogram equalization is applied to the thresholded image in modes 10/11
    wire use_temp = mode[1];

    // ------------------------------------------------------------------
    task load_image;
        input [8*100:1] filename;
        integer file, i, scan_result;
        reg [PIXEL_BITS-1:0] pixel_data;
        begin
            file = $fopen(filename, "r");
            if (file == 0) begin
                $display("Error: Cannot open file %0s", filename);
                $finish;
            end else begin
                for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
                    scan_result = $fscanf(file, "%h", pixel_data);
                    if (scan_result != 1) begin
                        $display("Error reading pixel %0d", i);
                        input_image[i] = 8'h00;
                    end else begin
                        input_image[i] = pixel_data;
                    end
                end
                $fclose(file);
                $display("Image loaded successfully: %0d pixels", TOTAL_PIXELS);
            end
        end
    endtask

    task save_image;
        input [8*100:1] filename;
        integer file, i;
        begin
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("Error: Cannot create file %0s", filename);
            end else begin
                for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
                    $fwrite(file, "%h\n", output_image[i]);
                end
                $fclose(file);
                $display("Enhanced image saved to %0s", filename);
            end
        end
    endtask

    task init_histogram;
        integer h;
        begin
            for (h = 0; h < 256; h = h + 1) begin
                histogram[h] = 17'd0;
                cdf[h]       = 32'd0;
            end
            cdf_min = 32'd0;
        end
    endtask

    task init_output;
        integer m;
        begin
            for (m = 0; m < TOTAL_PIXELS; m = m + 1) begin
                output_image[m] = 8'h00;
                temp_image[m]   = 8'h00;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Main processing logic
    // ------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            done           <= 1'b0;
            pixel_counter  <= 17'd0;
            bin_counter    <= 9'd0;
            enhanced_pixel <= {PIXEL_BITS{1'b0}};
            enhanced_valid <= 1'b0;
            pixel_addr     <= 17'd0;
            init_histogram;
            init_output;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        pixel_counter <= 17'd0;
                        bin_counter   <= 9'd0;
                        done          <= 1'b0;
                        init_histogram;
                        init_output;

                        if (mode == 2'b01)
                            state <= BUILD_HIST;   // histogram equalization only
                        else
                            state <= THRESHOLD;    // threshold first

                        $display("[%0d ns] Starting enhancement - Mode: %b, Threshold: %0d",
                                 $time, mode, threshold_value);
                    end
                end

                THRESHOLD: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        current_pixel = input_image[pixel_counter];

                        if (current_pixel >= threshold_value)
                            temp_image[pixel_counter] <= 8'hFF;   // White
                        else
                            temp_image[pixel_counter] <= 8'h00;   // Black

                        pixel_counter <= pixel_counter + 1'b1;
                    end else begin
                        $display("[%0d ns] Thresholding completed", $time);
                        pixel_counter <= 17'd0;

                        if (mode == 2'b00) begin
                            // Threshold only - result goes straight to output
                            for (k = 0; k < TOTAL_PIXELS; k = k + 1)
                                output_image[k] <= temp_image[k];
                            state <= OUTPUT;
                        end else begin
                            state <= BUILD_HIST;
                        end
                    end
                end

                BUILD_HIST: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        if (use_temp)
                            current_pixel = temp_image[pixel_counter];
                        else
                            current_pixel = input_image[pixel_counter];

                        histogram[current_pixel] <= histogram[current_pixel] + 1'b1;
                        pixel_counter <= pixel_counter + 1'b1;
                    end else begin
                        $display("[%0d ns] Histogram built", $time);
                        state       <= BUILD_CDF;
                        bin_counter <= 9'd0;
                        cdf[0]      <= histogram[0];
                    end
                end

                BUILD_CDF: begin
                    if (bin_counter < 255) begin
                        bin_counter <= bin_counter + 1'b1;
                        cdf[bin_counter + 1] <= cdf[bin_counter] + histogram[bin_counter + 1];
                    end else begin
                        // cdf is non-decreasing, so the first non-zero entry is the minimum
                        found_min = 1'b0;
                        min_tmp   = 32'd0;
                        for (k = 0; k < 256; k = k + 1) begin
                            if (!found_min && cdf[k] > 0) begin
                                min_tmp   = cdf[k];
                                found_min = 1'b1;
                            end
                        end
                        cdf_min <= min_tmp;

                        $display("[%0d ns] CDF computed, CDF_min = %0d", $time, min_tmp);
                        state         <= HIST_EQ;
                        pixel_counter <= 17'd0;
                    end
                end

                HIST_EQ: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        if (use_temp)
                            current_pixel = temp_image[pixel_counter];
                        else
                            current_pixel = input_image[pixel_counter];

                        // new = ((cdf[p] - cdf_min) * 255) / (TOTAL - cdf_min)
                        if (cdf_min > 0 && cdf_min < TOTAL_PIXELS) begin
                            numerator       = (cdf[current_pixel] - cdf_min) * 255;
                            equalized_value = numerator / (TOTAL_PIXELS - cdf_min);
                            output_image[pixel_counter] <= equalized_value[PIXEL_BITS-1:0];
                        end else begin
                            // Flat image: nothing to equalize
                            output_image[pixel_counter] <= current_pixel;
                        end

                        pixel_counter <= pixel_counter + 1'b1;
                    end else begin
                        $display("[%0d ns] Histogram equalization completed", $time);
                        state         <= OUTPUT;
                        pixel_counter <= 17'd0;
                    end
                end

                OUTPUT: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        enhanced_pixel <= output_image[pixel_counter];
                        pixel_addr     <= pixel_counter;
                        enhanced_valid <= 1'b1;
                        pixel_counter  <= pixel_counter + 1'b1;
                    end else begin
                        enhanced_valid <= 1'b0;
                        state          <= DONE;
                    end
                end

                DONE: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
