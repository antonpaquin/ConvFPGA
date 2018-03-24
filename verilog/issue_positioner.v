`ifndef _include_issue_positioner
`define _include_issue_positioner

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
module IssuePositioner #(
        parameter num_allocators = 220
    ) (
        input  wire [ 7:0] image_dim,
        input  wire [ 1:0] padding,
        input  wire [ 2:0] stride,

        output reg  [ 7:0] center_x,
        output reg  [ 7:0] center_y,
        output reg  [num_allocators-1:0] allocator_select,

        output reg  [ 7:0] x_min,
        output reg  [ 7:0] x_max,
        output reg  [ 7:0] x_start,
        output reg  [ 7:0] x_end,
        output reg  [ 7:0] y_min,
        output reg  [ 7:0] y_max,

        input  wire        advance,
        output reg         done,

        input  wire        clk,
        input  wire        rst
    );
    
    reg [7:0] allocator_counter;

    wire [7:0] position_bound;
    assign position_bound = image_dim - 1 + padding;

    always @(posedge clk) begin
        if (rst || done) begin
            allocator_select <= 0;
        end else if (allocator_counter == 0) begin
            allocator_select[num_allocators-1] <= 0;
            if (advance) begin
                allocator_select[allocator_counter] <= 1;
            end
        end else if (allocator_counter < num_allocators) begin
            allocator_select[allocator_counter] <= 1;
            allocator_select[allocator_counter-1] <= 0;
        end else if (allocator_counter == num_allocators) begin
            allocator_select[num_allocators-1] <= 0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            allocator_counter <= 0;
        end else if (allocator_counter == 0) begin
            if (advance) begin
                allocator_counter <= allocator_counter + 1;
            end
        end else if (allocator_counter < num_allocators) begin
            allocator_counter <= allocator_counter + 1;
        end else if (allocator_counter == num_allocators) begin
            allocator_counter <= 0;
        end
    end

    wire [7:0] advance_x;
    wire [7:0] advance_y;
    assign advance_x = center_x + stride;
    assign advance_y = center_y + stride;

    wire [7:0] next_x;
    assign next_x = (
        (advance_x >= position_bound && advance_y >= position_bound) ? 
            center_x 
        : (advance_x >= position_bound) ?
            padding
        :
            advance_x
    );

    wire [7:0] next_y;
    assign next_y = (
        (advance_x >= position_bound && advance_y < position_bound) ?
            advance_y
        : 
            center_y
    );

    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else if ((allocator_select != 0) && (advance_x >= position_bound) && (advance_y >= position_bound)) begin
            done <= 1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            center_x <= padding;
            center_y <= padding;
            x_start <= 0;
            x_end <= 0;
            y_min <= 0;
            y_max <= 0;
        end else if (allocator_counter == 0) begin
            if (advance) begin
                x_start <= center_x - padding;
                y_min <= center_y - padding;
            end
        end else if (allocator_counter <= num_allocators) begin
            center_x <= next_x;
            center_y <= next_y;
            x_end <= center_x + padding;
            y_max <= center_y + padding;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            x_min <= -1;
            x_max <= 0;
        end else if (allocator_counter == 0) begin
            if (advance) begin
                x_min <= center_x;
                x_max <= center_x;
            end
        end else if (allocator_counter <= num_allocators) begin
            if (center_x - padding < x_min) begin
                x_min <= center_x - padding;
            end
            if (center_x + padding > x_max) begin
                x_max <= center_x + padding;
            end
        end
    end
endmodule
`endif // _include_issue_positioner
