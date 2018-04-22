#include "driver.h"

int main() {
    int ii;
    struct image_struct *test_image;
    struct filter_struct *test_filter;
    struct image_struct *output;
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

    accel_open();
    
    accel_set_image(test_image);
    accel_set_filters(&test_filter, 1);

    output = accel_run();

    image_free(test_image);
    filter_free(test_filter);
    image_free(output);

    accel_close();
    return 0;
}

