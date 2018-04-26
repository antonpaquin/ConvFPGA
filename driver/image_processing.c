#include <math.h>

#include "image_processing.h"
#include "image.h"

#define max(x, y) ((x > y) ? x : y)

inline int image_pick_index(int *start, int row_size, int layer_size, int z, int y, int x) {
    return *(start + (layer_size * z) + (row_size * y) + x);
}

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
                    *data_out++ = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr, row_ctr);
                } else if (col_ctr + 1 == row_size) {
                    c[0] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr, row_ctr);
                    c[1] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr, row_ctr+1);
                    *data_out++ = max(c[0], c[1]);
                } else if (row_ctr + 1 == row_size) {
                    c[0] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr, row_ctr);
                    c[2] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr+1, row_ctr);
                    *data_out++ = max(c[0], c[2]);
                } else {
                    c[0] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr, row_ctr);
                    c[1] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr, row_ctr+1);
                    c[2] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr+1, row_ctr);
                    c[3] = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr+1, row_ctr+1);
                    *data_out++ = max(max(c[0], c[1]), max(c[2], c[3]));
                }
            }
        }
    }

    return output;
}

float fixed_to_float(int x) {
    static const int point = 16;
    return ((float) x) / (1<<point);
}

int float_to_fixed(float x) {
    static const int point = 16;
    return (int) (x * (1<<point));
}

struct image_struct *iprocess_lrn(struct image_struct *s) {
    static const float k = 2.0f;
    static const float a = 0.0001f;
    static const float b = 0.75f;
    static const int n = 5;

    struct image_struct *output;
    int layer_size, depth, full_length;
    float response, nearby_response;
    int *data_in, *data_out;
    int output_idx, nearby_idx;
    int ii;

    output = image_alloc(image_get_dim(s), image_get_depth(s));

    layer_size = image_get_dim(s) * image_get_dim(s);
    depth = image_get_depth(s);
    full_length = layer_size * depth;

    data_in = image_get_data_ptr(s);
    data_out = image_get_data_ptr(output);

    for (output_idx=0; output_idx<full_length; output_idx++) {
        response = k;
        for (ii=-(n/2); ii<(n/2)+1; ii++) {
            nearby_idx = output_idx + (layer_size * ii);
            if (nearby_idx >= 0 && nearby_idx < full_length) {
                nearby_response = fixed_to_float(*(data_in + nearby_idx));
                response += a * powf(nearby_response, 2);
            }
        }
        response = fixed_to_float(*(data_in + output_idx)) / powf(response, b);
        *(data_out + output_idx) = float_to_fixed(response);
    }
    
    return output;
}
