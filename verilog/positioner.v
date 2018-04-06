`ifndef _include_positioner_
`define _include_positioner_

/*
 * Positioner Module
 *
 * The positioner module tells the allocator units where to go. In order to
 * not have 220x16 wires going from here to the allocators, we have 220
 * allocator_select signals and a single center_x and center_y going to all of
 * them. Positioner figures out where to put the next allocator and raises its
 * select signal.
 *
 * Note that this entire module might be able to be optimized away by moving
 * to systolic allocator positioning (see "systolics.txt").
 *
 * We also expose positioning signals that describe where the current round is
 * positioned, so that broadcast knows which pixels to send to the allocators.
 *
 * Rounds are controlled by the "advance" signal and the allocator counter.
 * When we're done positioning, we wait for the issue controller to decide to
 * start the next round (when broadcast is done), at which point it will raise
 * "advance", and we'll move on to the next round.
 * The allocator counter counts how many allocators are left to assign in the
 * current round, and if it's at 0 we're done positioning for the round.
 */

/* TODO
 * 1. We can move positioning to a systolic computing model -- see
 * "systolics.txt". 
 *
 * 2. I ran a 5x5x3 image through "accel", and got a 4x4x3 output. I think
 * this is a positioner error
 */

module Positioner #(
        // Parameterized number of DSPs we have available to assign
        parameter num_allocators = 220
    ) (
        // Describe the image we'll be allocating for -- size, filter padding,
        // filter stride
        input  wire [ 7:0] image_dim,
        input  wire [ 1:0] padding,
        input  wire [ 2:0] stride,
        
        // We allocate by setting center_x and center_y and then raising the
        // relevant allocator_select line. At most one of allocator_select 
        // should be high at any time
        output reg  [ 7:0] center_x,
        output reg  [ 7:0] center_y,
        output reg  [num_allocators-1:0] allocator_select,

        // Positioner placment signals -- these describe where we've placed
        // allocators, so that the broadcast stage knows what pixels need to
        // be sent.
        output reg  [ 7:0] x_min,
        output reg  [ 7:0] x_max,
        output reg  [ 7:0] x_start,
        output reg  [ 7:0] x_end,
        output reg  [ 7:0] y_min,
        output reg  [ 7:0] y_max,

        // If there are more pixels per layer than there are allocators, we
        // place allocators in several rounds per layer. Broadcast needs to
        // happen for each round, so we wait until the "advance" signal is
        // raised before positioning the next round.
        input  wire        advance,
        output reg         round,

        // When we've placed the last pixel in a layer, we raise "done" to
        // show that we can move on to the next filter.
        output reg         done,
        
        input  wire        clk,
        input  wire        rst
    );
    
    // Counts which allocator we're currently assigning
    reg [7:0] allocator_counter;
    
    // We add "padding" rows and columns at both edges of the image. This
    // offset means that the last index that we need to position is the value
    // described below (which will be used a lot later)
    wire [7:0] position_bound;
    assign position_bound = image_dim - 1 + padding;

    // Raise the select line for the allocator we're currently positioning,
    // and only the allocator we're currently positioning
    always @(posedge clk) begin
        // Start out at zero, and when we're finished don't do anything
        if (rst || done) begin
            allocator_select <= 0;

        // While we're waiting for the next round, stay at zero
        end else if (allocator_counter == 0) begin
            allocator_select[num_allocators-1] <= 0;
            
            // If advance is high, we're starting the next round, start
            // assigning
            if (advance) begin // allocator_counter is 0
                allocator_select[allocator_counter] <= 1;
            end

        // While we're counting up, turn on the new allocator's select, 
        // and turn off the old one
        end else if (allocator_counter < num_allocators) begin
            allocator_select[allocator_counter] <= 1;
            allocator_select[allocator_counter-1] <= 0;

        // If we've reached the end, turn off the last select line
        end else if (allocator_counter == num_allocators) begin
            allocator_select[num_allocators-1] <= 0;

        // The else state shouldn't happen
        end
    end

    // allocator_counter describes which allocator we're currently positioning
    // (in a 8bit form, as opposed to the allocator_select one-hot encoding). 
    // It's stable at 0 if advance is low, otherwise counts up to
    // num_allocators and then wraps to 0.
    always @(posedge clk) begin
        // Start out at stable state 0
        if (rst) begin
            allocator_counter <= 0;

        // While we're at zero, hold state unless advance is high
        end else if (allocator_counter == 0) begin
            if (advance) begin
                allocator_counter <= allocator_counter + 1;
            end

        // If we're not at zero, and not at the end, just count up
        end else if (allocator_counter < num_allocators) begin
            allocator_counter <= allocator_counter + 1;

        // When we hit the end, reset to 0
        end else if (allocator_counter == num_allocators) begin
            allocator_counter <= 0;

        // Else case shouldn't happen
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            round <= 0;

        end else if (advance) begin
            round <= 0;

        end else if (allocator_counter == num_allocators) begin
            round <= 1;

        end 
    end

    // Now we're going to start calculating where to actually put the DSPs.
    // For this, we need to know where the next position is. 
    // These signals are a simple (current position + stride), the usefulness
    // of which will be apparent shortly.
    wire [7:0] advance_x;
    wire [7:0] advance_y;
    assign advance_x = center_x + stride;
    assign advance_y = center_y + stride;

    // Compute the next X position to be assigned.
    wire [7:0] next_x;
    assign next_x = (
        // If the next step would be out of bounds in both x and y, just stay
        // steady; we're done.
        (advance_x > position_bound && advance_y > position_bound) ? 
            center_x 

        // Otherwise if the next position would be out of bounds in x, go back
        // to the start of x
        : (advance_x > position_bound) ?
            padding

        // Otherwise, just increment x by stride
        :
            advance_x
    );

    // Compute the next Y position to be placed
    wire [7:0] next_y;
    assign next_y = (
        // If X is ready to wrap around, and Y would not advance out of
        // bounds, then increment Y by stride
        (advance_x > position_bound && advance_y <= position_bound) ?
            advance_y

        // Otherwise, keep Y the same
        : 
            center_y
    );

    always @(posedge clk) begin
        // Initial state is not done
        if (rst) begin
            done <= 0;

        // If we're assigning something and the next X and Y would be out of
        // bounds, we're done; set the done signal
        end else if ((allocator_select != 0) && (advance_x > position_bound) && (advance_y > position_bound)) begin
            done <= 1;

        // Otherwise, hold state
        end
    end
    
    // Compute center_x, center_y, x_start, x_end, y_min, y_max
    always @(posedge clk) begin
        // Initial / reset values
        if (rst) begin
            center_x <= padding; // XY starts at (padding, padding)
            center_y <= padding; // (the top left of the image)
            x_start <= 0; // Start of position data will be set later
            x_end <= 0; // We can init all of these to 0
            y_min <= 0; // ^
            y_max <= 0; // ^

        // If we're waiting for a round, wait for the advance signal to do
        // anything
        end else if (allocator_counter == 0) begin
            // When advance goes high
            if (advance) begin
                // Padding is equal to "filter_halfsize", or the offset of the
                // edge of the filter to the center of the filter. So the
                // first position that needs to be broadcast is described here.
                x_start <= center_x - padding; 
                y_min <= center_y - padding;
            end 

        // If we're counting up,
        end else if (allocator_counter <= num_allocators) begin
            // the center_* signals are calculated by continuous assignment as
            // above
            center_x <= next_x;
            center_y <= next_y;

            // And we can keep on setting these; they'll be correct for the 
            // round when we reach the last value, and the broadcaster can use
            // intermediate values before they're finalized like this
            x_end <= center_x + padding;
            y_max <= center_y + padding;
        end
    end
    
    // Compute x_min and x_max
    always @(posedge clk) begin
        // Starting positions
        if (rst) begin
            x_min <= -1; // Note: this is INTMAX for unsigned
            x_max <= 0;

        // At steady state, only compute if advance is high
        end else if (allocator_counter == 0) begin
            // We'll start off at an easy (center_x, center_x)
            if (advance) begin
                x_min <= center_x;
                x_max <= center_x;
            end

        // While we're counting up, we can compute x_min and x_max
        // continuously.
        end else if (allocator_counter <= num_allocators) begin
            // If the filter's min x value is less than our current x_min, set
            // x_min
            if (center_x - padding < x_min) begin
                x_min <= center_x - padding;
            end

            // Likewise for x_max
            if (center_x + padding > x_max) begin
                x_max <= center_x + padding;
            end

            // These compute a standard min() and max() as we progress through
            // the list.
        end
    end
endmodule
`endif // _include_positioner_
