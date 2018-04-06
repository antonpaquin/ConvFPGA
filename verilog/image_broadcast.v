`ifndef _include_image_broadcast_
`define _include_image_broadcast_

/*
 * Image Broadcast
 *
 * Given some bounds and memory access, this module will:
 *     - Compute what pixels need to be sent
 *     - Compute those pixels' locations in memory
 *     - Read the pixel value and send it out to the allocators (through the
 *       issue stage)
 * 
 * To describe what pixels need to be sent, we use the signals coming out of
 * the positioner (x_min, x_max, x_start, x_end, y_min, y_max). From these, we
 * say the issue round falls into one of three cases:
 *     - "rectangle": 
 *           the issue does not wrap around the edge
 *     - "jump": 
 *           the issue wraps around the edge, but the wrapped around pixels do 
 *           not connect with the non-wrapped-around pixels
 *     - "continuous": 
 *           The issue wraps around the edge and the wraparound connects with
 *           the previous line
 *
 * It's easier to see than to read about, for which I recommend running the
 * sim "issue_tb.v". Imagine you've got a square, and you're drawing a line
 * across the square that continues on the next row when you hit the edge, and
 * you need to describe all the pixels you've drawn on. That's the bulk of the
 * work that this module does.
 *
 */

/* TODO
 *
 * 1. I'm not sure x_rectangle is ever hit in practice -- for a 3x3 filter
 * centered at (5, 5) y_min should be 4 and y_max should be 6, even though
 * this is cearly the "x_rectangle" case. We should fix this.
 *
 * 2. As described in "issue.v" TODO #2: the algorithm does not account for
 * stride, and if an edge is crossed it will assume that the edge continuation
 * is only one line down, instead of a full stride down. This should occur in
 * the "continuous" and "jump" cases.
 *
 * 3. RAM reading is currently accomplished with the simple but area-expensive
 * form of a 8x8x8 multiplier. We could instead accomplish this with adders,
 * incrementing the address by the proper amount along with next_x, next_y,
 * and next_z as they are updated.
 */
module ImageBroadcast(
        // Memory signals -- we need read access to image memory
        output wire [15:0] ramb_read_addr,
        input  wire [17:0] ramb_read_data,
        
        // Description of the image
        input  wire [ 7:0] image_dim, // the width (and height) of the entire image
        // Padding is the amount of zeroes we have to send in addition to the
        // image itself. 2 for a 5x5 filter, 1 for a 3x3.
        // For example, for a 3x3 filter at image (0, 0), we translate that
        // pixel to (1,1) so that the full 3x3 square (0, 0) -> (2, 2) is covered.
        input  wire [ 1:0] image_padding, 
        
        // Positioner description signals, describing where we have to
        // broadcast pixel values
        input  wire [ 7:0] x_min,
        input  wire [ 7:0] x_max,
        input  wire [ 7:0] x_start,
        input  wire [ 7:0] x_end,
        input  wire [ 7:0] y_min,
        input  wire [ 7:0] y_max,
        input  wire [ 8:0] z_max,

        // Whether we should continue to send values, or to wait
        input  wire        block,
        output reg         en,
        
        // This data represents the currently issued pixel. The allocators
        // will read this to pick up their pixel data as the allocator sweeps
        // along the image. 
        output reg  [ 7:0] current_x,
        output reg  [ 7:0] current_y,
        output wire [17:0] current_data,
        
        // When all pixels for this round have been sent, raise "round"
        output reg         round,

        input  wire        clk,
        input  wire        rst
    );
    
    // We have individual signals for each mode of positioner allocation (as
    // described above). Only one of these should be high at a time.
    // These should be continuously assigned, since the mode might change
    // at any time while the positioner does its work for the round. 
    wire x_continuous;
    wire x_jump;
    wire x_rectangle;

    // See TODO #1. This should describe when the pixel allocation never hits
    // an edge.
    assign x_rectangle = (y_min == y_max);

    // Jump means it spans two positioned rows of pixels, but the wraparound 
    // doesn't go all the way to the start of the previous row
    assign x_jump = ((y_min + 1 == y_max) && (x_end < x_start));

    // Continous means it spans 2+ positioned rows, and the wraparound
    // connects. This means that the addressed space is continous
    // See TODO #2 -- this doesn't account for strides in the positioning
    assign x_continuous =(((y_min + 1 == y_max) && (x_end >= x_start)) || (y_min + 1 < y_max));
    
    // Starting work on TODO #3. This isn't currently used, but will be
    // necessary to jump Z-levels if we use an adder to get memory addresses.
    wire [15:0] image_channel_len;
    assign image_channel_len = image_dim * image_dim;
    
    // Since memory will take a cycle to get, we operate mostly on the _next_
    // value of xyz instead of the current value. 
    // This may cause timing issues with the blocker signals (untested).
    reg [7:0] next_x;
    reg [7:0] next_y;
    reg [8:0] next_z;

    // Usually we want to take image data straight from the memory, but
    // sometimes we want to be zeroed (when we're in the padding zone)
    reg data_padding;
    assign current_data = data_padding ? 0 : ramb_read_data;

    // Done detection
    always @(posedge clk) begin
        // Start off round is 0
        if (rst) begin
            round <= 1'b0;

        // When we hit the last XYZ, set round 1
        end else if (next_x == x_end && next_y == y_max && next_z == z_max) begin
            round <= 1'b1;

        // Else hold state
        end 
    end

    // Calculate the next XYZ position
    // Note: when I wrote this, it appears I was only adjusting for the simple
    // case of a 1x1 filter, when we'll mostly be using 3x3 and 5x5 filters.
    // There might be errors due to this assumption.
    always @(posedge clk) begin
        // Start off: x at the start column, y at the first row, z at layer 0
        if (rst) begin
            next_x <= x_start;
            next_y <= y_min;
            next_z <= 0;

        // if we're not reset, calculate the next value
        end else begin
            // If we're blocked, don't move
            if (block) begin
            
            // If it's a rectangle placement, follow the rectangle rules
            end else if (x_rectangle) begin
                // We wrap round from x_max to x_start
                // THIS IS BUGGY AND ONLY WORKS BECAUSE X_RECTANGLE IS NEVER ACTIVE
                // See TODO #1
                if (next_x == x_max) begin
                    if (next_z != z_max) begin
                        next_x <= x_start;
                        next_z <= next_z + 1;

                    // If we're at the last x on the last z-level, don't do anything
                    end
                end else begin
                    next_x <= next_x + 1;
                end

            // Continous placement -- once we hit the edge of the image, wrap
            // around and keep going
            end else if (x_continuous) begin
                // At the last pixel on the bottom row, go back to start and
                // go to the next z-level
                if (next_x == x_end && next_y == y_max) begin
                    if (next_z != z_max) begin
                        next_x <= x_start;
                        next_y <= y_min;
                        next_z <= next_z + 1;

                    // Except if we're at the last z-level, don't do anything
                    end

                // If we're on the image's rightmost edge, wrap around to the
                // left edge of the image
                end else if (next_x == x_max) begin
                    next_x <= x_min;
                    next_y <= next_y + 1;

                // Otherwise, just move along X
                end else begin
                    next_x <= next_x + 1;
                end

            // Jump placement -- If we hit the edge, wrap around. Or if we hit
            // the rightmost pixel in the left group, jump to the leftmost
            // pixel in the right group. 
            end else if (x_jump) begin
                // At the last pixel on the bottom row, go back to start and
                // go to the next z-level
                if (next_x == x_end && next_y == y_max) begin
                    if (next_z != z_max) begin
                        next_x <= x_start;
                        next_y <= y_min;
                        next_z <= next_z + 1;

                    // Except if we're at the last z-level, don't do anything
                    end

                // At the right edge of the image, go to the left edge of the 
                // image on the next row
                end else if (next_x == x_max) begin
                    next_x <= x_min;
                    next_y <= next_y + 1;

                // If we hit the right edge of the left group, jump to the
                // left edge of the right group
                end else if (next_x == x_end) begin
                    next_x <= x_start;

                // Otherwise, just move along X
                end else begin
                    next_x <= next_x + 1;
                end
            end
        end
    end

    // From next XYZ, get the memory address of the pixel to fetch from
    // memory.
    // Note the (* - image_padding) terms -- this has to do with us
    // translating the image in order to pad it with zeros. 
    assign ramb_read_addr = (image_dim * image_dim * next_z) + 
                            (image_dim * (next_y - image_padding)) + 
                            (next_x - image_padding);
    
    // Send the current XY signals to allocators
    // The allocators only need to know about X and Y, since it's guaranteed
    // that Z will be issued in-order.
    always @(posedge clk) begin
        // Start off sending nothing
        if (rst || round) begin
            current_x <= x_start;
            current_x <= y_min;
            en <= 1'b0;
        
        // Otherwise, current XY are the values of XY that are coming out of
        // memory right now
        end else begin
            current_x <= next_x;
            current_y <= next_y;
            en <= ~block;
        end
    end
    
    // Get current data from memory
    always @(posedge clk) begin
        // If we're within the padding zone, send a 0
        if (next_x < image_padding || 
            next_y < image_padding || 
            next_x >= image_dim + image_padding  || 
            next_y >= image_dim + image_padding
        ) begin
            data_padding <= 1;

        // Otherwise, send the value from memory
        end else begin
            data_padding <= 0;
        end
    end

endmodule
`endif // _include_image_broadcast_
