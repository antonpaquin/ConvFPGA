`ifndef _include_accel_
`define _include_accel_

`include "issue.v"
`include "issue_filter.v"
`include "allocator.v"
`include "memory.v"

/* 
 * accel.v
 *
 * This is the initial state of the global accel module. 
 */

module Accel(
        input  wire [ 7:0] image_dim,
        input  wire [ 8:0] image_depth,

        input  wire [15:0] image_memory_offset,
        input  wire [15:0] filter_memory_offset,

        input  wire [ 1:0] filter_halfsize,
        input  wire [ 2:0] filter_stride,
        input  wire [12:0] filter_length,
        input  wire [17:0] filter_bias,

        output wire        done,

        input  wire        clk,
        input  wire        rst
    );

    wire [15:0] imem_read_addr_virt;
    wire [15:0] imem_read_addr_phys;
    wire [17:0] imem_read_data;

    assign imem_read_addr_phys = imem_read_addr_virt + image_memory_offset;

    wire [15:0] fmem_read_addr_virt;
    wire [15:0] fmem_read_addr_phys;
    wire [17:0] fmem_read_data;

    assign fmem_read_addr_phys = fmem_read_addr_virt + filter_memory_offset;

    wire [ 7:0] issue_x;
    wire [ 7:0] issue_y;
    wire [17:0] issue_data;
    wire        issue_en;
    wire        issue_block;
    wire        issue_done;

    wire [7:0] positioner_x;
    wire [7:0] positioner_y;
    wire       positioner_sel;

    wire [12:0] filter_issue_counter;
    wire [17:0] filter_data;
    wire        filter_block;
    wire        filter_en;
    wire        filter_done;

    assign done = issue_done && filter_done;

    Issue #(
        .num_allocators(1)
    ) issue (
        .imem_read_addr(imem_read_addr_virt),
        .imem_read_data(imem_read_data),

        .image_dim(image_dim),
        .image_depth(image_depth),

        .filter_halfsize(filter_halfsize),
        .filter_stride(filter_stride),

        .issue_x(issue_x),
        .issue_y(issue_y),
        .issue_data(issue_data),
        .issue_en(issue_en), 

        .issue_block(issue_block),

        .positioner_x(positioner_x),
        .positioner_y(positioner_y),
        .positioner_select(positioner_sel),

        .done(issue_done), // !
        
        .clk(clk),
        .rst(rst)
    );

    IssueFilter #(
        .num_allocators(1)
    ) issue_filter (
        .filter_issue_counter(filter_issue_counter),
        .filter_data(filter_data),
        .filter_en(filter_en),
        .filter_block(filter_block),
        
        .filter_length(filter_length),

        .filter_read_addr(fmem_read_addr_virt),
        .filter_read_data(fmem_read_data),

        .done(filter_done),

        .clk(clk),
        .rst(rst)
    );

    Allocator allocator (
        .issue_a_x(issue_x),
        .issue_a_y(issue_y),
        .issue_a_data(issue_data),
        .issue_a_blocked(~issue_en),
        .issue_a_block(issue_block),

        .filter_issue_counter(filter_issue_counter),
        .filter_data(filter_data),
        .filter_blocked(~filter_en),
        .filter_block(filter_block),

        .center_x_input(positioner_x),
        .center_y_input(positioner_y),
        .center_write_enable(positioner_sel),

        .filter_halfsize(filter_halfsize),
        .filter_bias(filter_bias),
        .filter_length(filter_length),

        //.result_ready(),
        //.result_data(),

        .clk(clk),
        .rst(rst)
    );

    Memory memory (
        .read_addr_a(imem_read_addr_phys),
        .read_data_a(imem_read_data),

        .read_addr_b(fmem_read_addr_phys),
        .read_data_b(fmem_read_data),

        //.write_addr_a(),
        //.write_data_a(),
        //.write_en_a(),

        //.write_addr_b(),
        //.write_data_b(),
        //.write_en_b(),

        .clk(clk)
    );

endmodule

`endif // _include_accel_
