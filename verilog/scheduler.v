`ifndef _include_scheduler_
`define _include_scheduler_

`define STATE_START_ROUND          3'b000
`define STATE_POSITIONER_HEADSTART 3'b001
`define STATE_BROADCASTING         3'b010
`define STATE_AWAIT_ADVANCE        3'b011
`define STATE_DONE                 3'b100

module Scheduler (
        input  wire positioner_round,
        output reg  positioner_advance,
        input  wire positioner_done,
        output reg  positioner_rst,

        input  wire image_broadcast_round,
        output reg  image_broadcast_rst,

        input  wire filter_broadcast_done,
        output reg  filter_broadcast_rst,

        input  wire allocator_done,
        output reg  allocator_rst,

        output reg  accel_done,

        input  wire advance,

        input  wire clk,
        input  wire rst
    );

    reg [2:0] state;
    reg [2:0] delay_counter;
    
    localparam positioner_headstart_delay = 1;

   
    always @(posedge clk) begin
        if (rst) begin
            state <= `STATE_START_ROUND;
            delay_counter <= 0;

        end else if (state == `STATE_START_ROUND) begin
            state <= `STATE_POSITIONER_HEADSTART;
            delay_counter <= 0;

        end else if (state == `STATE_POSITIONER_HEADSTART) begin
            delay_counter <= delay_counter + 1;
            if (delay_counter == positioner_headstart_delay) begin
                state <= `STATE_BROADCASTING;
            end

        end else if (state == `STATE_BROADCASTING) begin
            if (image_broadcast_round && positioner_done && allocator_done) begin
                state <= `STATE_DONE;

            end else if (image_broadcast_round && positioner_round && allocator_done) begin
                state <= `STATE_AWAIT_ADVANCE;

            end

        end else if (state == `STATE_AWAIT_ADVANCE) begin
            if (advance) begin
                state <= `STATE_START_ROUND;
            end

        end else if (state == `STATE_DONE) begin

        end
    end

    always @(*) begin
        case (state)
            `STATE_START_ROUND: begin
                positioner_advance = 1;
                positioner_rst = 0;
                image_broadcast_rst = 1;
                filter_broadcast_rst = 1;
                allocator_rst = 1;
                accel_done = 0;
            end

            `STATE_POSITIONER_HEADSTART: begin
                positioner_advance = 0;
                positioner_rst = 0;
                image_broadcast_rst = 1;
                filter_broadcast_rst = 0;
                allocator_rst = 0;
                accel_done = 0;
            end

            `STATE_BROADCASTING: begin
                positioner_advance = 0;
                positioner_rst = 0;
                image_broadcast_rst = 0;
                filter_broadcast_rst = 0;
                allocator_rst = 0;
                accel_done = 0;
            end

            `STATE_AWAIT_ADVANCE: begin
                positioner_advance = 0;
                positioner_rst = 0;
                image_broadcast_rst = 1;
                filter_broadcast_rst = 1;
                allocator_rst = 0;
                accel_done = 0;
            end

            `STATE_DONE: begin
                positioner_advance = 0;
                positioner_rst = 1;
                image_broadcast_rst = 1;
                filter_broadcast_rst = 1;
                allocator_rst = 1;
                accel_done = 1;
            end

            default: begin
                positioner_advance = 0;
                positioner_rst = 1;
                image_broadcast_rst = 1;
                filter_broadcast_rst = 1;
                allocator_rst = 1;
                accel_done = 0;
            end
        endcase
    end
endmodule
`endif // _include_scheduler_
