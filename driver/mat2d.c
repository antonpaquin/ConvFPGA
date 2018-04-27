#include <stdlib.h>

#include "mat2d.h"
#include "image.h"

struct mat2d {
    int rows;
    int cols;
    float *data;
};

float mat2d_fixed_to_float(int x) {
    static const int point = 16;
    return ((float) x) / (1<<point);
}

struct mat2d *mat2d_convert_flatten_image(struct image_struct *s) {
    struct mat2d *output;
    int full_length;
    int *input_data;
    int ii;
    
    full_length = image_get_len(s);
    input_data = image_get_data_ptr(s);

    output = mat2d_alloc(1, full_length);

    for (ii=0; ii<full_length; ii++) {
        *((output -> data) + ii) = mat2d_fixed_to_float(*(input_data + ii));
    }

    return output;
}

struct mat2d *mat2d_alloc(int rows, int cols) {
    struct mat2d *res;

    res = malloc(sizeof(struct mat2d));
    res -> rows = rows;
    res -> cols = cols;
    res -> data = malloc(sizeof(float) * rows * cols);

    return res;
}

void mat2d_free(struct mat2d *m) {
    free(m -> data);
    free(m);
}

float *mat2d_get_data_ptr(struct mat2d *m) {
    return m -> data;
}

int mat2d_get_rows(struct mat2d *m) {
    return m -> rows;
}

int mat2d_get_cols(struct mat2d *m) {
    return m -> cols;
}

int mat2d_get_len(struct mat2d *m) {
    return (m -> rows) * (m -> cols);
}
