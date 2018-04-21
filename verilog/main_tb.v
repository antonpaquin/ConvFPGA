`include "logic.v"
`include "ioport_emu.v"

module main (
    );

    reg clk;
    reg rst;
    wire [23:0] bus;

    Logic uut (
        .master_bus(bus),
        .clk(clk),
        .rst(rst)
    );

    IoPortEmu #(
        .width_bytes(3)
    ) port (
        .out(bus)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #10 rst = 0;
    end

endmodule
