`timescale 1ns / 1ns

`include "issue.v"
`include "memory.v"

/* Issue Test Bench
 * 
 * This test bench shows the progression of the "issue" module, by printing
 * out the results of positioning and broadcast as they happen. This makes
 * debugging a lot more intuitive than looking at waveforms, but it requires
 * the ability to compile a verilog file with iverilog. Install iverilog and
 * use the included makefile ("make issue").
 * 
 *
 */

// You can set this if you like -- it makes simulation faster by only
// redrawing lines that have been updated
// Comment out if you suspect it is causing issues
//`define go_fast

module main();
    // SIMULATION PARAMS
    // You should set these based on exactly what you want to test
    
    // The number of allocators to simulate
    localparam num_allocators  = 220;

    // The dimensions (width and height are the same) of the testing image
    localparam image_dim = 46;
    reg [7:0] image_width = image_dim;

    // Number of channels in the image. Beyond testing for a few low numbers,
    // there's not much logic that goes on with this value, so it's not
    // important to test the very deep channels we use.
    // It might be prudent to make sure we can go past 256.
    reg [8:0] image_depth = 9'd3;

    // Defining the filter: halfsize 1 corresponds to a 3x3, 2 to a 5x5, 3 to
    // a 7x7, etc.
    reg [1:0] filter_halfsize = 2'd1;
    // Stride -- how many steps to take between filter instances
    // We'll eventually use one case of a stride 4 filter in the input layer, 
    // and stride 1 otherwise
    reg [2:0] filter_stride = 3'd1;

    // END SIMULATION PARAMS

    reg clk, rst;

    // What pixel is currently being issued
    wire [7:0] issue_x, 
               issue_y;
    // And is the issue currently active
    wire       issue_en;

    // Connection to main memory
    wire [15:0] imem_read_addr;
    wire [17:0] imem_read_data;

    // What pixel is the center of the current positioner signal
    wire [7:0] positioner_x,
               positioner_y;
    // And what allocator is currently being positioned
    wire [num_allocators-1:0] positioner_select;
    
    // Done when the entire thing completes
    wire issue_done;
    

    // Memory unit -- an issue stage takes 1 read signal from main memory
    Memory memory (
        .read_addr_a(imem_read_addr),
        .read_data_a(imem_read_data)
        
        // We don't need the rest of these signals for this test
        //.read_addr_b(),
        //.read_data_b(),

        //.write_addr_a(),
        //.write_data_a(),
        //.write_en_a(),

        //.write_addr_b(),
        //.write_data_b(),
        //.write_en_b(),
    );

    // Our issue stage, which could eventually be exposed above
    Issue #(
        .num_allocators(num_allocators)
    ) uut (
        // Issue needs access to memory, even if it's all zeroed for the test
        .imem_read_addr(imem_read_addr),
        .imem_read_data(imem_read_data),
        
        // "constant" image params that need to be sent to Issue
        .image_dim(image_width),
        .image_depth(image_depth),

        // "constant" filter params
        .filter_halfsize(filter_halfsize),
        .filter_stride(filter_stride),
        
        // Describe where the issue broadcast is currently operating
        .issue_x(issue_x),
        .issue_y(issue_y),
        //.issue_data(), // For this sim, we're ignoring the data
        .issue_en(issue_en),
        
        // For this sim, no allocators will ever block issue. I'd like to test
        // this with some allocators actually hooked up, so we can get
        // realistic block signal testing.
        .issue_block({num_allocators{1'b0}}),

        // Where is the positioner currently operating, and what allocator is
        // it positioning?
        .positioner_x(positioner_x),
        .positioner_y(positioner_y),
        .positioner_select(positioner_select),
        
        // "done" when the entire filter is done
        .done(issue_done),

        .clk(clk),
        .rst(rst)
    );
    
    // Start with a 10-count reset signal
    initial begin
        rst = 1;
        #10 rst = 0;
    end
    
    // Oscillate clock
    initial begin
        clk = 1;
        forever #1 clk = ~clk;
    end
    
    // These regs are for displaying to the terminal what's going on
    
    // Show the number of times a pixel has been issued
    reg [7:0] display [image_dim+2:0][image_dim+2:0];
    // Track whether a row has been updated (to make go_fast work)
    reg [1:0] display_rows_faster [image_dim+2:0];
    // Track what pixels have been positioned
    reg [7:0] display_position [image_dim+2:0][image_dim+2:0];

    // Initialize display and display_position to " " characters
    integer ii, jj, xx, yy;
    initial begin
        for (ii=0; ii<image_dim+2; ii=ii+1) begin
            display_rows_faster[ii] = 2; // The first time through, print every row
            for (jj=0; jj<image_dim+2; jj=jj+1) begin
                display[ii][jj] = 32; // 32 is a space -- " "
                display_position[ii][jj] = 32;
            end
        end
    end
    
    // Waveform dump to "issue.vcd"
    // You can inspect this with gtkwave
    initial begin
        $dumpfile("issue.vcd");
        $dumpvars(0, uut);
    end
    
    // When "done" is raised, wait 3 counts for the "display" loops to all 
    // happen, and then stop
    always @(posedge clk) begin
        if (issue_done) begin
            #3 $finish;
        end
    end
    
    // Update the display signals
    always @(posedge clk) begin
        // If the positioner is enabled, then set the display_position of the
        // appropriate pixels to a "#"
        if (positioner_select) begin
            for (yy=positioner_y-filter_halfsize; yy<=positioner_y+filter_halfsize; yy=yy+1) begin
                display_rows_faster[yy] = 2;
                for (xx=positioner_x-filter_halfsize; xx<=positioner_x+filter_halfsize; xx=xx+1) begin
                    display_position[yy][xx] <= 35; // 35 is "#"
                end
            end
        end
        
        // If the issue is enabled (broadcast), then update the "display" of
        // the relevant pixel
        if (issue_en) begin
            display_rows_faster[issue_y] = 2;
            // If it's a "#" or a " ", then go to "0"
            if (display[issue_y][issue_x] == 35 || display[issue_y][issue_x] == 32) begin
                display[issue_y][issue_x] <= 48;
            // If it's "9", then go to "A"
            end else if (display[issue_y][issue_x] == 57) begin
                display[issue_y][issue_x] <= 65;
            // Otherwise just increment
            end else begin
                display[issue_y][issue_x] <= display[issue_y][issue_x] + 1;
            // This causes some weirdness if you increment past "Z" into
            // special characters. Just avoid that, it's not really necessary
            end
        end
    end
    
    // Start off with a "clear terminal" character, so we get a blank slate
    initial begin
        $write("\033[2J");
    end
    
    // Display the display_* signals
    always @(posedge clk) begin
        // Start off by jumping to the terminal top left position
        $write("\033[H");

        // Go through each pixel and print the display_position and display
        // characters for each
        for (ii=0; ii<image_dim+2; ii=ii+1) begin
            if (display_rows_faster[ii]) begin // We only print for rows that have been updated
                for (jj=0; jj<image_dim+2; jj=jj+1) begin
                    $write("%c%c", display_position[ii][jj], display[ii][jj]);
                end
                // go_fast means we forget about a row after it's been two
                // displays since it was updated 
                `ifdef go_fast
                display_rows_faster[ii] = display_rows_faster[ii] - 1;
                `endif // go_fast
            end
            // After every row, move on to the next row
            $write("\n");
        end

        // Also, at the bottom, let's print the last position to be
        // positioned
        if (positioner_select) begin
            for (ii=0; ii<num_allocators; ii=ii+1) begin
                if (positioner_select[ii]) begin
                    $display("(%d, %d) --> %d", positioner_x, positioner_y, ii);
                end
            end
        end
        //$stop;
    end
endmodule
