#include "image_processing.h"
#include "image.h"

#define max(x, y) ((x > y) ? x : y)

struct image_struct *iprocess_maxpool(struct image_struct *s) {
    int layer_ctr, col_ctr, row_ctr;
    int c[4];

    int *data_in, *data_out;
    int row_size;
    int layer_size;
    int depth;
    struct image_struct *output;

    data_in = image_get_data_ptr(s);
    row_size = image_get_dim(s);
    layer_size = row_size * row_size;
    depth = image_get_depth(s);

    output = image_alloc((row_size + 1) / 2, depth);
    data_out = image_get_data_ptr(output);

    for (layer_ctr = 0; layer_ctr < depth; layer_ctr++) {
        for (col_ctr = 0; col_ctr < row_size; col_ctr += 2) {
            for (row_ctr = 0; row_ctr < row_size; row_ctr += 2) {
                if (col_ctr + 1 == row_size && row_ctr + 1 == row_size) {
                    *data_out++ = *(data_in + (layer_ctr * layer_size) + (col_ctr * row_size) + row_ctr);
                } else if (col_ctr + 1 == row_size) {
                    c[0] = *(data_in + (layer_ctr * layer_size) + (col_ctr * row_size) + row_ctr);
                    c[1] = *(data_in + (layer_ctr * layer_size) + (col_ctr * row_size) + row_ctr + 1);
                    *data_out++ = max(c[0], c[1]);
                } else if (row_ctr + 1 == row_size) {
                    c[0] = *(data_in + (layer_ctr * layer_size) + (col_ctr * row_size) + row_ctr);
                    c[2] = *(data_in + (layer_ctr * layer_size) + ((col_ctr + 1) * row_size) + row_ctr);
                    *data_out++ = max(c[0], c[2]);
                } else {
                    c[0] = *(data_in + (layer_ctr * layer_size) + (col_ctr * row_size) + row_ctr);
                    c[1] = *(data_in + (layer_ctr * layer_size) + (col_ctr * row_size) + row_ctr + 1);
                    c[2] = *(data_in + (layer_ctr * layer_size) + ((col_ctr + 1) * row_size) + row_ctr);
                    c[3] = *(data_in + (layer_ctr * layer_size) + ((col_ctr + 1) * row_size) + row_ctr + 1);
                    *data_out++ = max(max(c[0], c[1]), max(c[2], c[3]));
                }
            }
        }
    }

    return output;
}
