void proto_open(void);
void proto_close(void);

void proto_start_image(int address);
void proto_start_filter(int address);
void proto_set_output(int address);
void proto_filter_info(int halfsize, int stride, int length);
void proto_filter_bias(int bias);
void proto_image_info(int depth, int dim);
void proto_data(int data);
void proto_run_accel(void);
void proto_output_ack(void);

