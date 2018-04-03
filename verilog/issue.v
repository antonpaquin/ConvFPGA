`ifndef _include_issue_
`define _include_issue_

`include "issue_broadcast.v"
`include "issue_positioner.v"

/*
 * Issue is the module that describes where things go.
 * It describes, broadly:
 *   - The positioning of the allocators
 *   - The passing of filter data to allocators
 *   - The passing of image data to allocators
 *
 * Each allocator is first positioned, and then given the data it needs to
 * complete its computation.
 *
 * Since the image will likely have more pixels than we have DSPs, positioning
 * is done in several rounds, each round positioning up to the max number of
 * DSPs. Then, image data is sent to each of these DSPs, before the next round
 * is started.
 *
 * Image data issue ("broadcast") is done by tracking where the DSPs have been
 * positioned in the past round, and sweeping across the pixel data over all
 * pixels covered by the DSPs. This avoids having to send the entire image for
 * each positioning round.
 *
 * The allocators are designed to allow connections to multiple issue units,
 * allowing higher memory throughput. This would require proper operation of
 * the "block" signal, which is not yet tested.
 *
 * IssuePositioner controls the positioning phase of this design.
 * IssueBroadcast controls the image data portion.
 *
 * This module contains and connects the above modules, and manages the reset
 * signals that allow for multiple rounds of execution.
 */

/* TODO
 * 
 * 1. The block signals are not yet tested, and they may cause timing errors.
 * We should simulate these to ensure that they quickly propagate to the 
 * broadcast module, such that the allocators do not miss any data if a block
 * is sent.
 *
 * 2. The positioning algorithm can account for stride, but its description of
 * covered pixels does not. You can see this if you run a 5x5 stride 4 
 * filter with 2 DSPs, and run it until the DSPs are positioned across a line
 * break. The expected behavior is that only the covered pixels are issued, 
 * and the seen behavior is that pixels in the higher row outside the
 * rightmost column are broadcast as well.
 * (Note that we do not need to support strides larger than the filter size).
 *
 * 3. (Shared with allocator) the proper position and filter data to be sent
 * to an allocator is available in the previous allocator. This may allow for
 * systolic computing, which would cut down on the connection requirements of
 * this module.
 *
 * 4. Allocators currently don't store their outputs anywhere. We may have to
 * find a way to propagate those values back up through this module.
 *
 * 5. We aren't currently dealing with filter weights at all. Do we want to do
 * this with another copy of the issue stage, or by doing both a filter issue
 * and an image issue in the same module?
 */

module Issue #(
        // The number of allocators / DSP units that will be attached to this
        // issue module.
        parameter num_allocators = 220
    ) (
        // Issue requires read access to image memory. In this implementation,
        // we hold the main memory in the top level module, and accept read
        // signals. 
        // We could also accomplish this by holding the memory here and export
        // write signals.
        output wire [15:0] imem_read_addr,
        input  wire [17:0] imem_read_data,

        // Dimensions of the image currently being worked on. Dim goes from
        // 13x13 to 224x224, and depth goes from 3 to 384. 
        input  wire [ 7:0] image_dim,
        input  wire [ 8:0] image_depth,

        // Describes the filter we're currently using. 
        // halfsize is the distance from the edge of the filter to the center
        //     2 for 5x5 filter, 1 for a 3x3
        // stride is the filter stride, standard convolutional network meaning
        input  wire [ 1:0] filter_halfsize,
        input  wire [ 2:0] filter_stride,

        // The outputs of the broadcast -- x and y position of which pixel is
        // currently active, what data is being sent, and whether the signal
        // is good to be used.
        output wire [ 7:0] issue_x,
        output wire [ 7:0] issue_y,
        output wire [17:0] issue_data,
        output wire        issue_en,
        
        // Each DSP can send a blocking signal. While any of these is high,
        // issue should not continue to the next pixel, waiting for the signal
        // to go low before continuing.
        input  wire [num_allocators-1:0] issue_block,
        
        // DSP positioning. Issue will set an x and y describing where, and
        // will raise a wire to the allocator that is meant to accept the
        // signal.
        output wire [ 7:0] positioner_x,
        output wire [ 7:0] positioner_y,
        output wire [num_allocators-1:0] positioner_select,
        
        // Done -- when all pixels in the image have been positioned,
        // broadcast through the full depth of the image, and output returned.
        output reg         done,

        input  wire        clk,
        input  wire        rst

    );
    
    // Reset control for the positioner. Positioner should start off, turn on
    // when we begin working on an (image, filter) pair, walk through one or
    // many rounds of positioning, and turn off after
    wire positioner_done;
    reg  positioner_advance;
    reg  positioner_rst;
    wire positioner_rst_or;

    // Reset control for the broadcast stage. Broadcast should start off,
    // turn on a short while after the positioner has started each round, and
    // then turn off when it has finished broadcasting.
    wire broadcast_done;
    reg  broadcast_rst;

    // Allow global reset to control the positioner
    assign positioner_rst_or = (positioner_rst || rst);

    // The positioner computes where it has placed DSPs this round, and stores
    // that information in these signals. These are then sent to issue to
    // determine which pixels need to be sent.
    // These will be important to bug #2
    wire [7:0] x_min,
               x_max,
               x_start,
               x_end,
               y_min,
               y_max;

    // Lower level modules would like to know what is the highest z-index to
    // go to, instead of how many that is (index at 0, vs at 1). Might as well
    // compute that here.
    wire [8:0] z_max;
    assign z_max = image_depth - 1;

    // The positioner needs a bit of a head start on broadcast, so that each
    // allocator knows its position before it gets any values. We'll use
    // a counter that starts counting as soon as the positioner starts, and
    // turns on when it reaches this predefined value. 
    localparam positioner_headstart = 5;
    reg  [2:0] positioner_headstart_counter;

    // Broadcast stage, walks through the image data and puts out values
    IssueBroadcast broadcast(
        .ramb_read_addr(imem_read_addr),
        .ramb_read_data(imem_read_data),
        
        .image_dim(image_dim),
        .image_padding(filter_halfsize),

        .x_min(x_min),
        .x_max(x_max),
        .x_start(x_start),
        .x_end(x_end),
        .y_min(y_min),
        .y_max(y_max),
        .z_max(z_max),

        .issue_block(|issue_block), // Notice: OR reduction
        .issue_en(issue_en),

        .current_x(issue_x),
        .current_y(issue_y),
        .current_data(issue_data),

        .done(broadcast_done),

        .clk(clk),
        .rst(broadcast_rst)
    );

    // Positioner stage, computes DSP positioning and tells them what image
    // values to pay attention to
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

    // Control broadcast_rst
    always @(posedge clk) begin
        // We should start off reset
        if (rst) begin
            broadcast_rst <= 1;

        // Then use the headstart counter to start slightly after the positioner
        // advances
        end else if (positioner_headstart_counter == positioner_headstart) begin
            broadcast_rst <= 0;

        // If broadcast is done then go back to reset,
        end else if (broadcast_done) begin
            broadcast_rst <= 1;

        // Otherwise hold state
        end
    end
    
    // Control the headstart counter
    always @(posedge clk) begin
        // Start off at zero
        if (rst) begin
            positioner_headstart_counter <= 0;

        // If we're not counting and the positioner isn't starting, stay at
        // zero
        end else if (positioner_headstart_counter == 0 && !positioner_advance) begin
            positioner_headstart_counter <= 0;

        // Otherwise, we're already counting or the positioner has started,
        // start counting up
        end else begin
            positioner_headstart_counter <= positioner_headstart_counter + 1;
        end
    end
    
    // Track the positioner advance and reset, and the global "done" signal
    always @(posedge clk) begin
        // Start off:
        if (rst) begin
            done <= 0; // Computation isn't done
            positioner_advance <= 1; // The positioner should start positioning immediately
            positioner_rst <= 0; // And the positioner should be enabled
        
        // positioner_advance turns off after one cycle
        end else if (positioner_advance) begin
            positioner_advance <= 0;

        // If the positioner has reached the end of the image, and broadcast
        // is done, then we've sent everything we need to.
        end else if (broadcast_done && positioner_done) begin
            positioner_rst <= 1; // Turn off positioner
            done <= 1; // And signal that issue is done
        
        // Or if broadcast has finished its processing for the round, move on
        // to the next round
        end else if (broadcast_done) begin
            positioner_advance <= 1;

        // Otherwise, hold state
        end
    end
endmodule
`endif // _include_issue_
