`ifndef _include_filter_broadcast_
`define _include_filter_broadcast_

/* Issue Filter
 *
 * This module reads filter data from memory, and sends it out to the
 * allocators along with a counter.
 * 
 * Because of that, it's a fairly simple implementation. The biggest worry is
 * timing issues coming out of memory, which I think are all solved.
 */

/* TODO
 *
 * 1. (Shared with allocator) the proper position and filter data to be sent
 * to an allocator is available in the previous allocator. This may allow for
 * systolic computing, which would cut down on the connection requirements of
 * this module.
 */

module FilterBroadcast #(
        // We need this only to accept the filter_block signal. Maybe that can
        // be done by moving the OR reduction to "accel.v"?
        parameter num_allocators = 220
    ) (
        // For each output, we send the weight and a counter.
        output reg  [12:0] counter,
        output wire [17:0] data,

        // We also allow the receivers to "block" us if they're out of space,
        // preventing further broadcast until block is lowered
        output reg         en,
        input  wire [num_allocators-1:0] block,

        // How long is the filter? We need to know when to stop reading and
        // counting
        input  wire [12:0] filter_length,
        
        // Memory access -- filter probably won't be the critical path, so we
        // can afford to skimp on read lines here and spend them elsewhere (on
        // image broadcast, perhaps)
        output wire [15:0] filter_read_addr,
        input  wire [17:0] filter_read_data,

        // Done when we've sent the entire filter for the round
        output reg         done,

        input  wire        clk,
        input  wire        rst
    );
    
    // Memory is delayed by one cycle, so we mostly operate on the next value
    // of the counter, instead of the present value
    reg [12:0] counter_next;

    // The address we want to read is represented by just the counter, nothing
    // fancy. We pad it out with three bits to fill up the 15 bit address.
    assign filter_read_addr = {3'b0, counter_next};

    // If any allocators are blocking filter, we should hold
    assign blocked = |block;

    // Our output is just the value from memory, but we want that to be fast
    assign data = filter_read_data;

    // Main controls for this module
    always @(posedge clk) begin
        // Initial: counter is zero, no data ready, not done
        if (rst) begin
            counter_next <= 0;
            en <= 0;
            done <= 0;
        
        // If we've sent everything, do nothing
        end else if (done) begin

        // When we reach the end of the count, we have nothing left to send
        end else if (counter_next == filter_length) begin
            en <= 0;
            done <= 1;

        // If a DSP is blocking, don't move, but we should show that there's
        // no new data coming out
        end else if (blocked) begin
            en <= 0;

        // Otherwise, count up and send data
        end else begin
            en <= 1;
            counter_next <= counter_next + 1;

        end
    end

    // filter_issue_counter is filter_issue_counter_next, delayed by one cycle
    // (which usually means next-1, but not always)
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;

        end else begin
            counter <= counter_next;

        end
    end

endmodule
`endif // _include_filter_broadcast_
