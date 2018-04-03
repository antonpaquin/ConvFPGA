issue: issue_tb.v issue.v memory.v issue_broadcast.v issue_positioner.v
	iverilog -o issue issue_tb.v

issue_filter: issue_filter.v issue_filter_tb.v
	iverilog -o issue_filter issue_filter_tb.v

allocator: allocator_tb.v allocator.v allocator_controller.v dsp_controller.v dsp_emu.v ramb18_emu.v
	iverilog -o allocator allocator_tb.v

accel: accel_tb.v accel.v allocator_controller.v allocator.v dsp_controller.v dsp_emu.v issue_broadcast.v issue_filter.v issue_positioner.v issue.v memory.v ramb18_emu.v
	iverilog -o accel accel_tb.v
