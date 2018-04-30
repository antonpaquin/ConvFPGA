
`timescale 1 ns / 1 ps

	module dataip2_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32,

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output reg [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,

		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid
	);
//// Instantiation of Axi Bus Interface M00_AXIS
//	dataip2_v1_0_M00_AXIS # ( 
//		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
//		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
//	) dataip2_v1_0_M00_AXIS_inst (
//		.start_outstream(slave_done),
//		.word_to_send(word_to_send),
//		.num_words_to_send(num_words_to_send),
//		.M_AXIS_ACLK(m00_axis_aclk),
//		.M_AXIS_ARESETN(m00_axis_aresetn),
//		.M_AXIS_TVALID(m00_axis_tvalid),
//		.M_AXIS_TDATA(m00_axis_tdata),
//		.M_AXIS_TSTRB(m00_axis_tstrb),
//		.M_AXIS_TLAST(m00_axis_tlast),
//		.M_AXIS_TREADY(m00_axis_tready)
//	);

// Instantiation of Axi Bus Interface S00_AXIS
	dataip2_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
	) dataip2_v1_0_S00_AXIS_inst (
		.done_reading(slave_done),
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid)
	);

	// Add user logic here
    wire slave_done;

	// data to be streamed out
	localparam NUMBER_OF_OUTPUT_WORDS = 32;
//	wire [4:0] num_words_to_send = NUMBER_OF_OUTPUT_WORDS;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0] words_to_send[0:NUMBER_OF_OUTPUT_WORDS-1];
	assign words_to_send[0] = 32'h1010101;
    assign words_to_send[1] = 32'h2020202;
    assign words_to_send[2] = 32'h3030303;
    assign words_to_send[3] = 32'h4040404;
    assign words_to_send[4] = 32'h5050505;
    assign words_to_send[5] = 32'h6060606;
    assign words_to_send[6] = 32'h7070707;
    assign words_to_send[7] = 32'h8080808;
    assign words_to_send[8] = 32'h9090909;
    assign words_to_send[9] = 32'ha0a0a0a;
    assign words_to_send[10] = 32'hb0b0b0b;
    assign words_to_send[11] = 32'hc0c0c0c;
    assign words_to_send[12] = 32'hd0d0d0d;
    assign words_to_send[13] = 32'he0e0e0e;
    assign words_to_send[14] = 32'hf0f0f0f;
    assign words_to_send[15] = 32'hdeadbeef;
    assign words_to_send[16] = 32'h1010101;
    assign words_to_send[17] = 32'h2020202;
    assign words_to_send[18] = 32'h3030303;
    assign words_to_send[19] = 32'h4040404;
    assign words_to_send[21] = 32'h5050505;
    assign words_to_send[22] = 32'h6060606;
    assign words_to_send[23] = 32'h7070707;
    assign words_to_send[24] = 32'h8080808;
    assign words_to_send[25] = 32'h9090909;
    assign words_to_send[26] = 32'ha0a0a0a;
    assign words_to_send[27] = 32'hb0b0b0b;
    assign words_to_send[28] = 32'hc0c0c0c;
    assign words_to_send[29] = 32'hd0d0d0d;
    assign words_to_send[30] = 32'he0e0e0e;
    assign words_to_send[31] = 32'hf0f0f0f;
    assign words_to_send[20] = 32'hdeadbeef;

//	reg [3:0] idx = 0;
//	reg [C_M00_AXIS_TDATA_WIDTH-1:0] word_to_send;
//	always @ (posedge m00_axis_aclk)
//	begin

//		if (!m00_axis_aresetn)
//		begin
//			word_to_send <= 0;
//			idx <= 0;
//		end
		
//		else
//		begin
//            if (slave_done)
//            begin
//                word_to_send <= words_to_send[idx];
//                idx <= idx + 1;
//            end	
//		end
	
//	end

    // module that emulates the convolution
    // take slave done as input
    // wait for 100 cycles
    // start outputting to master (turn send dta signal high)

/////////////////////////////////////////////////////////////////////////////////////////

	// // dummy signal, actually will be set as the convoluter module output
	// wire start_tx = ((counter & 63) == 0) && counter!=0;

	// reg [8:0] counter = 0;
	// always @ (posedge m00_axis_aclk)
	// begin
	// 	if (m00_axis_aresetn && m00_axis_tready)
	// 	begin
	// 		counter <= counter + 1;
	// 	end
	// 	else
	// 	begin
	// 		counter <= 0;
	// 	end
	// end

	wire start_tx = slave_done;

	localparam SENDING = 1;
	localparam IDLE = 0;

	reg [5:0] num_words_to_send = 32;
	reg [5:0] num_words_sent = 0;
	reg [4:0] pkt_size = 16;
	reg state;
	// wire tx_en;

	assign m00_axis_tvalid = (state == SENDING) && (num_words_sent <= num_words_to_send);
	assign m00_axis_tlast = ((num_words_sent & pkt_size-1) == 0) && (num_words_sent!=0);
	assign m00_axis_tstrb = {(C_M00_AXIS_TDATA_WIDTH/8){1'b1}};
	// assign tx_en = m00_axis_tready && (num_words_sent <= num_words_to_send) && state==SENDING;

	always @ (posedge m00_axis_aclk)
	begin
		
		if (!m00_axis_aresetn)
		begin
			state <= IDLE;
			num_words_sent <= 0;
		end

		else
		begin

			if (m00_axis_tready)
			begin
				case (state)
					
					IDLE:
					begin
						if (start_tx)
						begin
							state <= SENDING;
							m00_axis_tdata <= words_to_send[num_words_sent];
							num_words_sent <= num_words_sent + 1;
						end
					end
			
					SENDING:
					begin
						if (num_words_sent == num_words_to_send)
						begin
							state <= IDLE;
							num_words_sent <= 0;
						end
						else
						begin
							m00_axis_tdata <= words_to_send[num_words_sent];
							num_words_sent <= num_words_sent + 1;
						end
					end

				endcase // state
			end // m00_axis_tready

			else
			begin
				state <= IDLE;
				num_words_sent <= 0;	
			end
		
		end

	end

	// User logic ends

	endmodule
