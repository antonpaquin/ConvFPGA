`ifndef _include_ioport_emu_
`define _include_ioport_emu_

module IoPortEmu #(
        parameter width_bytes = 1
    )(
        output wire [(width_bytes*8)-1:0] out
    );

    integer ii;
    integer port_file;

    reg [7:0] readbuf [width_bytes-1:0];
    reg [8:0] test_char;
    
    genvar jj;
    generate
        for (jj=0; jj<width_bytes; jj=jj+1) begin
            assign out[(jj*8)+7:(jj*8)] = readbuf[width_bytes - jj - 1];
        end
    endgenerate

    initial begin
        port_file = $fopen("~/tmp/verilog.port", "r");
    end

    initial begin
        ii = 0;
        forever begin
            #2;
            test_char = $fgetc(port_file);
            while (test_char != {9{1'b1}}) begin
                readbuf[ii] = test_char[7:0];
                ii = (ii + 1) % width_bytes;
                test_char = $fgetc(port_file);
            end
        end
    end

endmodule
`endif // _include_ioport_emu_
