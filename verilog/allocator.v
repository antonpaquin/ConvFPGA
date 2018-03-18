`ifndef _include_allocator_
`define _include_allocator_

`include "allocator_controller.v"
`include "ramb18_emu.v"
`include "dsp_controller.v"

module Allocator(
        input  wire [ 7:0] issue_a_x,
        input  wire [ 7:0] issue_a_y,
        input  wire [17:0] issue_a_data,
        input  wire        issue_a_blocked,
        output wire        issue_a_block,

        input  wire [12:0] filter_issue_counter,
        input  wire [17:0] filter_data,
        input  wire        filter_blocked,
        output wire        filter_block,

        input  wire [ 7:0] center_x,
        input  wire [ 7:0] center_y,

        input  wire [ 2:0] filter_dim,
        input  wire [17:0] filter_bias,
        input  wire [12:0] filter_length,

        output wire        result_ready,
        output wire [17:0] result_data,

        input  wire        clk,
        input  wire        rst
    );
    
    wire [ 9:0] ramb_read_a_addr,
                ramb_read_b_addr,
                ramb_writ_a_addr,
                ramb_writ_b_addr;

    wire [17:0] ramb_read_a_data,
                ramb_read_b_data,
                ramb_writ_a_data,
                ramb_writ_b_data;

    wire        ramb_writ_a_en,
                ramb_writ_b_en;

    wire [12:0] issue_a_alloc_counter,
                issue_a_dsp_counter;

    wire [12:0] filter_dsp_counter;

    wire [47:0] result;
    
    AllocatorController controller (
        .issue_a_x(issue_a_x),
        .issue_a_y(issue_a_y),
        .issue_a_data(issue_a_data),
        .issue_a_blocked(issue_a_blocked),
        
        .issue_a_alloc_counter(issue_a_alloc_counter),
        .issue_a_dsp_counter(issue_a_dsp_counter),
        .issue_a_block(issue_a_block),

        .filter_data(filter_data),
        .filter_blocked(filter_blocked),

        .filter_issue_counter(filter_issue_counter),
        .filter_dsp_counter(filter_dsp_counter),
        .filter_block(filter_block),

        .center_x(center_x),
        .center_y(center_y),

        .filter_dim(filter_dim),
        .filter_bias(filter_bias),
        .filter_length(filter_length),

        .ramb_a_write_en(ramb_writ_a_en),
        .ramb_a_data(ramb_writ_a_data),
        .ramb_a_addr(ramb_writ_a_addr),

        .ramb_b_write_en(ramb_writ_b_en),
        .ramb_b_data(ramb_writ_b_data),
        .ramb_b_addr(ramb_writ_b_addr),

        //.result_ready(???),
        //.result_data(???),
        
        .clk(clk),
        .rst(rst)
    );
    
    DspController dsp (
        .ramb_a_addr(ramb_read_a_addr),
        .ramb_a_data(ramb_read_a_data),
        .ramb_b_addr(ramb_read_b_addr),
        .ramb_b_data(ramb_read_b_data),

        .issue_a_alloc_counter(issue_a_alloc_counter),
        .issue_a_dsp_counter(issue_a_dsp_counter),

        .filter_issue_counter(filter_issue_counter),
        .filter_dsp_counter(filter_dsp_counter),
        
        .result(result),

        .clk(clk),
        .rst(rst)
    );
    
    Ramb18Emu ramb (
        .read_addr_a(ramb_read_a_addr),
        .read_data_a(ramb_read_a_data),
        .read_addr_b(ramb_read_b_addr),
        .read_data_b(ramb_read_b_data),

        .write_addr_a(ramb_writ_a_addr),
        .write_data_a(ramb_writ_a_data),
        .write_en_a  (ramb_writ_a_en),

        .write_addr_b(ramb_writ_b_addr),
        .write_data_b(ramb_writ_b_data),
        .write_en_b  (ramb_writ_b_en),

        .clk(clk)
    );

endmodule
`endif // _include_allocator_
