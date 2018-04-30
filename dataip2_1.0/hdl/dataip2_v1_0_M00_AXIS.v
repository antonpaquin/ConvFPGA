
`timescale 1 ns / 1 ps

	module dataip2_v1_0_M00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input wire start_outstream,
        input wire [C_M_AXIS_TDATA_WIDTH-1:0] word_to_send,
        input wire [4:0] num_words_to_send,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);
	// Total number of output data                                                 
//	localparam NUMBER_OF_OUTPUT_WORDS = 8;                                               
	                                                                                     
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	// function integer clogb2 (input integer bit_depth);                                   
	//   begin                                                                              
	//     for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
	//       bit_depth = bit_depth >> 1;                                                    
	//   end                                                                                
	// endfunction                                                                          
	                                                                                                   
	// bit_num gives the minimum number of bits needed to address 'depth' size of FIFO.  
	// localparam bit_num  = clogb2(NUMBER_OF_OUTPUT_WORDS);                                
	localparam bit_num = 4;

	// Define the states of state machine                                                
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO                                      
	parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state               
	                                                                                     
	                INIT_COUNTER  = 2'b01, // This state initializes the counter, once   
	                                // the counter reaches C_M_START_COUNT count,        
	                                // the state machine changes state to SEND_STREAM     
	                SEND_STREAM   = 2'b10; // In this state the                          
	                                     // stream data is output through M_AXIS_TDATA   
	// State variable                                                                    
	reg [1:0] mst_exec_state;                                                            
	// Example design FIFO read pointer                                                  
	reg [bit_num-1:0] read_pointer;                                                      
	reg [bit_num-1:0] word_idx;                                                      

//	// data to be streamed out
//	wire [C_M_AXIS_TDATA_WIDTH-1:0] words_to_send[0:NUMBER_OF_OUTPUT_WORDS-1];
//	assign words_to_send[0] = 32'h1010101;
//	assign words_to_send[1] = 32'h2020202;
//	assign words_to_send[2] = 32'h3030303;
//	assign words_to_send[3] = 32'h4040404;
//	assign words_to_send[4] = 32'h5050505;
//	assign words_to_send[5] = 32'h6060606;
//	assign words_to_send[6] = 32'h7070707;
//	assign words_to_send[7] = 32'h8080808;

	// AXI Stream internal signals
	//streaming data valid
	wire  	axis_tvalid;
	//streaming data valid delayed by one clock cycle
	reg  	axis_tvalid_delay;
	//Last of the streaming data 
	wire  	axis_tlast;
	//Last of the streaming data delayed by one clock cycle
	reg  	axis_tlast_delay;
	wire  	tx_en;
	//The master has issued all the streaming data stored in FIFO
	reg  	tx_done;


	// I/O Connections assignments

	assign M_AXIS_TVALID= axis_tvalid_delay;
	assign M_AXIS_TDATA	= word_to_send;
	assign M_AXIS_TLAST	= axis_tlast_delay;
	assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};


	// Control state machine implementation                             
	always @(posedge M_AXIS_ACLK)                                             
	begin                                                                     
		
		if (!M_AXIS_ARESETN)                                                    
		begin                                                                 
			mst_exec_state <= IDLE;                                             
	    end                                                                   
		
		else
		begin

		  	case (mst_exec_state)

		  		IDLE:
		  		begin
		  			if (start_outstream)
		  			begin
		  				mst_exec_state <= SEND_STREAM;
		  			end
		  			else
		  			begin
		  				mst_exec_state <= IDLE;
		  			end
		  		end

		  		SEND_STREAM:
		  		begin
		  			if (tx_done)
		  			begin
		  				mst_exec_state <= IDLE;
		  			end
		  			else
		  			begin
		  				mst_exec_state <= SEND_STREAM;	
		  			end

		  		end

		  	endcase

		end

	end                                                                       

	//tvalid generation
	//axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	//number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	assign axis_tvalid = ((mst_exec_state == SEND_STREAM) && (word_idx < num_words_to_send));
	                                                                                               
	// AXI tlast generation                                                                        
	// axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
	// (0 to NUMBER_OF_OUTPUT_WORDS-1)                                                             
	assign axis_tlast = (word_idx == num_words_to_send-1);                                
	                                                                                               
	                                                                                               
	// Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	// to match the latency of M_AXIS_TDATA                                                        
	always @(posedge M_AXIS_ACLK)                                                                  
	begin                                                                                          
	  if (!M_AXIS_ARESETN)                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= 1'b0;                                                               
	      axis_tlast_delay <= 1'b0;                                                                
	    end                                                                                        
	  else                                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= axis_tvalid;                                                        
	      axis_tlast_delay <= axis_tlast;                                                          
	    end                                                                                        
	end                                                                                            


	//read_pointer pointer

	always@(posedge M_AXIS_ACLK)                                               
	begin                                                                            
	  if(!M_AXIS_ARESETN)                                                            
	    begin                                                                        
	      tx_done <= 1'b0;                                                           
	      word_idx <= 0;                                                         
	    end                                                                          
	  else                                                                           
	    if (word_idx <= num_words_to_send-1)                                
	      begin                                                                      
	        if (tx_en)                                                               
	          // read pointer is incremented after every read from the FIFO          
	          // when FIFO read signal is enabled.                                   
	          begin                                                                  
	            word_idx <= word_idx + 1;                                    
	            tx_done <= 1'b0;                                                     
	          end                                                                    
	      end                                                                        
	    else if (word_idx == num_words_to_send)                             
	      begin                                                                      
	        // tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
	        // has been out.                                                         
	        tx_done <= 1'b1;                                                         
	      end                                                                        
	end                                                                              


	//FIFO read enable generation 

	assign tx_en = M_AXIS_TREADY && axis_tvalid;                                                

	// Add user logic here

	// User logic ends

	endmodule
