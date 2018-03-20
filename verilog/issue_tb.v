`timescale 1ns / 1ns

`include "issue.v"

//`define go_fast

module main();

    localparam num_allocators  = 2;

    reg [7:0]  image_width     = 8'd26;
    reg [8:0]  image_depth     = 9'd3;

    reg [1:0]  filter_halfsize = 2'd2;
    reg [2:0]  filter_stride   = 3'd4;

    reg clk, rst;

    wire [7:0] issue_x, 
               issue_y;

    wire issue_en;

    wire [7:0] positioner_x,
               positioner_y;

    wire [num_allocators-1:0] positioner_select;


    Issue #(
        .num_allocators(num_allocators)
    ) uut (
        //.imem_write_addr_a(),
        //.imem_write_data_a(),
        .imem_write_en_a(1'b0),

        .image_dim(image_width),
        .image_depth(image_depth),

        .filter_halfsize(filter_halfsize),
        .filter_stride(filter_stride),

        .issue_x(issue_x),
        .issue_y(issue_y),
        //.issue_data(),
        .issue_en(issue_en),

        .issue_block({num_allocators{1'b0}}),

        .positioner_x(positioner_x),
        .positioner_y(positioner_y),
        .positioner_select(positioner_select),

        //.done(),

        .clk(clk),
        .rst(rst)
    );

    initial begin
        rst = 1;
        #10 rst = 0;
    end

    initial begin
        clk = 1;
        forever #1 clk = ~clk;
    end

    reg [7:0] display [44:0][44:0];
    reg [1:0] display_rows_faster [44:0];
    reg [7:0] display_position [44:0][44:0];

    integer ii, jj, xx, yy;
    initial begin
        for (ii=0; ii<45; ii=ii+1) begin
            display_rows_faster[ii] = 2;
            for (jj=0; jj<45; jj=jj+1) begin
                display[ii][jj] = 32;
                display_position[ii][jj] = 32;
            end
        end
    end

    initial begin
        $dumpfile("issue.vcd");
        $dumpvars(0, uut);
    end
    
    always @(posedge clk) begin
        if (positioner_select) begin
            for (yy=positioner_y-filter_halfsize; yy<=positioner_y+filter_halfsize; yy=yy+1) begin
                display_rows_faster[yy] = 2;
                for (xx=positioner_x-filter_halfsize; xx<=positioner_x+filter_halfsize; xx=xx+1) begin
                    display_position[yy][xx] <= 35;
                end
            end
        end

        if (issue_en) begin
            display_rows_faster[issue_y] = 2;
            if (display[issue_y][issue_x] == 35 || display[issue_y][issue_x] == 32) begin
                display[issue_y][issue_x] <= 48;
            end else if (display[issue_y][issue_x] == 57) begin
                display[issue_y][issue_x] <= 65;
            end else begin
                display[issue_y][issue_x] <= display[issue_y][issue_x] + 1;
            end
        end
    end

    initial begin
        $write("\033[2J");
    end

    always @(posedge clk) begin
        $write("\033[H");
        for (ii=0; ii<45; ii=ii+1) begin
            if (display_rows_faster[ii]) begin
                for (jj=0; jj<45; jj=jj+1) begin
                    $write("%c%c", display_position[ii][jj], display[ii][jj]);
                end
                `ifdef go_fast
                display_rows_faster[ii] = display_rows_faster[ii] - 1;
                `endif // go_fast
            end
            $write("\n");
        end
        if (positioner_select) begin
            for (ii=0; ii<num_allocators; ii=ii+1) begin
                if (positioner_select[ii]) begin
                    $display("(%d, %d) --> %d", positioner_x, positioner_y, ii);
                end
            end
        end
        //$stop;
    end
endmodule
