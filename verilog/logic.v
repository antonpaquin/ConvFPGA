`ifndef _include_logic_
`define _include_logic_

`include "accel.v"
`include "interface.v"

module Logic (
        input  wire [23:0] master_bus,
        input  wire        clk,
        input  wire        rst
    );

    wire [ 7:0] image_dim;
    wire [ 8:0] image_depth;

    wire [15:0] image_memory_offset;
    wire [15:0] filter_memory_offset;
    wire [15:0] output_memory_offset;

    wire [ 1:0] filter_halfsize;
    wire [ 2:0] filter_stride;
    wire [12:0] filter_length;
    wire [17:0] filter_bias;

    wire [15:0] interface_write_addr;
    wire [17:0] interface_write_data;
    wire        interface_write_en;

    wire        accel_trigger;
    wire        accel_done;
    reg         accel_active;

    Accel accel (
        .image_dim(image_dim),
        .image_depth(image_depth),

        .image_memory_offset(image_memory_offset),
        .filter_memory_offset(filter_memory_offset),
        .output_memory_offset(output_memory_offset),

        .filter_halfsize(filter_halfsize),
        .filter_stride(filter_stride),
        .filter_length(filter_length),
        .filter_bias(filter_bias),

        .interface_write_addr(interface_write_addr),
        .interface_write_data(interface_write_data),
        .interface_write_en(interface_write_en),

        .accel_done(accel_done),

        .clk(clk),
        .rst(rst | ~accel_active)
    );

    Interface interface (
        .master_bus(master_bus),

        .image_dim(image_dim),
        .image_depth(image_depth),

        .image_memory_offset(image_memory_offset),
        .filter_memory_offset(filter_memory_offset),
        .output_memory_offset(output_memory_offset),

        .filter_halfsize(filter_halfsize),
        .filter_stride(filter_stride),
        .filter_length(filter_length),
        .filter_bias(filter_bias),

        .mem_write_data(interface_write_data),
        .mem_write_addr(interface_write_addr),
        .mem_write_en(interface_write_en),

        .trigger_accel(accel_trigger),

        .clk(clk),
        .rst(rst)
    );

    always @(posedge clk) begin
        if (rst) begin
            accel_active <= 0;
        end else if (accel_trigger) begin
            accel_active <= 1;
        end else if (accel_done) begin
            // This resets immediately
            // TODO make it reset when reporting has finished
            accel_active <= 0;
        end
    end
endmodule
`endif // _include_logic_
