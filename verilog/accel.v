`ifndef _include_accel_
`define _include_accel_

`include "scheduler.v"
`include "image_broadcast.v"
`include "filter_broadcast.v"
`include "positioner.v"
`include "allocator.v"
`include "memory.v"

/* 
 * accel.v
 *
 * This is the accel module, which connects the allocator and issue stage into
 * one unit. You'll see that there isn't much logic here, just wiring up the
 * two modules.
 *
 * What accel _is_ responsible for: controlling the allocator resets + timing
 * the issue rounds. The logic is described more but generally allocator is
 * controlling what is running when.
 * 
 * It's possible that we break the positioner unit out of issue, in which case
 * that would also sit and be controlled here. This would unify the scheduling
 * code to mostly one place, which would be a good thing, but it would involve
 * moving a bunch of signals from issue, which would be a significant
 * refactor, so for now it's a TODO.
 */

module Accel(
        // We need some signals about the image. Right now, I'm thinking about
        // putting them in special memory locations and picking them out of
        // the stream in the "interface" stage.
        input  wire [ 7:0] image_dim,
        input  wire [ 8:0] image_depth,

        // The image and filter can be anywhere in main memory, as long as
        // they are contiguous. We just need to know where each starts.
        input  wire [15:0] image_memory_offset,
        input  wire [15:0] filter_memory_offset,
        
        // Constant information about the filter, which will be distributed
        // throughout the chip.
        input  wire [ 1:0] filter_halfsize,
        input  wire [ 2:0] filter_stride,
        input  wire [12:0] filter_length,
        input  wire [17:0] filter_bias,
    
        // Done signal for when this (image, filter) pair has been completed
        output wire        accel_done,

        input  wire        clk,
        input  wire        rst
    );

    // Reset control for the positioner. Positioner should start off, turn on
    // when we begin working on an (image, filter) pair, walk through one or
    // more rounds of positioning, and turn off after
    wire image_broadcast_round;
    wire image_broadcast_rst;

    wire filter_broadcast_done;
    wire filter_broadcast_rst;

    wire positioner_round;
    wire positioner_advance;
    wire positioner_done;
    wire positioner_rst;

    wire allocator_done;
    wire allocator_rst;

    wire [17:0] image_broadcast_data;
    wire [ 7:0] image_broadcast_x;
    wire [ 7:0] image_broadcast_y;
    wire        image_broadcast_block;
    wire        image_broadcast_en;

    // filter data out of filter issue
    wire [12:0] filter_broadcast_counter;
    wire [17:0] filter_broadcast_data;
    wire        filter_broadcast_block;
    wire        filter_broadcast_en;

    wire [7:0] positioner_x;
    wire [7:0] positioner_y;
    wire       positioner_sel;

    // The positioner computes where it has placed DSPs this round, and stores
    // that information in these signals. These are then sent to issue to
    // determine which pixels need to be sent.
    wire [7:0] field_x_min,
               field_x_max,
               field_x_start,
               field_x_end,
               field_y_min,
               field_y_max;

    wire [17:0] allocator_data;

    // I'm naming this "virtual" and "physical", though that isn't perfectly
    // accurate. The issue stages assume that their data starts at address 0,
    // so if we need to store it somewhere else we just add a constant offset.
    // This is that computation for image memory
    wire [15:0] imem_read_addr_virt;
    wire [15:0] imem_read_addr_phys;
    wire [17:0] imem_read_data;

    assign imem_read_addr_phys = imem_read_addr_virt + image_memory_offset;
    
    // as above, for filter memory
    wire [15:0] fmem_read_addr_virt;
    wire [15:0] fmem_read_addr_phys;
    wire [17:0] fmem_read_data;

    assign fmem_read_addr_phys = fmem_read_addr_virt + filter_memory_offset;

    Scheduler scheduler (
        .positioner_round(positioner_round),
        .positioner_advance(positioner_advance),
        .positioner_done(positioner_done),
        .positioner_rst(positioner_rst),

        .image_broadcast_round(image_broadcast_round),
        .image_broadcast_rst(image_broadcast_rst),

        .filter_broadcast_done(filter_broadcast_done),
        .filter_broadcast_rst(filter_broadcast_rst),

        .allocator_done(allocator_done),
        .allocator_rst(allocator_rst),

        .accel_done(accel_done),
        
        .advance(1'b1),

        .clk(clk),
        .rst(rst)
    );

    // The issue stage, which picks out what values from image memory need to
    // be sent to the DSPs, and sends them to all the DSPs
    ImageBroadcast image_broadcast (
        .ramb_read_addr(imem_read_addr_virt),
        .ramb_read_data(imem_read_data),

        .image_dim(image_dim),
        .image_padding(filter_halfsize),

        .x_min(field_x_min),
        .x_max(field_x_max),
        .x_start(field_x_start),
        .x_end(field_x_end),
        .y_min(field_y_min),
        .y_max(field_y_max),
        .z_max((image_depth-1)),

        .block(image_broadcast_block),
        .en(image_broadcast_en),

        .current_x(image_broadcast_x),
        .current_y(image_broadcast_y),
        .current_data(image_broadcast_data),

        .round(image_broadcast_round),

        .clk(clk),
        .rst(rst | image_broadcast_rst)
    );

    // The filter issue stage, which sends a sequence of filter data to the
    // DSPs, fairly simply. If we move to a systolic array, this only needs to
    // be connected to the first DSP.
    FilterBroadcast #(
        .num_allocators(1)
    ) filter_broadcast (
        .counter(filter_broadcast_counter),
        .data(filter_broadcast_data),
        .en(filter_broadcast_en),
        .block(filter_broadcast_block),
        
        .filter_length(filter_length),

        .filter_read_addr(fmem_read_addr_virt),
        .filter_read_data(fmem_read_data),

        .done(filter_broadcast_done),

        .clk(clk),
        .rst(rst | filter_broadcast_rst)
    );

    Positioner #(
        .num_allocators(1)
    ) positioner (
        .image_dim(image_dim),
        .padding(filter_halfsize),
        .stride(filter_stride),

        .center_x(positioner_x),
        .center_y(positioner_y),
        .allocator_select(positioner_sel),

        .x_min(field_x_min),
        .x_max(field_x_max),
        .x_start(field_x_start),
        .x_end(field_x_end),
        .y_min(field_y_min),
        .y_max(field_y_max),

        .advance(positioner_advance),
        .round(positioner_round),
        .done(positioner_done),

        .clk(clk),
        .rst(rst | positioner_rst)
    );
    
    
    // The allocator stage, which controls a single DSP. When we eventually
    // move to more DSP units, we'll need to set up a "generate" loop here to
    // place a bunch of them down
    Allocator allocator (
        .image_a_x(image_broadcast_x),
        .image_a_y(image_broadcast_y),
        .image_a_data(image_broadcast_data),
        .image_a_blocked(~image_broadcast_en),
        .image_a_block(image_broadcast_block),

        .filter_counter(filter_broadcast_counter),
        .filter_data(filter_broadcast_data),
        .filter_blocked(~filter_broadcast_en),
        .filter_block(filter_broadcast_block),

        .center_x_input(positioner_x),
        .center_y_input(positioner_y),
        .center_write_enable(positioner_sel),

        .filter_halfsize(filter_halfsize),
        .filter_bias(filter_bias),
        .filter_length(filter_length),

        .done(allocator_done),
        .result_data(allocator_data),

        .clk(clk),
        .rst(rst | allocator_rst)
    );
    
    // Debug / this is a hack
    always @(posedge allocator_done) begin
        $display("DSP emits: %d", allocator_data);
    end
    
    // Simple memory unit. We'll probably expose the write lines to the
    // interface module.
    // If we move to multiple broadcast stages, this will become more
    // interesting.
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
