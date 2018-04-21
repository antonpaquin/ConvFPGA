allocator: allocator_tb.v allocator.v allocator_controller.v dsp_controller.v dsp_emu.v ramb18_emu.v
	iverilog -o allocator allocator_tb.v

accel: accel_tb.v accel.v allocator_controller.v allocator.v dsp_controller.v dsp_emu.v image_broadcast.v filter_broadcast.v positioner.v memory.v ramb18_emu.v scheduler.v writeback.v
	iverilog -o accel accel_tb.v

main:
	iverilog -o main main_tb.v
