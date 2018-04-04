`timescale 1ns / 1ns

`define memory_init_dec

`include "accel.v"

/* Accel test bench
 *
 * Testbenches are starting to get simple. This mainly hooks up "accel" with
 * what it should be reading from the CPU, and lets it go
 */
   

module main();
    reg clk;
    reg rst;

    wire done;

    Accel uut (
        .image_dim(8'd5), // (x,y) = 5x5
        .image_depth(9'd3), // z = 3
        
        // Image memory is stored at index 0
        .image_memory_offset(16'd0),
        // Filter memory is stored at index 1000
        .filter_memory_offset(16'd1000),
        // This is completely arbitrary
        
        .filter_halfsize(2'd1), // 3x3 filter
        .filter_stride(3'd1), // Stride of 1

        // 3x3x3 filter has length 27
        // NOTE! This is denormalized -- we could compute this somewhere, but
        // in order to avoid generating a big multiplier we'll just require
        // that the CPU compute it for us.
        // This value should be image_depth * ((2*filter_halfsize + 1)^2)
        .filter_length(13'd27), 

        // Bias to add to the filter values at the end
        // This currently isn't hooked up anywhere (bad?)
        .filter_bias(18'd100),
        
        .done(done),

        .clk(clk),
        .rst(rst)
    );

    initial begin
        rst = 1;
        #10 rst = 0;
    end

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("accel.vcd");
        $dumpvars(0, uut);
    end

    always @(posedge clk) begin
        if (done) begin
            // Sleep 100 to allow the last value to propagate out, because
            // "done" is raised prematurely (see comment in "accel.v")
            #100 $finish;
        end
    end
endmodule
