`ifndef _include_dsp_emu_
`define _include_dsp_emu_

`define DSP_INSTRUCTION_CLR 2'b00
`define DSP_INSTRUCTION_MAC 2'b01
`define DSP_INSTRUCTION_ACC 2'b10
`define DSP_INSTRUCTION_NOP 2'b11

module DspEmu(
        input  wire [ 1:0] op,
        input  wire [17:0] a,
        input  wire [17:0] b,
        input  wire [47:0] c,
        output reg  [47:0] p,
        input  wire        clk
    );
    always @(posedge clk) begin
        case (op)
            `DSP_INSTRUCTION_CLR: p <= 0;
            `DSP_INSTRUCTION_ACC: p <= p + c;
            `DSP_INSTRUCTION_MAC: p <= p + (a*b);
            `DSP_INSTRUCTION_NOP: p <= p;
        endcase
        if (op == `DSP_INSTRUCTION_MAC) $display("MAC (%d * %d)", a, b);
    end

endmodule

`endif // _include_dsp_emu_
