`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:33:06 03/17/2018 
// Design Name: 
// Module Name:    Convolutor 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Convolutor(
	input clk,
	input rst
	);
	
	reg [17:0] image[0:3][0:3][0:2];		// 4x4x3 input image
	reg [17:0] filter[0:2][0:2][0:2];	// 3x3x3 kernel
	wire [47:0] conv00;					// 2x2 convoluted image, idx 0,0
	wire [47:0] conv01;					// 2x2 convoluted image, idx 0,1
	wire [47:0] conv10;					// 2x2 convoluted image, idx 1,0
	wire [47:0] conv11;					// 2x2 convoluted image, idx 1,1

	// row idx, col idx, depth idx of filter
	reg [1:0] frow;
	reg [1:0] fcol;
	reg [1:0] fdep;

	// row idx, col idx, depth idx of image
	reg [1:0] irow;
	reg [1:0] icol;
	reg [1:0] idep;
	
	// !!! hardcoded for 4x4x3 image
	wire dsp0_row_offset = 0;
	wire dsp0_col_offset = 0;
	wire dsp1_row_offset = 0;
	wire dsp1_col_offset = 1;
	wire dsp2_row_offset = 1;
	wire dsp2_col_offset = 0;
	wire dsp3_row_offset = 1;
	wire dsp3_col_offset = 1;

	// will calculate 0,0 of output
	MACC_MACRO #(
		.DEVICE("7SERIES"),
		.LATENCY(1),
		.WIDTH_A(18),
		.WIDTH_B(18),
		.WIDTH_P(48)
	) dsp0 (
		.P(conv00),
		.A(image[dsp0_row_offset+irow][dsp0_col_offset+icol][idep]),
		.ADDSUB(1'b1),
		.B(filter[frow][fcol][fdep]),
		.CARRYIN(1'b0),
		.CE(1'b1),
		.CLK(clk),
		.LOAD(1'b0),
		.LOAD_DATA(48'b0),
		.RST(rst)
	);
	
	// will calculate 0,1 of output
	MACC_MACRO #(
		.DEVICE("7SERIES"),
		.LATENCY(1),
		.WIDTH_A(18),
		.WIDTH_B(18),
		.WIDTH_P(48)
	) dsp1 (
		.P(conv01),
		.A(image[dsp1_row_offset+irow][dsp1_col_offset+icol][idep]),
		.ADDSUB(1'b1),
		.B(filter[frow][fcol][fdep]),
		.CARRYIN(1'b0),
		.CE(1'b1),
		.CLK(clk),
		.LOAD(1'b0),
		.LOAD_DATA(48'b0),
		.RST(rst)
	);

	// will calculate 1,0 of output
	MACC_MACRO #(
		.DEVICE("7SERIES"),
		.LATENCY(1),
		.WIDTH_A(18),
		.WIDTH_B(18),
		.WIDTH_P(48)
	) dsp2 (
		.P(conv10),
		.A(image[dsp2_row_offset+irow][dsp2_col_offset+icol][idep]),
		.ADDSUB(1'b1),
		.B(filter[frow][fcol][fdep]),
		.CARRYIN(1'b0),
		.CE(1'b1),
		.CLK(clk),
		.LOAD(1'b0),
		.LOAD_DATA(48'b0),
		.RST(rst)
	);
	
	// will calculate 1,1 of output
	MACC_MACRO #(
		.DEVICE("7SERIES"),
		.LATENCY(1),
		.WIDTH_A(18),
		.WIDTH_B(18),
		.WIDTH_P(48)
	) dsp3 (
		.P(conv11),
		.A(image[dsp3_row_offset+irow][dsp3_col_offset+icol][idep]),
		.ADDSUB(1'b1),
		.B(filter[frow][fcol][fdep]),
		.CARRYIN(1'b0),
		.CE(1'b1),
		.CLK(clk),
		.LOAD(1'b0),
		.LOAD_DATA(48'b0),
		.RST(rst)
	);
	
	// to ensure first values at posedge clk are 00
	always @ (rst) begin
		if (rst) begin
			frow <= 2'b00;
			irow <= 2'b00;
			
			fcol <= 2'b11;	
			icol <= 2'b11;
			
			fdep <= 2'b10;	
			idep <= 2'b10;
		end
	end
	
	// move the indices of image and filter to iterate over entire image and filter weights
	always @ (posedge clk) begin
	
		if (!rst) begin
		
			// increase dep idx for current row, col pair
			idep <= idep + 2'b1;
			fdep <= fdep + 2'b1;
			
			
			// reached last depth. increase col idx now. reset dep idx to 0
			if (idep==2'b10) begin	// idep and fdep will have same value
			
				icol <= icol + 2'b1;
				fcol <= fcol + 2'b1;
				idep <= 2'b00;
				fdep <= 2'b00;
				
				// reached last col. increase row idx now. reset col idx to 0
				if (icol==2'b10) begin	// icol and fcol will have same value
				
					irow <= irow + 2'b1;
					frow <= frow + 2'b1;
					icol <= 2'b00;
					fcol <= 2'b00;
					
					// reached last row. done with conv
					if (irow==2'b10) begin	// irow and frow will have same value
						irow <= 2'b00;
						frow <= 2'b00;
					end	// last row check
					
				end	// last col check
			
			end	// last dep check
		
		end	// rst check

	end	// always begin


	// manually set values for filter and image. later these should come from memory
	initial begin
		// set values in the 3x3x3 filter (random for now)	
		filter[0][0][0] <= 26;
		filter[0][0][1] <= 25;
		filter[0][0][2] <= 24;
		filter[0][1][0] <= 23;
		filter[0][1][1] <= 22;
		filter[0][1][2] <= 21;
		filter[0][2][0] <= 20;
		filter[0][2][1] <= 19;
		filter[0][2][2] <= 18;
		
		filter[1][0][0] <= 17;
		filter[1][0][1] <= 16;
		filter[1][0][2] <= 15;
		filter[1][1][0] <= 14;
		filter[1][1][1] <= 13;
		filter[1][1][2] <= 12;
		filter[1][2][0] <= 11;
		filter[1][2][1] <= 10;
		filter[1][2][2] <= 9;
		
		filter[2][0][0] <= 8;
		filter[2][0][1] <= 7;
		filter[2][0][2] <= 6;
		filter[2][1][0] <= 5;
		filter[2][1][1] <= 4;
		filter[2][1][2] <= 3;
		filter[2][2][0] <= 2;
		filter[2][2][1] <= 1;
		filter[2][2][2] <= 0;
		
		// set values in the 4x4x3 image (random for now)	
		image[0][0][0] <= 1;
		image[0][0][1] <= 1;
		image[0][0][2] <= 1;
		image[0][1][0] <= 1;
		image[0][1][1] <= 1;
		image[0][1][2] <= 1;
		image[0][2][0] <= 1;
		image[0][2][1] <= 1;
		image[0][2][2] <= 1;
		image[0][3][0] <= 1;
		image[0][3][1] <= 1;
		image[0][3][2] <= 1;

		image[1][0][0] <= 1;
		image[1][0][1] <= 1;
		image[1][0][2] <= 1;
		image[1][1][0] <= 1;
		image[1][1][1] <= 1;
		image[1][1][2] <= 1;
		image[1][2][0] <= 1;
		image[1][2][1] <= 1;
		image[1][2][2] <= 1;
		image[1][3][0] <= 1;
		image[1][3][1] <= 1;
		image[1][3][2] <= 1;

		image[2][0][0] <= 1;
		image[2][0][1] <= 1;
		image[2][0][2] <= 1;
		image[2][1][0] <= 1;
		image[2][1][1] <= 1;
		image[2][1][2] <= 1;
		image[2][2][0] <= 1;
		image[2][2][1] <= 1;
		image[2][2][2] <= 1;
		image[2][3][0] <= 1;
		image[2][3][1] <= 1;
		image[2][3][2] <= 1;

		image[3][0][0] <= 1;
		image[3][0][1] <= 1;
		image[3][0][2] <= 1;
		image[3][1][0] <= 1;
		image[3][1][1] <= 1;
		image[3][1][2] <= 1;
		image[3][2][0] <= 1;
		image[3][2][1] <= 1;
		image[3][2][2] <= 1;
		image[3][3][0] <= 1;
		image[3][3][1] <= 1;
		image[3][3][2] <= 1;
	end	// initial value setting

endmodule
