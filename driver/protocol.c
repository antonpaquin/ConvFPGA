#include "ioport_comm.h"

#define PROTOCOL_NOOP         ( 0<<18)
#define PROTOCOL_START_IMAGE  ( 1<<18)
#define PROTOCOL_START_FILTER ( 2<<18)
#define PROTOCOL_SET_OUTPUT   ( 3<<18)
#define PROTOCOL_FILTER_INFO  ( 4<<18)
#define PROTOCOL_FILTER_BIAS  ( 5<<18)
#define PROTOCOL_IMAGE_INFO   ( 6<<18)
#define PROTOCOL_DATA         ( 7<<18)
#define PROTOCOL_RUN_ACCEL    ( 8<<18)
#define PROTOCOL_OUTPUT_ACK   ( 9<<18)
#define PROTOCOL_RST          (31<<18)

#define MASK_CLK  (0x00800000)
#define MASK_CMD  (0x007C0000)
#define MASK_DATA (0x00003FFF)

void write_word(int cmd, int data) {
    int msg;
    char buf[3];

    msg = MASK_CLK | (MASK_CMD & cmd) | (MASK_DATA & data);
    buf[0] = msg & 0x000000FF;
    buf[1] = (msg & 0x0000FF00) >> 8;
    buf[2] = (msg & 0x00FF0000) >> 16;
    ioport_write(buf, 3);
    buf[2] &= ~MASK_CLK;
    // I might need to sleep here
    ioport_write(buf, 3);
    // I might need to sleep here
}

void proto_open(void) {
    ioport_open("~/tmp/verilog.port");
}
void proto_close(void) {
    ioport_close();
}

void proto_start_image(int address) {
    write_word(PROTOCOL_START_IMAGE, address);
}

void proto_start_filter(int address) {
    write_word(PROTOCOL_START_FILTER, address);
}

void proto_set_output(int address) {
    write_word(PROTOCOL_SET_OUTPUT, address);
}

void proto_filter_info(int halfsize, int stride, int length) {
    static const int mask_halfsize = 0x00030000;
    static const int mask_stride =   0x0000E000;
    static const int mask_length =   0x000001FF;
    int data;

    data = ((halfsize << 16) & mask_halfsize) | ((stride << 13) & mask_stride) | (length & mask_length);
    write_word(PROTOCOL_FILTER_INFO, data);
}

void proto_filter_bias(int bias) {
    write_word(PROTOCOL_FILTER_BIAS, bias);
}

void proto_image_info(int depth, int dim) {
    static const int mask_depth = 0x0001FF00;
    static const int mask_dim =   0x000000FF;
    int data;

    data = ((depth << 8) & mask_depth) | (dim & mask_dim);
    write_word(PROTOCOL_IMAGE_INFO, data);
}

void proto_data(int data) {
    write_word(PROTOCOL_DATA, data);
}

void proto_run_accel(void) {
    write_word(PROTOCOL_RUN_ACCEL, 0);
}

void proto_output_ack(void) {
    write_word(PROTOCOL_OUTPUT_ACK, 0);
}
