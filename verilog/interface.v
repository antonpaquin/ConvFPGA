`ifndef _include_interface_
`define _include_interface_

/* Memory Interface
 *
 */

`define PROTOCOL_NOOP            5'b00000
`define PROTOCOL_START_IMAGE     5'b00001
`define PROTOCOL_START_FILTER    5'b00010
`define PROTOCOL_SET_OUTPUT      5'b00011
`define PROTOCOL_FILTER_INFO     5'b00100
`define PROTOCOL_FILTER_BIAS     5'b00101
`define PROTOCOL_IMAGE_INFO      5'b00110
`define PROTOCOL_DATA            5'b00111
`define PROTOCOL_RUN_ACCEL       5'b01000
`define PROTOCOL_OUTPUT_ACK      5'b01001
`define PROTOCOL_RST             5'b11111

`include "ioport_emu.v"

module Interface(
        input  wire [23:0] master_bus,

        output reg  [ 7:0] image_dim,
        output reg  [ 8:0] image_depth,

        output reg  [15:0] image_memory_offset,
        output reg  [15:0] filter_memory_offset,
        output reg  [15:0] output_memory_offset,

        output reg  [ 1:0] filter_halfsize,
        output reg  [ 2:0] filter_stride,
        output reg  [12:0] filter_length,
        output reg  [17:0] filter_bias,

        output reg  [17:0] mem_write_data,
        output reg  [15:0] mem_write_addr,
        output reg         mem_write_en,

        output reg         trigger_accel,

        input  wire        clk,
        input  wire        rst
    );

    wire master_clk;
    assign master_clk = clk; // The emulator should handle this

    wire [4:0] master_meta;
    assign master_meta = master_bus[22:18];

    wire [17:0] master_data;
    assign master_data = master_bus[17:0];

    reg master_run_req;
    reg slave_run_ack;

    always @(posedge master_clk) begin
        if (rst || master_meta == `PROTOCOL_RST) begin
            image_dim <= 0;
            image_depth <= 0;
            image_memory_offset <= 0;
            filter_memory_offset <= 0;
            output_memory_offset <= 0;
            filter_halfsize <= 0;
            filter_stride <= 0;
            filter_length <= 0;
            filter_bias <= 0;
            mem_write_data <= 0;
            mem_write_addr <= 0;
            mem_write_en <= 0;
        end

        else if (master_meta == `PROTOCOL_NOOP) begin
        end

        else if (master_meta == `PROTOCOL_START_IMAGE) begin
            image_memory_offset <= master_data;
            mem_write_addr <= master_data;
        end

        else if (master_meta == `PROTOCOL_START_FILTER) begin
            filter_memory_offset <= master_data;
            mem_write_addr <= master_data;
        end

        else if (master_meta == `PROTOCOL_SET_OUTPUT) begin
            output_memory_offset <= master_data;
        end

        else if (master_meta == `PROTOCOL_FILTER_INFO) begin
            filter_halfsize <= master_data[17:16];
            filter_stride   <= master_data[15:13];
            filter_length   <= master_data[12: 0];
        end

        else if (master_meta == `PROTOCOL_FILTER_BIAS) begin
            filter_bias <= master_data;
        end

        else if (master_meta == `PROTOCOL_IMAGE_INFO) begin
            image_depth <= master_data[16:8];
            image_dim   <= master_data[7:0];
        end

        else if (master_meta == `PROTOCOL_DATA) begin
            // TODO this won't work, we're crossing clock domains here
            // the memory writes will be all weird
            // we'll need synchronization
            mem_write_addr <= mem_write_addr + 1;
            mem_write_en <= 1;
            mem_write_data <= master_data;
        end

        else if (master_meta == `PROTOCOL_RUN_ACCEL) begin
        end

        else if (master_meta == `PROTOCOL_OUTPUT_ACK) begin
            // TODO
        end
    end

    always @(posedge master_clk) begin
        if (rst) begin
            master_run_req <= 0;

        end else if (master_meta == `PROTOCOL_RUN_ACCEL) begin
            master_run_req <= 1;

        end else if (slave_run_ack) begin
            master_run_req <= 0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            trigger_accel <= 0;
            slave_run_ack <= 0;
        end else if (master_run_req && !slave_run_ack) begin
            trigger_accel <= 1;
            slave_run_ack <= 1;
        end else begin
            trigger_accel <= 0;
            if (!master_run_req) begin
                slave_run_ack <= master_run_req;
            end
        end
    end

endmodule
`endif // _include_interface_
