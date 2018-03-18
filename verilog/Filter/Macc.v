`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:18:18 03/17/2018 
// Design Name: 
// Module Name:    Macc 
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


// Applies a 3x3 filter (stride=1) over a 6x6x1 image
// Outputs 4x4 activation map
// Assumes multiplicands are 18 bits wide
module Macc(
	input clk,
	input rst,
	input [1:0] frow,
	input [1:0] fcol,
	input [1:0] fdep,
	input [17:0] image_pixel,

	output [47:0] activation
	);

	// the filter to be applied over image
	reg [17:0] filter[0:2][0:2][0:2];

	MACC_MACRO #(
		.DEVICE("7SERIES"), 	// Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6", "7SERIES"
		.LATENCY(1), 			// Desired clock cycle latency, 1-4
		.WIDTH_A(18), 			// Multiplier A-input bus width, 1-25
		.WIDTH_B(18), 			// Multiplier B-input bus width, 1-18
		.WIDTH_P(48) 			// Accumulator output bus width, 1-48
	) MACC_MACRO_inst (
		.P(activation), 					// MACC output bus, width determined by WIDTH_P parameter
		.A(image_pixel), 					// MACC input A bus, width determined by WIDTH_A parameter
		.ADDSUB(1'b1), 					// 1-bit add/sub input, high selects add, low selects subtract
		.B(filter[frow][fcol][fdep]), 					// MACC input B bus, width determined by WIDTH_B parameter
		.CARRYIN(1'b0), 					// 1-bit carry-in input to accumulator
		.CE(1'b1),					 // 1-bit active high input clock enable
		.CLK(clk),				 // 1-bit positive edge clock input
		.LOAD(1'b0), 			// 1-bit active high input load accumulator enable
		.LOAD_DATA(48'b0), // Load accumulator input data, width determined by WIDTH_P parameter
		.RST(rst) 				// 1-bit input active high reset
	);
	
	// set values in filter (random for now)
	initial begin
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
	end
	
endmodule
