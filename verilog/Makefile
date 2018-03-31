issue: issue_tb.v issue.v memory.v issue_broadcast.v issue_positioner.v
	iverilog -o issue issue_tb.v

allocator: allocator_tb.v allocator.v allocator_controller.v dsp_controller.v dsp_emu.v ramb18_emu.v
	iverilog -o allocator allocator_tb.v
