`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:39:04 03/17/2018
// Design Name:   Convolutor
// Module Name:   X:/Documents/Filter/tb_Convolutor.v
// Project Name:  Filter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Convolutor
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_Convolutor;

	// Inputs
	reg clk;
	reg rst;
	
	// Instantiate the Unit Under Test (UUT)
	Convolutor uut (
		.clk(clk), 
		.rst(rst)
	);

	always #1 clk = !clk;

	initial begin
		// Initialize Inputs
		clk = 1;
		rst = 1;

		// Wait 100 ns for global reset to finish
		#100 rst = 0;
        
	end
      
endmodule

