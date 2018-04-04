`ifndef _include_accel_
`define _include_accel_

`include "issue.v"
`include "issue_filter.v"
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
        output wire        done,

        input  wire        clk,
        input  wire        rst
    );

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

    // Connections regarding image data out of image issue
    wire [ 7:0] issue_x;
    wire [ 7:0] issue_y;
    wire [17:0] issue_data;
    wire        issue_en;
    wire        issue_block;
    wire        issue_done;
    reg         issue_advance;
    
    // Positioner data out of image issue
    // As in above TODO, this could be broken out into a separate top-level
    // module
    wire [7:0] positioner_x;
    wire [7:0] positioner_y;
    wire       positioner_sel;

    // filter data out of filter issue
    wire [12:0] filter_issue_counter;
    wire [17:0] filter_data;
    wire        filter_block;
    wire        filter_en;
    wire        filter_done;

    // round_done marks the distinction between issue rounds, and when it goes
    // high round_data will have the output of the DSP
    // Ideally, round_done is an OR reduction on all of the DSP's
    // "result_ready" signals
    wire        round_done;
    wire [17:0] round_data;

    // Global allocator reset signal (for now, "global" means one)
    // Between issue rounds, all allocators need a cycle of reset
    reg  allocator_rst;
    
    // When both image issue and filter issue have sent all the data, we're
    // done with computation
    // TODO this is almost correct, but a bit premature -- we should check
    // that all the DSPs have finished computation and output as well
    assign done = issue_done && filter_done;

    // The issue stage, which picks out what values from image memory need to
    // be sent to the DSPs, and sends them to all the DSPs
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
        
        .advance(issue_advance),
        .done(issue_done),
        
        .clk(clk),
        .rst(rst)
    );
    
    // The filter issue stage, which sends a sequence of filter data to the
    // DSPs, fairly simply. If we move to a systolic array, this only needs to
    // be connected to the first DSP.
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
    
    // The allocator stage, which controls a single DSP. When we eventually
    // move to more DSP units, we'll need to set up a "generate" loop here to
    // place a bunch of them down
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

        .result_ready(round_done),
        .result_data(round_data),

        .clk(clk),
        .rst(allocator_rst | rst)
    );
    
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
    
    // Control the issue_advance signal, which tells "issue" when it can move
    // on to positioning and broadcasting the next round of data. We want to
    // raise this for one cycle as soon as we've read everything that the DSPs
    // have output. The allocators each put this out on their "result_ready"
    // signal, which we have mapped to "round_done".
    always @(posedge clk) begin
        // Start out high (this doesn't really matter)
        if (rst) begin
            issue_advance <= 1;
        
        // Auto toggle off after one cycle
        end else if (issue_advance) begin
            issue_advance <= 0;
        
        // When the allocators have finished this round, we can tell issue to
        // start up the next round
        end else if (round_done) begin
            issue_advance <= 1;
        end
    end

    // Control the allocator reset signal. We want to raise this when a round
    // has finished.
    always @(posedge clk) begin
        // Initial: start at 0
        if (rst) begin
            allocator_rst <= 0;

        // When the allocator finishes, reset the allocator (and emit an
        // output for debug purposes)
        end else if (round_done) begin
            allocator_rst <= 1;
            if (!allocator_rst) begin
                $display("DSP emits: %d", round_data);
            end

        // Otherwise, we don't need to reset the allocator
        end else begin
            allocator_rst <= 0;

        end
    end

endmodule

`endif // _include_accel_
