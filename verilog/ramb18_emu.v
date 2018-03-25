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
        input  wire [ 9:0] read_addr_a,
        output reg  [17:0] read_data_a,

        input  wire [ 9:0] read_addr_b,
        output reg  [17:0] read_data_b,
        
        // Write signals -- when write_en is high, the input data will be
        // written to the specified address.
        input  wire [ 9:0] write_addr_a,
        input  wire [17:0] write_data_a,
        input  wire        write_en_a,

        input  wire [ 9:0] write_addr_b,
        input  wire [17:0] write_data_b,
        input  wire        write_en_b,

        input  wire        clk
    );
    // Main memory of the emulated RAMB18
    reg [17:0] memory [1023:0];
    
    // Two independent write signals, which will each write an 18-bit value to
    // the appropriate address every cycle write_en is high
    always @(posedge clk) begin
        if (write_en_a) begin
            memory[write_addr_a] <= write_data_a;
            // This is a debug line, which we can uncomment to see memory
            // writes as they occur (in simulation).
            //$display("%d --> [%d]", write_data_a, write_addr_a);
        end
    end
    
    always @(posedge clk) begin
        if (write_en_b) begin
            memory[write_addr_b] <= write_data_b;
            //$display("%d --> [%d]", write_data_b, write_addr_b);
        end
    end
    
    // The RAMB18 can read from 2 addresses per cycle
    always @(posedge clk) read_data_a <= memory[read_addr_a];
    always @(posedge clk) read_data_b <= memory[read_addr_b];

endmodule

`endif // _include_ramb_emu_
