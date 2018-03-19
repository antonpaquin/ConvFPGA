`ifndef _include_allocator_controller_
`define _include_allocator_controller_

module AllocatorController #(
        parameter filter_leak = 0
    )(
        input  wire [ 7:0] issue_a_x,
        input  wire [ 7:0] issue_a_y,
        input  wire [17:0] issue_a_data,
        input  wire        issue_a_blocked,

        output reg  [12:0] issue_a_alloc_counter,
        input  wire [12:0] issue_a_dsp_counter,
        output reg         issue_a_block,

        input  wire [17:0] filter_data,
        input  wire        filter_blocked,

        input  wire [12:0] filter_issue_counter,
        input  wire [12:0] filter_dsp_counter,
        output reg         filter_block,

        input  wire [ 7:0] center_x_input,
        input  wire [ 7:0] center_y_input,
        input  wire        center_write_enable,

        input  wire [ 2:0] filter_dim,
        input  wire [17:0] filter_bias,
        input  wire [12:0] filter_length,

        output reg         ramb_a_write_en,
        output reg  [17:0] ramb_a_data,
        output reg  [ 9:0] ramb_a_addr,

        output reg         ramb_b_write_en,
        output reg  [17:0] ramb_b_data,
        output reg  [ 9:0] ramb_b_addr,

        output reg         result_ready,
        output reg  [17:0] result_data,

        input  wire        clk,
        input  wire        rst
    );

    reg [7:0] center_x;
    reg [7:0] center_y;

    wire [1:0] filter_halfsize;
    assign filter_halfsize = (filter_dim == 3) ? 1 : 2;

    wire issue_a_xrange;
    wire issue_a_yrange;
    wire issue_a_en;

    // Tracks if the issue_a_x value is within the bounds of center_x +- filter_halfsize 
    assign issue_a_xrange = (
        (issue_a_x >= center_x - filter_halfsize) &&
        (issue_a_x <= center_x + filter_halfsize)
    ) ? 1'b1 : 1'b0;
    assign issue_a_yrange = (
        (issue_a_y >= center_y - filter_halfsize) &&
        (issue_a_y <= center_y + filter_halfsize)
    ) ? 1'b1 : 1'b0;
    
    // If we're in range of both X and Y, then we need to read the issue
    assign issue_a_en = (issue_a_xrange && issue_a_yrange);

    always @(posedge clk) begin
        if (rst) begin
            issue_a_alloc_counter <= 0;
            ramb_a_write_en <= 0;
            issue_a_block <= 0;
        end else if (issue_a_en && !issue_a_blocked) begin
            // TODO: check if issue_a_alloc_counter and issue_a_dsp_counter
            // imply that we should block issue (i.e. if reading a new value
            // into ramb would overwrite a value that the DSP hasn't been able
            // to process yet
            // TODO: same with filter
            ramb_a_write_en <= 1;
            ramb_a_addr <= {1'b0, issue_a_alloc_counter[8:0]};
            ramb_a_data <= issue_a_data;
            issue_a_alloc_counter <= issue_a_alloc_counter + 1;
        end else begin
            ramb_a_write_en <= 0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            filter_block <= 0;
            ramb_b_write_en <= 0;
        end else if (!filter_blocked) begin
            ramb_b_write_en <= 1;
            ramb_b_addr <= {1'b1, filter_issue_counter[8:0]};
            ramb_b_data <= filter_data;
        end else begin
            ramb_b_write_en <= 0;
        end
    end

    // Assign center x and y on enable
    always @(posedge clk) begin
        if (center_write_enable) begin
            center_x <= center_x_input;
            center_y <= center_y_input;
        end
    end
    
    // Debug block -- remove for synthesis
    always @(posedge clk) begin
        if (center_x < filter_halfsize || center_x + filter_halfsize < center_x || 
            center_y < filter_halfsize || center_y + filter_halfsize < center_y) begin
            $display("Param error: Assigned an allocator to (%d, %d). Allowable range is (%d, %d) to (%d, %d).",
                center_x, center_y, filter_halfsize, filter_halfsize, -filter_halfsize, -filter_halfsize);
            $display("If you're sending an image, you need to pad it with 0's manually in the issue stage");
        end
    end
endmodule

 `endif // _include_allocator_controller_
