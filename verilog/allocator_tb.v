`timescale 1ns / 1ns

`include "allocator.v"

module main();
    reg [ 7:0] issue_x, issue_y, issue_z;
    reg [17:0] issue_data;

    reg [12:0] filter_issue_counter;
    reg [17:0] filter_data;

    reg [ 7:0] center_x, center_y;

    reg [ 2:0] filter_dim;

    reg clk, rst;

    Allocator uut(
        .issue_a_x(issue_x),
        .issue_a_y(issue_y),
        .issue_a_data(issue_data),
        .issue_a_blocked(1'b0),

        .filter_issue_counter(filter_issue_counter),
        .filter_data(filter_data),
        .filter_blocked(1'b0),

        .center_x(center_x),
        .center_y(center_y),

        .filter_dim(filter_dim),

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
        center_x = 1;
        center_y = 1;
        filter_dim = 3;
    end

    initial begin
        filter_data = 0;
        filter_issue_counter = 0;
        #10;
        forever begin
            #10;
            filter_data = filter_data + 1;
            filter_issue_counter = filter_issue_counter + 1;
        end
    end

    initial begin
        issue_data = 0;
        issue_x = 0;
        issue_y = 0;
        issue_z = 0;
    end

    always @(posedge clk) begin
        if (issue_x == 255 && issue_y == 255) begin
            issue_x <= 0;
            issue_y <= 0;
            issue_z <= issue_z + 1;
        end else if (issue_x == 255) begin
            issue_x <= 0;
            issue_y <= issue_y + 1;
        end else begin
            issue_x <= issue_x + 1;
        end
        issue_data <= issue_data + 10;
    end
    
    initial begin
        $dumpfile("allocator.vcd");
        $dumpvars(0, uut);
        #10000 $finish;
    end

endmodule

    
    
