`ifndef _include_issue_positioner
`define _include_issue_positioner

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
        output wire        done,

        input  wire        clk,
        input  wire        rst
    );

    reg [7:0] allocator_counter;

    always @(posedge clk) begin
        if (rst) begin
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

    wire [7:0] next_x;
    assign next_x = (
        (center_y == image_dim - 1 + padding && center_x == image_dim - 1 + padding) ? 
            center_x 
        : (center_x == image_dim - 1 + padding) ?
            padding
        :
            center_x + stride
    );

    wire [7:0] next_y;
    assign next_y = (
        (center_x == image_dim - 1 + padding && center_y < image_dim - 1 + padding) ?
            center_y + stride
        : 
            center_y
    );

    assign done = (center_x == image_dim + padding) && (center_y == image_dim + padding);

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
        end else if (allocator_counter < num_allocators) begin
            center_x <= next_x;
            center_y <= next_y;
        end else if (allocator_counter == num_allocators) begin
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
