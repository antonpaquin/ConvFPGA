#include <stdio.h>

#include "protocol.h"
#include "image.h"
#include "filter.h"

void write_image(struct image_struct *im, int addr);
void write_filter(struct filter_struct *fi, int addr);

int main() {
    int ii;
    struct image_struct *test_image;
    struct filter_struct *test_filter;
    int *image_data;
    int *filter_data;
    test_image = image_alloc(5, 3);
    test_filter = filter_alloc(3, 3, 1, 100);
        
    image_data = image_get_data_ptr(test_image);
    for (ii=0; ii<image_get_len(test_image); ii++) {
        *image_data = ii;
        image_data++;
    }

    filter_data = filter_get_data_ptr(test_filter);
    for (ii=0; ii<filter_get_len(test_filter); ii++) {
        *filter_data = ii*10;
        filter_data++;
    }

    proto_open();
    
    write_image(test_image, 0);
    write_filter(test_filter, image_get_len(test_image));

    proto_set_output(image_get_len(test_image) + filter_get_len(test_filter));

    proto_run_accel();

    image_free(test_image);
    filter_free(test_filter);
    proto_close();

    return 0;
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
