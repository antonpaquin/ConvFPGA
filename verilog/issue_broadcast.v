`ifndef _include_issue_broadcast_
`define _include_issue_broadcast_

// Issue Broadcast -- Given some bounds + memory access, reads values from
// memory in order, returning X coords, Y coords, and the pixel weight
module IssueBroadcast(
        output wire [15:0] ramb_read_addr,
        input  wire [17:0] ramb_read_data,

        input  wire [ 7:0] image_dim,
        input  wire [ 8:0] image_depth,
        input  wire [ 1:0] image_padding,
        
        input  wire [ 7:0] x_min,
        input  wire [ 7:0] x_max,
        input  wire [ 7:0] x_start,
        input  wire [ 7:0] x_end,
        input  wire [ 7:0] y_min,
        input  wire [ 7:0] y_max,

        input  wire        issue_block,
        output reg         issue_en,

        output reg  [ 7:0] current_x,
        output reg  [ 7:0] current_y,
        output reg  [17:0] current_data,

        output reg         done,

        input  wire        clk,
        input  wire        rst
    );

    // "Styles" of allocation -- governing wraparound cases, which are
    // explained better per wire
    wire x_continuous;
    wire x_jump;
    wire x_rectangle;

    // Rectangle means the entire allocation is on one row
    assign x_rectangle = (y_min == y_max);

    // Jump means it spans two lines, but the wraparound doesn't go all
    // the way to the start of the previous row
    assign x_jump = ((y_min + 1 == y_max) && (x_end < x_start));

    // Continous means it spans 2+ lines and the wraparound connects, meaning
    // the addressed space is continous
    assign x_continuous =(((y_min + 1 == y_max) && (x_end >= x_start)) || (y_min + 1 < y_max));

    wire [15:0] image_channel_len;
    assign image_channel_len = image_dim * image_dim;

    reg [7:0] next_x;
    reg [7:0] next_y;
    reg [8:0] next_z;

    always @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
        end else if (next_x == x_end && next_y == y_max && next_z == image_depth) begin
            done <= 1'b1;
        end 
    end

    // Controls next read position
    always @(posedge clk) begin
        if (rst) begin
            next_x <= x_start;
            next_y <= y_min;
            next_z <= 0;
        end else begin
            if (issue_block) begin
            end else if (x_rectangle) begin
                if (next_x == x_max) begin
                    if (next_z != image_depth) begin
                        next_x <= x_start;
                        // For block issue, y never changes
                        next_z <= next_z + 1;
                    end
                end else begin
                    next_x <= next_x + 1;
                end
            end else if (x_continuous) begin
                if (next_x == x_end && next_y == y_max) begin
                    if (next_z != image_depth) begin
                        next_x <= x_start;
                        next_y <= y_min;
                        next_z <= next_z + 1;
                    end
                end else if (next_x == x_max) begin
                    next_x <= x_min;
                    next_y <= next_y + 1;
                end else begin
                    next_x <= next_x + 1;
                end
            end else if (x_jump) begin
                if (next_x == x_end && next_y == y_max) begin
                    if (next_z != image_depth) begin
                        next_x <= x_start;
                        next_y <= y_min;
                        next_z <= next_z + 1;
                    end
                end else if (next_x == x_max) begin
                    next_x <= x_start;
                    next_y <= y_max;
                end else if (next_x == x_end) begin
                    next_x <= x_start;
                end
            end
        end
    end

    // TODO: this is a bit of a hack, there's a fast way to do it properly
    // outside the scope of this margin
    assign ramb_read_addr = (image_dim * image_dim * next_z) + 
                            (image_dim * (next_y - image_padding)) + 
                            (next_x - image_padding);

    always @(posedge clk) begin
        if (rst || done) begin
            current_x <= x_start;
            current_x <= y_min;
            issue_en <= 1'b0;
        end else begin
            current_x <= next_x;
            current_y <= next_y;
            issue_en <= ~issue_block;
        end
    end
    
    always @(posedge clk) begin
        if (next_x < image_padding || 
            next_y < image_padding || 
            next_x >= image_dim + image_padding  || 
            next_y >= image_dim + image_padding
        ) begin
            current_data <= 0;
        end else begin
            current_data <= ramb_read_data;
        end
    end

endmodule
`endif // _include_issue_broadcast_
