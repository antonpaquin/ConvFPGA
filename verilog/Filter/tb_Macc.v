`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:47:41 03/17/2018
// Design Name:   Macc
// Module Name:   X:/Documents/Filter/tb_Macc.v
// Project Name:  Filter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Macc
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_Macc;

	// Inputs
	reg clk;
	reg rst;

	// row idx, col idx, depth idx of filter
	reg [1:0] frow;
	reg [1:0] fcol;
	reg [1:0] fdep;

	// row idx, col idx, depth idx of image
	reg [1:0] irow;
	reg [1:0] icol;
	reg [1:0] idep;

	// the image to be convolved
	reg [17:0] image[0:3][0:3][0:2];
	
	// current pixel of image to be used to multiply with filter weight 
	wire [17:0] image_pixel = image[irow][icol][idep];

	// Outputs
	wire [47:0] activation;

	// Instantiate the Unit Under Test (UUT)
	Macc uut (
		.clk(clk), 
		.rst(rst), 
		.frow(frow),
		.fcol(fcol),
		.fdep(fdep),
		.image_pixel(image_pixel),
		.activation(activation)
	);

	always #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;

		// assigning random values to image matrix
		image[0][0][0] = 0;
		image[0][0][1] = 1;
		image[0][0][2] = 2;
		image[0][1][0] = 3;
		image[0][1][1] = 4;
		image[0][1][2] = 5;
		image[0][2][0] = 6;
		image[0][2][1] = 7;
		image[0][2][2] = 8;
		image[0][3][0] = 6;
		image[0][3][1] = 7;
		image[0][3][2] = 8;
		
		image[1][0][0] = 9;
		image[1][0][1] = 10;
		image[1][0][2] = 11;
		image[1][1][0] = 12;
		image[1][1][1] = 13;
		image[1][1][2] = 14;
		image[1][2][0] = 15;
		image[1][2][1] = 16;
		image[1][2][2] = 17;
		image[1][3][0] = 15;
		image[1][3][1] = 16;
		image[1][3][2] = 17;
		
		image[2][0][0] = 18;
		image[2][0][1] = 19;
		image[2][0][2] = 20;
		image[2][1][0] = 21;
		image[2][1][1] = 22;
		image[2][1][2] = 23;
		image[2][2][0] = 24;
		image[2][2][1] = 25;
		image[2][2][2] = 26;
		image[2][3][0] = 24;
		image[2][3][1] = 25;
		image[2][3][2] = 26;
		
		image[3][0][0] = 18;
		image[3][0][1] = 19;
		image[3][0][2] = 20;
		image[3][1][0] = 21;
		image[3][1][1] = 22;
		image[3][1][2] = 23;
		image[3][2][0] = 24;
		image[3][2][1] = 25;
		image[3][2][2] = 26;
		image[3][3][0] = 24;
		image[3][3][1] = 25;
		image[3][3][2] = 26;
		
		// Wait 100 ns for global reset to finish
		#100 rst = 0;

	end
	
	// to ensure first values at posedge clk are 00
	always @ (rst) begin
		if (rst) begin
			frow <= 2'b11;
			irow <= 2'b11;
			fcol <= 2'b11;	
			icol <= 2'b11;
			fdep <= 2'b10;	
			idep <= 2'b10;
		end
	end


	// move the filter
	always @ (posedge clk) begin
	
		if (!rst) begin
		
			// increase dep idx for current row, col pair
			idep <= idep + 2'b1;
			fdep <= fdep + 2'b1;
			
			
			// reached last depth. increase col idx now. reset dep idx to 0
			if (idep==2'b10) begin
			
				icol <= icol + 2'b1;
				fcol <= fcol + 2'b1;
				idep <= 2'b00;
				fdep <= 2'b00;
				
				// reached last col. increase row idx now. reset col idx to 0
				if (icol==2'b11) begin
				
					irow <= irow + 2'b1;
					frow <= frow + 2'b1;
					icol <= 2'b00;
					fcol <= 2'b00;
					
					// reached last row. done with conv
					if (irow==2'b11) begin
						irow <= 2'b00;
						frow <= 2'b00;
					end	// last row check
					
				end	// last col check
			
			end	// last dep check
		
		end	// rst check

	end	// always begin
	



	always @ (posedge clk) begin
	
		if (!rst) begin
		
			// increase dep idx for current row, col pair
			idep <= idep + 2'b1;
			fdep <= fdep + 2'b1;
			
			
			// reached last depth. increase col idx now. reset dep idx to 0
			if (idep==2'b10) begin
			
				icol <= icol + 2'b1;
				fcol <= fcol + 2'b1;
				idep <= 2'b00;
				fdep <= 2'b00;
				
				// reached last col. increase row idx now. reset col idx to 0
				if (icol==2'b11) begin
				
					irow <= irow + 2'b1;
					frow <= frow + 2'b1;
					icol <= 2'b00;
					fcol <= 2'b00;
					
					// reached last row. done with conv
					if (irow==2'b11) begin
						irow <= 2'b00;
						frow <= 2'b00;
					end	// last row check
					
				end	// last col check
			
			end	// last dep check
		
		end	// rst check

	end	// always begin
      
endmodule

