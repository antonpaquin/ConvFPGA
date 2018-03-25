`ifndef _include_dsp_emu_
`define _include_dsp_emu_

`define DSP_INSTRUCTION_CLR 2'b00
`define DSP_INSTRUCTION_MAC 2'b01
`define DSP_INSTRUCTION_ACC 2'b10
`define DSP_INSTRUCTION_NOP 2'b11

/* DSP Emulator
 * 
 * This is a model of the actual DSP48 macro implemented by Xilinx. Minimally,
 * the DSP should be able to execute these instructions, and it should have an
 * interface similar enough to this one that we can swap out this and the real
 * thing easily.
 *
 * Karan knows more about how the real module operates than I do.
 */
module DspEmu(
        input  wire [ 1:0] op, // The DSP opcode 
        input  wire [17:0] a, // INPUT A
        input  wire [17:0] b, // INPUT B
        input  wire [47:0] c, // INPUT C
        output reg  [47:0] p, // OUTPUT
        input  wire        clk
    );
    always @(posedge clk) begin
        case (op)
            `DSP_INSTRUCTION_CLR: p <= 0; // Clear operation -- sets OUTPUT to zero
            `DSP_INSTRUCTION_ACC: p <= p + c; // Accumulate -- increment P by C
            `DSP_INSTRUCTION_MAC: p <= p + (a*b); // Multiply and accumulate -- P += (A*B)
            `DSP_INSTRUCTION_NOP: p <= p; // No-op -- P should stay where it is
        endcase
        // This is a debug line so we can see MAC operations as they happen,
        // which will be good for debugging, but we might remove it if it gets spammy
        if (op == `DSP_INSTRUCTION_MAC) $display("MAC (%d * %d)", a, b);
    end

endmodule

`endif // _include_dsp_emu_
