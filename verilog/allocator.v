`ifndef _include_allocator_
`define _include_allocator_

`include "allocator_controller.v"
`include "ramb18_emu.v"
`include "dsp_controller.v"

/* Allocator
 *
 * Allocator is the module that describes an individual computational unit
 * that drives a single DSP. It's got one RAMB18 attached for near-DSP
 * caching, and talks to the DSP through the dsp_controller.
 *
 * When the allocator's center_write_enable is raised, it reads and saves the
 * position corresponding to where it should currently be listening to. Then,
 * as the issue stage broadcasts pixel values across the image, the allocator
 * picks out values that are within its listening range and puts them in the
 * RAMB18.
 *
 * The dsp_controller picks out values in the RAMB18 for which there is both
 * an image weight and a filter weight. Then it sends these into the DSP for
 * a MACC operation.
 *
 * Issue is guaranteed to be in-order (Z is the high order bit, then Y, then 
 * X). This means we can synchronize the values going through the RAMB18 with
 * counters. 
 */

/* TODO
 *
 * 1. We need to get output values out of the DSP somehow. Right now, we
 * should know when the DSP is done, but we don't do anything with the output
 * -- we should add the bias, run a RELU, then store it in a memory location
 *  somewhere.
 *
 *  2. Allocators could use systolic data busses for the filter weights, thus
 *  cutting down the required memory connections by 1/2 (see "systolics.txt")
 */

module Allocator(
        // Input values coming from the issue stage that describe image data
        input  wire [ 7:0] issue_a_x,
        input  wire [ 7:0] issue_a_y,
        input  wire [17:0] issue_a_data,
        input  wire        issue_a_blocked,
        output wire        issue_a_block,
        
        // Input values for the filter weights, coming from (???)
        input  wire [12:0] filter_issue_counter,
        input  wire [17:0] filter_data,
        input  wire        filter_blocked,
        output wire        filter_block,
        
        // Positioning data -- describes where the allocator should be
        // listening to
        input  wire [ 7:0] center_x_input,
        input  wire [ 7:0] center_y_input,
        input  wire        center_write_enable,
        
        // Filter information
        // This is the size of the filter -- 5, or 3
        input  wire [ 2:0] filter_dim,
        // The bias that will be added to the pixel once all MACCs have run
        input  wire [17:0] filter_bias,
        // The number of total operations in the filter =W*H*D
        input  wire [12:0] filter_length,
        
        // Output, and whether the output is ready to be read
        output wire        result_ready,
        output wire [17:0] result_data,

        input  wire        clk,
        input  wire        rst
    );
    
    // Connection to the allocator's RAMB18 memory. We use both read and write
    // on both A and B, fully utilizing the memory per unit.
    wire [ 9:0] ramb_read_a_addr,
                ramb_read_b_addr,
                ramb_writ_a_addr,
                ramb_writ_b_addr;

    wire [17:0] ramb_read_a_data,
                ramb_read_b_data,
                ramb_writ_a_data,
                ramb_writ_b_data;

    wire        ramb_writ_a_en,
                ramb_writ_b_en;
    
    // The counters describe how much data there is in memory, and how many
    // values have been computed. This is how we ensure that the allocator
    // executes everything it needs to execute, in order.
    // If we had multiple issue units, each would need its own pair of these.
    wire [12:0] issue_a_alloc_counter, // Image data issue counter
                issue_a_dsp_counter; // DSP execution counter
    
    // We only need one filter counter for the whole set though
    wire [12:0] filter_dsp_counter;
    
    // Raw output from the DSP
    wire [47:0] result;
        
    // The main controller of the allocater unit -- takes in data from issue
    // stage, and puts it into the ramb and dsp_controller units
    AllocatorController controller (
        // Data from issue broadcast -- what information from the image is
        // being sent right now?
        .issue_a_x(issue_a_x),
        .issue_a_y(issue_a_y),
        .issue_a_data(issue_a_data),
        .issue_a_blocked(issue_a_blocked),
        
        // Synchronizing counters for how much of the issue data has been
        // received vs how much has the DSP been able to process
        .issue_a_alloc_counter(issue_a_alloc_counter),
        .issue_a_dsp_counter(issue_a_dsp_counter),
        // Given the state of these counters, should we block issue?
        .issue_a_block(issue_a_block),

        // Filter data needs to come in from somewhere as well. Should be
        // issued in-order like image data, so we don't actually need the XYZ
        // data in order to place it properly
        .filter_data(filter_data),
        .filter_blocked(filter_blocked),
        
        // Filter synchronizing counters, to keep the DSP and the controller
        // within the bounds set by the RAMB18 buffer
        .filter_issue_counter(filter_issue_counter),
        .filter_dsp_counter(filter_dsp_counter),
        .filter_block(filter_block),
        
        // We read the position we should pay attention to with these signals,
        // and latch them when write_enable goes high. Data about these pixels
        // should only be issued after we have been positioned
        .center_x_input(center_x_input),
        .center_y_input(center_y_input),
        .center_write_enable(center_write_enable),
        
        // Information about the filter 
        .filter_dim(filter_dim), // How wide / tall
        .filter_length(filter_length), // How deep
        .filter_bias(filter_bias), // What bias to apply
        // Note that the leak factor is implemented as a module parameter --
        // it should be held constant over entire life of the accelerator
        
        // The controller stage reads from the issue stage and writes to the
        // ramb buffer. It needs one write line for image data, and one for
        // filter data, but it doesn't need to read anything
        .ramb_a_write_en(ramb_writ_a_en),
        .ramb_a_data(ramb_writ_a_data),
        .ramb_a_addr(ramb_writ_a_addr),

        .ramb_b_write_en(ramb_writ_b_en),
        .ramb_b_data(ramb_writ_b_data),
        .ramb_b_addr(ramb_writ_b_addr),
        
        // We're not currently sending the result_ready or result_data signals
        // This needs to be implemented at some point -- see TODO #1
        //.result_ready(???),
        //.result_data(???),
        
        .clk(clk),
        .rst(rst)
    );
    
    // The DSP controller is a thin layer between the DSP and the RAMB memory
    // + allocator controller. It keeps track of the relevant counters, and
    // when things are OK, sends values for the DSP to process.
    DspController dsp (
        // This unit does all the buffer memory read operations
        .ramb_a_addr(ramb_read_a_addr),
        .ramb_a_data(ramb_read_a_data),
        .ramb_b_addr(ramb_read_b_addr),
        .ramb_b_data(ramb_read_b_data),
        
        // These counters synchronize image data
        .issue_a_alloc_counter(issue_a_alloc_counter),
        .issue_a_dsp_counter(issue_a_dsp_counter),

        // And these synchronize filter data
        .filter_issue_counter(filter_issue_counter),
        .filter_dsp_counter(filter_dsp_counter),
        
        // Result of the DSP48 -- "P" -- as a 48 bit number
        .result(result),

        .clk(clk),
        .rst(rst)
    );
    
    // Model 18 bit block RAM unit. We give 1 of these per DSP to act as
    // a buffer, so that image data and filter data don't need to be perfectly
    // synchronized. We can still take in weights for either until the buffer
    // is filled, and the DSP will go through these values as fast as it can.
    Ramb18Emu ramb (
        // Each block RAM provides 1k of 18-bit values, with 2 read lines and
        // 2 write lines.
        .read_addr_a(ramb_read_a_addr),
        .read_data_a(ramb_read_a_data),
        .read_addr_b(ramb_read_b_addr),
        .read_data_b(ramb_read_b_data),

        .write_addr_a(ramb_writ_a_addr),
        .write_data_a(ramb_writ_a_data),
        .write_en_a  (ramb_writ_a_en),

        .write_addr_b(ramb_writ_b_addr),
        .write_data_b(ramb_writ_b_data),
        .write_en_b  (ramb_writ_b_en),

        .clk(clk)
    );

endmodule
`endif // _include_allocator_
