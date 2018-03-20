`ifndef _include_issue_
`define _include_issue_

`include "issue_broadcast.v"
`include "issue_mem.v"
`include "issue_positioner.v"

module Issue #(
        parameter num_allocators = 220
    ) (
        input  wire [15:0] imem_write_addr_a,
        input  wire [17:0] imem_write_data_a,
        input  wire        imem_write_en_a,

        input  wire [ 7:0] image_dim,
        input  wire [ 8:0] image_depth,

        input  wire [ 1:0] filter_halfsize,
        input  wire [ 2:0] filter_stride,

        output wire [ 7:0] issue_x,
        output wire [ 7:0] issue_y,
        output wire [17:0] issue_data,
        output wire        issue_en,

        input  wire [num_allocators-1:0] issue_block,

        output wire [ 7:0] positioner_x,
        output wire [ 7:0] positioner_y,
        output wire [num_allocators-1:0] positioner_select,

        output reg         done,

        input  wire        clk,
        input  wire        rst

    );

    wire positioner_done;
    reg  positioner_advance;
    reg  positioner_rst;
    wire positioner_rst_or;

    wire broadcast_done;
    reg  broadcast_rst;

    assign positioner_rst_or = (positioner_rst || rst);

    wire [7:0] x_min,
               x_max,
               x_start,
               x_end,
               y_min,
               y_max;

    wire [15:0] imem_read_addr_a;
    wire [17:0] imem_read_data_a;

    // The positioner needs a bit of a head start on broadcast, so that each
    // allocator knows its position before it gets any values
    localparam positioner_headstart = 5;
    reg  [2:0] positioner_headstart_counter;

    IssueBroadcast broadcast(
        .ramb_read_addr(imem_read_addr_a),
        .ramb_read_data(imem_read_data_a),
        
        .image_dim(image_dim),
        .image_depth(image_depth),
        .image_padding(filter_halfsize),

        .x_min(x_min),
        .x_max(x_max),
        .x_start(x_start),
        .x_end(x_end),
        .y_min(y_min),
        .y_max(y_max),

        .issue_block(|issue_block), // Notice: OR reduction
        .issue_en(issue_en),

        .current_x(issue_x),
        .current_y(issue_y),
        .current_data(issue_data),

        .done(broadcast_done),

        .clk(clk),
        .rst(broadcast_rst)
    );

    IssuePositioner #(
        .num_allocators(num_allocators)
    ) positioner (
        .image_dim(image_dim),
        .padding(filter_halfsize),
        .stride(filter_stride),

        .center_x(positioner_x),
        .center_y(positioner_y),
        .allocator_select(positioner_select),

        .x_min(x_min),
        .x_max(x_max),
        .x_start(x_start),
        .x_end(x_end),
        .y_min(y_min),
        .y_max(y_max),

        .advance(positioner_advance),
        .done(positioner_done),

        .clk(clk),
        .rst(positioner_rst_or)
    );

    IssueMemory memory(
        .read_addr_a(imem_read_addr_a),
        .read_data_a(imem_read_data_a),

        //.read_addr_b(),
        //.read_data_b(),

        .write_addr_a(imem_write_addr_a),
        .write_data_a(imem_write_data_a),
        .write_en_a(imem_write_en_a),

        //.write_addr_b(),
        //.write_data_b(),
        //.write_en_b(),

        .clk(clk)
    );

    always @(posedge clk) begin
        if (rst) begin
            positioner_headstart_counter <= 0;
            broadcast_rst <= 1;
        end else if (done) begin
            broadcast_rst <= 1;
        end else if (positioner_headstart_counter == 0 && !positioner_advance) begin
        end else if (positioner_headstart_counter == positioner_headstart) begin
            broadcast_rst <= 0;
            positioner_headstart_counter <= 0;
        end else begin
            broadcast_rst <= 1;
            positioner_headstart_counter <= positioner_headstart_counter + 1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
            positioner_advance <= 1;
            positioner_rst <= 0;
        end else if (positioner_advance) begin
            positioner_advance <= 0;
        end else if (broadcast_done && positioner_done) begin
            positioner_rst <= 1;
            done <= 1;
        end else if (broadcast_done) begin
            positioner_advance <= 1;
        end
    end
endmodule
`endif // _include_issue_
