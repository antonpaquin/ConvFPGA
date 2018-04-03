`timescale 1ns / 1ns

`define memory_init_dec

`include "issue_filter.v"
`include "memory.v"

module main();
    reg clk;
    reg rst;

    reg block;

    wire [17:0] mem_data;
    wire [15:0] mem_addr;

    wire done;

    IssueFilter #(
        .num_allocators(1)
    ) uut (
        //.filter_issue_counter(),
        //.filter_data(),
        //.filter_blocked(),
        .filter_block(block),

        .filter_length(13'd255),

        .filter_read_addr(mem_addr),
        .filter_read_data(mem_data),

        .done(done),

        .clk(clk),
        .rst(rst)
    );

    Memory memory (
        .read_addr_a(mem_addr),
        .read_data_a(mem_data),

        //.read_addr_b(),
        //.read_data_b(),

        //.write_addr_a(),
        //.write_data_a(),
        //.write_en_a(),

        //.write_addr_b(),
        //.write_data_b(),
        //.write_en_b(),

        .clk(clk)
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
        block = 0;
        #161 block = 1;
        #50 block = 0;
    end

    initial begin
        $dumpfile("issue_filter.vcd");
        $dumpvars(0, uut);
    end
    
    always @(posedge clk) begin
        if (!rst && done) begin
            $finish;
        end
    end

endmodule
