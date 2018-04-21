`include "logic.v"
`include "ioport_emu.v"

module main (
    );

    reg clk;
    reg rst;
    wire [23:0] bus_ext;
    reg  [23:0] bus_int;
    
    reg bus_switched;

    Logic uut (
        .master_bus(bus_int),
        .clk(clk),
        .rst(rst)
    );

    IoPortEmu #(
        .width_bytes(3)
    ) port (
        .out(bus_ext)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (bus_switched) begin
            bus_int <= bus_ext;
            bus_switched <= 0;
        end
    end

    always @(posedge bus_ext[23]) begin
        bus_switched <= 1;
    end

    initial begin
        rst = 1;
        #10 rst = 0;
    end

endmodule
