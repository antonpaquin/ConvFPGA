#include "driver.h"

int main() {
    struct image_struct *test_image;
    struct filter_struct *test_filter[2];
    struct image_struct *output;

    test_image = image_alloc(5, 3);
    test_filter[0] = filter_alloc(3, 3, 1, 100);
    test_filter[1] = filter_alloc(3, 3, 1, 100);
    
    image_read_file(test_image, "test.ib");
    filter_read_file(test_filter[0], "test.fb");
    filter_read_file(test_filter[1], "test.fb");
    /* 
     * Note: this just to demo showing how to set up multiple filters.
     *
     * Currently, when this runs, the driver doesn't block until output, so the
     * simulator will start the next round prematurely. It turns out that this
     * is okay -- the new values will overwrite the old at some point, but 
     * they're identical anyway. However, we'll only see one set of outputs.
     *
     * This should be fixed when the protocol is fully in place.
     */

    accel_open();
    
    accel_set_image(test_image);
    accel_set_filters(test_filter, 2);

    output = accel_run();

    image_free(test_image);
    filter_free(test_filter[0]);
    filter_free(test_filter[1]);
    image_free(output);

    accel_close();
    return 0;
}

