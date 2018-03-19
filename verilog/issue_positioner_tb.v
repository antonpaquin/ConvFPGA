`timescale 1ns / 1ns

`include "issue_positioner.v"

module main();

    reg clk, rst, advance;
    
    wire [7:0] center_x, center_y;
    wire [219:0] allocator_select;

    IssuePositioner uut(
        .image_dim(8'd230),
        .padding(2'd1),
        .stride(3'd1),
    
        .center_x(center_x),
        .center_y(center_y),
        .allocator_select(allocator_select),
        
        .advance(advance),

        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #10 rst = 0;
    end

    initial begin
        advance = 1;
        #20 advance = 0;
        #2980 advance = 1;
        #20 advance = 0;
    end

    initial begin
        $dumpfile("issue_positioner.vcd");
        $dumpvars(0, uut);
        #6000 $finish;
    end

    integer ii;
    always @(posedge clk) begin
        for (ii=0; ii<220; ii=ii+1) begin
            if (allocator_select[ii]) begin
                $display("%t a%d <-- (%d, %d)", $time, ii, center_x, center_y);
            end
        end
    end


endmodule
