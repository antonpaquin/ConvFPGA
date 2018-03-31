`ifndef _include_memory_
`define _include_memory_

/*
 * Memory is a model of the image memory we'll eventually use on our board. 
 * It's a fairly standard memory model.
 *
 * We're modeled off the xilinx RAM18 blocks, which store 1024 18-bit words
 * with 2 read signals and 2 write signals per cycle. Reading and writing from 
 * the same address in the same cycle is not supported. 
 *
 * Our Z7020 chips have 280 RAMB18's available, of which 220 are currently set
 * to DSPs (one per DSP). We could free up half of these by moving DSPs to
 * systolic filter data (see "systolics.txt").
 */
module Memory(
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
    
    // Allocate 60 Ramb18's
    localparam memsize = 60*1024;
    reg [17:0] memory [memsize-1:0];
    
    // Read signals are easy
    always @(posedge clk) read_data_a <= memory[read_addr_a];
    always @(posedge clk) read_data_b <= memory[read_addr_b];
    
    // Write signals write only when write_en is high
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
    
    // Initialization block: memory is initialized to 0 by default
    integer ii;
    initial begin
        for (ii=0; ii<memsize; ii=ii+1) begin
            memory[ii] = 0;
        end
    end

endmodule

`endif // _include_memory_
