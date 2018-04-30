`timescale 1 ns / 1 ps

module tb_dataip2_v1_0;

	localparam C_M00_AXIS_TDATA_WIDTH = 32;
	localparam C_S00_AXIS_TDATA_WIDTH = 32;

	reg clk;
	reg rstn;

	// Ports of Axi Master Bus Interface M00_AXIS
	wire  m00_axis_tvalid;
	wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata;
	wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb;
	wire  m00_axis_tlast;
	reg  m00_axis_tready;

	// Ports of Axi Slave Bus Interface S00_AXIS
	wire  s00_axis_tready;
	reg [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata;
	reg [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb;
	reg  s00_axis_tlast;
	reg  s00_axis_tvalid;


	dataip2_v1_0 uut (

		.m00_axis_aclk(clk),
		.m00_axis_aresetn(rstn),
		.m00_axis_tvalid(m00_axis_tvalid),
		.m00_axis_tdata(m00_axis_tdata),
		.m00_axis_tstrb(m00_axis_tstrb),
		.m00_axis_tlast(m00_axis_tlast),
		.m00_axis_tready(m00_axis_tready),

		// Ports of Axi Slave Bus Interface S00_AXIS
		.s00_axis_aclk(clk),
		.s00_axis_aresetn(rstn),
		.s00_axis_tready(s00_axis_tready),
		.s00_axis_tdata(s00_axis_tdata),
		.s00_axis_tstrb(s00_axis_tstrb),
		.s00_axis_tlast(s00_axis_tlast),
		.s00_axis_tvalid(s00_axis_tvalid)

	);


	always #1 clk = !clk;

	initial begin

		$dumpfile("dataip2_v1_0.vcd");
		// $dumpvars(0, uut, uut.storage[0], uut.storage[1], uut.storage[2], uut.storage[3],
		// 					uut.storage[4], uut.storage[5], uut.storage[6], uut.storage[7],
		// 					uut.storage[8], uut.storage[9], uut.storage[10], uut.storage[11],
		// 					uut.storage[12], uut.storage[13], uut.storage[14], uut.storage[15]);
		$dumpvars(0, uut);

		clk = 1;
		rstn = 0;
		s00_axis_tvalid = 0;
		s00_axis_tlast = 0;
		// uut.storage[0] = 1;
		// uut.storage[1] = 2;
		// uut.storage[2] = 3;
		// uut.storage[3] = 4;
		// uut.storage[4] = 5;
		// uut.storage[5] = 6;
		// uut.storage[6] = 7;
		// uut.storage[7] = 8;

		#10;
		rstn = 1;
		// uut.writes_done = 1;
		// uut.m00_start_outstream = 1;

		m00_axis_tready = 0;
		s00_axis_tvalid = 1;

		s00_axis_tdata = 1;
		#2 s00_axis_tdata = 2;
		#2 s00_axis_tdata = 3;
		#2 s00_axis_tdata = 4;
		#2 s00_axis_tdata = 5;
		#2 s00_axis_tdata = 6;
		#2 s00_axis_tdata = 7;
		#2 s00_axis_tdata = 8;
		#2 s00_axis_tdata = 9;
		#2 s00_axis_tdata = 10;
		#2 s00_axis_tdata = 11;
		#2 s00_axis_tdata = 12;
		#2 s00_axis_tdata = 13;
		#2 s00_axis_tdata = 14;
		#2 s00_axis_tdata = 15;
		#2 s00_axis_tdata = 16;
		s00_axis_tlast = 1;

		#2 s00_axis_tlast = 0;
		s00_axis_tvalid = 0;

		#8 m00_axis_tready = 1;
		// #64 uut.start_tx = 0;

		#500;
		$finish;

	end


endmodule
