#include "driver.h"

int main() {
    int ii;
    struct image_struct *test_image;
    struct filter_struct *test_filter;
    struct image_struct *output;
    test_image = image_alloc(5, 3);
    test_filter = filter_alloc(3, 3, 1, 100);
    
    image_read_file(test_image, "test.ib");
    filter_read_file(test_filter, "test.fb");

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

