`ifndef _include_issue_filter_
`define _include_issue_filter_

module IssueFilter #(
        parameter num_allocators = 220
    ) (
        output reg  [12:0] filter_issue_counter,
        output wire [17:0] filter_data,
        output reg         filter_en,
        input  wire [num_allocators-1:0] filter_block,

        input  wire [12:0] filter_length,
        
        output wire [15:0] filter_read_addr,
        input  wire [17:0] filter_read_data,

        output reg         done,

        input  wire        clk,
        input  wire        rst
    );

    reg [12:0] filter_issue_counter_next;
    reg        filter_en_next;

    assign filter_read_addr = {3'b0, filter_issue_counter_next};

    assign filter_blocked = |filter_block;

    assign filter_data = filter_read_data;

    always @(posedge clk) begin
        if (rst) begin
            filter_issue_counter_next <= 0;
            filter_en <= 0;
            done <= 0;
        
        end else if (done) begin

        end else if (filter_issue_counter_next == filter_length) begin
            filter_en <= 0;
            done <= 1;

        end else if (filter_blocked) begin
            filter_en <= 0;

        end else begin
            filter_en <= 1;
            filter_issue_counter_next <= filter_issue_counter_next + 1;

        end
    end

    always @(posedge clk) begin
        if (rst) begin
            filter_issue_counter <= 0;

        end else begin
            filter_issue_counter <= filter_issue_counter_next;

        end
    end

endmodule
`endif // _include_issue_filter_
