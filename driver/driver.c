#include "driver.h"
#include "image.h"
#include "filter.h"
#include "protocol.h"

void write_image(struct image_struct *im, int addr);
void write_filter(struct filter_struct *fi, int addr);
void read_output(int *data);

struct image_struct *base_image;
struct filter_struct **base_filter;
int filter_len;

void accel_open(void) {
    proto_open();
}

void accel_close(void) {
    proto_close();
}

void accel_set_image(struct image_struct *im) {
    base_image = im;
    write_image(im, 0);
}

void accel_set_filters(struct filter_struct **fi, int len) {
    base_filter = fi;
    filter_len = len;
}

struct image_struct *accel_run(void) {
    int ii;
    int output_dim;
    struct filter_struct *current_filter;
    struct image_struct *output;
    
    current_filter = *base_filter;

    output_dim = ((image_get_dim(base_image)-1) / filter_get_stride(current_filter)) + 1;
    output = image_alloc(output_dim, filter_len);

    proto_set_output(image_get_len(base_image) + filter_get_len(current_filter));

    for (ii=0; ii<filter_len; ii++) {
        current_filter = *(base_filter + ii);
        write_filter(current_filter, image_get_len(base_image));
        proto_run_accel();
        read_output(image_get_data_ptr(output) + (ii * output_dim * output_dim));
    }

    return output;
}

void write_image(struct image_struct *im, int addr) {
    int ii;
    int *data;

    proto_start_image(addr);
    proto_image_info(image_get_depth(im), image_get_dim(im));

    data = image_get_data_ptr(im);
    for (ii=0; ii<image_get_len(im); ii++, data++) {
        proto_data(*data);
    }
}

void write_filter(struct filter_struct *fi, int addr) {
    int ii;
    int *data;

    proto_start_filter(addr);
    proto_filter_info(filter_get_kernel_size(fi)/2, filter_get_stride(fi), filter_get_len(fi));
    proto_filter_bias(filter_get_bias(fi));

    data = filter_get_data_ptr(fi);
    for (ii=0; ii<filter_get_len(fi); ii++, data++) {
        proto_data(*data);
    }
}

void read_output(int *data) {
    // Unimplemented
    //
    // This should do whatever it takes to get data out of the accelerator
    // and write it into the pointer provided. The pointer is guaranteed to 
    // have enough space. If you need the length of the output data expected,
    // we have that as well.
    //
    // Note that it might be that the output is not ready yet when this is 
    // called. If that is the case, then we should block and wait for it to be
    // ready here or after proto_run_accel. Implementation should define which
    // is more acceptable.
}
