`ifndef _include_issue_mem_
`define _include_issue_mem_

module IssueMemory(
        input  wire [15:0] read_addr_a,
        output reg  [17:0] read_data_a,

        input  wire [15:0] read_addr_b,
        output reg  [17:0] read_data_b,

        input  wire [15:0] write_addr_a,
        input  wire [17:0] write_data_a,
        input  wire        write_en_a,

        input  wire [15:0] write_addr_b,
        input  wire [17:0] write_data_b,
        input  wire        write_en_b,
        
        input  wire        clk
    );
    reg [17:0] memory [60*1024];

    always @(posedge clk) read_data_a <= memory[read_addr_a];
    always @(posedge clk) read_data_b <= memory[read_addr_b];

    always @(posedge clk) begin
        if (write_en_a) begin
            memory[write_addr_a] <= write_data_a;
        end
    end

    always @(posedge clk) begin
        if (write_en_b) begin
            memory[write_addr_b] <= write_data_b;
        end
    end
endmodule

`endif // _include_issue_mem_
