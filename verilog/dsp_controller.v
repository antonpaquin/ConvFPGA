`ifndef _include_dsp_controller_
`define _include_dsp_controller_

`include "dsp_emu.v"

/* DSP controller
 * 
 * This module provides a layer between the DSP and the allocator controller 
 * and memory buffer. It manages the counters on the DSP side of things, sets
 * the DSP's opcodes, and reads values from the memory buffer into the DSP's
 * inputs.
 *
 * Note that the DSP module might be pipelined, in which case this module
 * will also handle whatever needs to be done to make that work smoothly.
 */

module DspController(
        // This module needs read access to both lines of the memory buffer
        output reg  [ 9:0] ramb_a_addr,
        input  wire [17:0] ramb_a_data,
        output reg  [ 9:0] ramb_b_addr,
        input  wire [17:0] ramb_b_data,
        
        // Counters to synchronize the DSP and the allocator controller. This
        // process is described in more detail in "allocator_controller.v"
        input  wire [12:0] issue_a_alloc_counter,
        output reg  [12:0] issue_a_dsp_counter,
        
        // As above, counters for the filter side of things
        input  wire [12:0] filter_issue_counter,
        output reg  [12:0] filter_dsp_counter,
        input  wire [12:0] filter_length,
        
        // Raw 48-bit result of the DSP, and whether it's ready to be read
        output wire [47:0] result,
        output reg         result_ready,

        input  wire        clk,
        input  wire        rst
    );
    
    // Since memory reads take a cycle to complete, we use these signals to
    // delay the DSP operation by 1 cycle so that they fall in line with
    // memory
    reg [ 1:0] dsp_op;
    reg [ 1:0] dsp_op_next;

    // The DSP takes some time to compute from when it inputs the last MAC for
    // the round. When that happens, we trigger a counter that waits for some
    // number of cycles before raising the "result_ready" signal.
    reg [2:0] pipeline_delay_result_counter;
    localparam pipeline_delay_result = 2; // How many cycles to wait for
    
    // Main operation of the DSP controller
    always @(posedge clk) begin
        // Initial: do nothing, clear the DSP, clear counters
        if (rst) begin
            issue_a_dsp_counter <= 0;
            filter_dsp_counter <= 0;
            dsp_op_next <= `DSP_INSTRUCTION_CLR; 

        // While there is more data to be used in both image issue and filter
        // issue, run a MACC operation
        end else if ((issue_a_alloc_counter > issue_a_dsp_counter) && (filter_issue_counter > filter_dsp_counter)) begin
            // Read data from memory
            // image data is addressed at [0-511]
            ramb_a_addr <= {1'b0, issue_a_dsp_counter[8:0]};
            // filter data is addressed at [512-1023]
            ramb_b_addr <= {1'b1, filter_dsp_counter[8:0]};
            // Increment the counters to track how far the DSP has progressed
            // Note: these two counters are synchronized -- do we really need two?
            issue_a_dsp_counter <= issue_a_dsp_counter + 1;
            filter_dsp_counter <= filter_dsp_counter + 1;
            // And set the DSP opcode
            dsp_op_next <= `DSP_INSTRUCTION_MAC;

        // If we don't have new data, hold state (and perform a no-op on the DSP)
        end else begin
            dsp_op_next <= `DSP_INSTRUCTION_NOP;
        end
    end

    // Delay the DSP operation by 1 cycle, so it is synched with memory data
    always @(posedge clk) begin
        if (rst) begin
            dsp_op <= `DSP_INSTRUCTION_CLR;
        end else begin
            dsp_op <= dsp_op_next;
        end
    end
    
    // Control the pipeline counter, which delays the "result_ready" signal
    // from the time the last input is entered into the DSP pipeline.
    always @(posedge clk) begin
        // Counter starts at 0, ready starts at 0
        if (rst) begin
            result_ready <= 0;
            pipeline_delay_result_counter <= 0;

        // When we send the last computation to the DSP, start counting up
        end else if (filter_dsp_counter == filter_length) begin
            pipeline_delay_result_counter <= pipeline_delay_result_counter + 1;
            // And if we hit the final value, raise "ready"
            if (pipeline_delay_result_counter == pipeline_delay_result) begin
                result_ready <= 1;
            end 

        // Otherwise, we don't need to do anything
        end
    end
    
    // The DSP48 unit that actually performs the heavy lifting
    DspEmu dsp (
        .op(dsp_op),
        .a(ramb_a_data),
        .b(ramb_b_data),
        .c(48'b0),
        .p(result),
        .clk(clk)
    );
endmodule

`endif // _include_dsp_controller_
