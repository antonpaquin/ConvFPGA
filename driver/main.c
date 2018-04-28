#include <stdio.h>

#include "image.h"
#include "mat2d.h"

#include "image_processing.h"
#include "head.h"

#include "driver.h"

void load_filter(struct filter_struct **f, int major, int minor);

struct image_struct *conv(struct image_struct *in, int major, int channels_out, int kernel, int stride, float bias) {
    int ii;
    struct filter_struct *filtr[384];
    struct image_struct *res;

    for (ii=0; ii<channels_out; ii++) {
        filtr[ii] = filter_alloc(kernel, image_get_depth(in), stride, bias);
        load_filter(filtr, major, ii);
    }

    accel_set_image(in);
    accel_set_filters(filtr, channels_out);
    
    res = accel_run();

    for (ii=0; ii<channels_out; ii++) {
        filter_free(filtr[ii]);
    }

    return res;
}

void load_filter(struct filter_struct **f, int major, int minor) {
    char fname[100];
    sprintf(fname, "filter_%d_%d.fb", major, minor);
    filter_read_file(f[minor], fname);
}

int main() {
    struct image_struct *img[13];
    struct mat2d *mat[4];

    accel_open();

    img[0] = image_alloc(227, 3);
    image_read_file(img[0], "input.ib");

    // TODO
    // right now all the biases are assumed to be 0
    // Do we need to include that in the filter file format?
    // How else do we want to read it into the program?
    img[1] = conv(img[0], 0, 96, 5, 2, 0);
    image_free(img[0]);

    img[2] = conv(img[1], 1, 96, 5, 2, 0);
    image_free(img[1]);

    img[3] = iprocess_maxpool(img[2], 2);
    image_free(img[2]);

    img[4] = iprocess_lrn(img[3]);
    image_free(img[3]);

    img[5] = conv(img[4], 2, 256, 5, 1, 0);
    image_free(img[4]);

    img[6] = iprocess_maxpool(img[5], 3);
    image_free(img[5]);

    img[7] = iprocess_lrn(img[6]);
    image_free(img[6]);

    img[8] = conv(img[7], 3, 384, 3, 1, 0);
    image_free(img[7]);

    img[9] = conv(img[8], 4, 384, 3, 1, 0);
    image_free(img[8]);

    img[10] = conv(img[9], 5, 256, 3, 1, 0);
    image_free(img[9]);

    img[11] = iprocess_maxpool(img[10], 3);
    image_free(img[10]);

    img[12] = iprocess_lrn(img[11]);
    image_free(img[11]);

    accel_close();

    mat[0] = mat2d_convert_flatten_image(img[12]);
    image_free(img[12]);

    // TODO requires loading the weights and biases of FC layer
    mat[1] = head_fc(mat[0], 0, 0);
    mat2d_free(mat[0]);

    mat[2] = head_fc(mat[1], 0, 0);
    mat2d_free(mat[1]);

    mat[3] = head_softmax(mat[2]);
    mat2d_free(mat[2]);

    // TODO convert softmax into classes (string? printf? to a file?)

    return 0;
}

