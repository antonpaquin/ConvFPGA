`timescale 1ns / 1ns

`define memory_init_dec

`include "accel.v"

module main();
    reg clk;
    reg rst;

    wire done;

    Accel uut (
        .image_dim(8'd5),
        .image_depth(9'd3),

        .image_memory_offset(16'd0),
        .filter_memory_offset(16'd1000),

        .filter_halfsize(2'd1),
        .filter_stride(3'd1),
        .filter_length(13'd27),
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
            $finish;
        end
    end
endmodule
