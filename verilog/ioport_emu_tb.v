`timescale 1ns / 1ns

`include "ioport_emu.v"

module main();
    reg clk;
    wire [39:0] data;

    initial begin
        clk = 1;
        //forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("ioport.vcd");
        $dumpvars(0, uut);
    end

    IoPortEmu #(
        .width_bytes(5)
    ) uut (
        .out(data)
    );
endmodule



