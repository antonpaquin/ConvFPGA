`ifndef _include_ramb_emu_
`define _include_ramb_emu_

/* RAMB18 Emulator
 * 
 * This is a block RAM 18 emulator. In the final design, it should be replaced
 * with the real macro implemented by Xilinx. The idea is that this module
 * implements the same functionality, and their interfaces should be similar
 * enough that swapping them out is a trivial procedure.
 *
 * The RAMB18 stores 1k entries of 18-bit data, and provides 2 read lines and
 * 2 write lines per block.
 *
 * In the real thing, reading and writing to the same address in the same
 * cycle is not supported. Be warned.
 */
module Ramb18Emu(
        // Read signals -- every cycle, the output will be written with the
        // contents of the memory at the given address
        input  wire [ 9:0] read_addr,
        output reg  [17:0] read_data,

        // Write signals -- when write_en is high, the input data will be
        // written to the specified address.
        input  wire [ 9:0] write_addr,
        input  wire [17:0] write_data,
        input  wire        write_en,

        input  wire        clk
    );
    // Main memory of the emulated RAMB18
    reg [17:0] memory [1023:0];
    
    // Two independent write signals, which will each write an 18-bit value to
    // the appropriate address every cycle write_en is high
    always @(posedge clk) begin
        if (write_en) begin
            memory[write_addr] <= write_data;
            // This is a debug line, which we can uncomment to see memory
            // writes as they occur (in simulation).
            //$display("%d --> [%d]", write_data_a, write_addr_a);
        end
    end
    
    always @(posedge clk) read_data <= memory[read_addr];

endmodule

`endif // _include_ramb_emu_
