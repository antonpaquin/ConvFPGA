ioport: ioport_comm.c ioport_comm.h ioport_comm_tb.c ioport_emu.v ioport_emu_tb.v
	rm ~/tmp/verilog.port; touch ~/tmp/verilog.port; \
	iverilog -o ioport_emu ioport_emu_tb.v; \
	gcc -o ioport_comm ioport_comm_tb.c ioport_comm.c
