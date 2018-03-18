`ifndef _include_dsp_controller_
`define _include_dsp_controller_

`include "dsp_emu.v"

module DspController(
        output reg  [ 9:0] ramb_a_addr,
        input  wire [17:0] ramb_a_data,
        output reg  [ 9:0] ramb_b_addr,
        input  wire [17:0] ramb_b_data,

        input  wire [12:0] issue_a_alloc_counter,
        output reg  [12:0] issue_a_dsp_counter,

        input  wire [12:0] filter_issue_counter,
        output reg  [12:0] filter_dsp_counter,

        output wire [47:0] result,

        input  wire        clk,
        input  wire        rst
    );

    reg [ 1:0] dsp_op;
    reg [ 1:0] dsp_op_next;

    always @(posedge clk) begin
        if (rst) begin
            issue_a_dsp_counter <= 0;
            filter_dsp_counter <= 0;
            dsp_op_next <= `DSP_INSTRUCTION_CLR; 
        end else if ((issue_a_alloc_counter > issue_a_dsp_counter) && (filter_issue_counter > filter_dsp_counter)) begin
            ramb_a_addr <= {1'b0, issue_a_dsp_counter[8:0]};
            ramb_b_addr <= {1'b1, filter_dsp_counter[8:0]};
            issue_a_dsp_counter <= issue_a_dsp_counter + 1;
            filter_dsp_counter <= filter_dsp_counter + 1;
            dsp_op_next <= `DSP_INSTRUCTION_MAC;
        end else begin
            dsp_op_next <= `DSP_INSTRUCTION_NOP;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            dsp_op <= `DSP_INSTRUCTION_CLR;
        end else begin
            dsp_op <= dsp_op_next;
        end
    end

    DspEmu dsp (
        .op(dsp_op),
        .a(ramb_a_data),
        .b(ramb_b_data),
        .c(48'b0),
        .p(result),
        .clk(clk)
    );
endmodule

`endif // _include_dsp_controller_
