#include <math.h> // powf

#include "image_processing.h"
#include "image.h"

#define max(x, y) ((x > y) ? x : y)
#define INT_MIN (1 << (8*sizeof(int)-1))

int image_pick_index(int *start, int row_size, int layer_size, int z, int y, int x) {
    if (x >= row_size || y >= row_size) {
        return INT_MIN;
    } else {
        return *(start + (layer_size * z) + (row_size * y) + x);
    }
}

struct image_struct *iprocess_maxpool(struct image_struct *s, int kernel) {
    int layer_ctr, col_ctr, row_ctr;
    int row_offset, col_offset;
    int picked_max, picked_test;

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
                picked_max = INT_MIN;
                for (col_offset = -((kernel - 1) / 2); col_offset <= kernel / 2; col_offset++) {
                    for (row_offset = -((kernel - 1) / 2); row_offset <= kernel / 2; row_offset++) {
                        picked_test = image_pick_index(data_in, row_size, layer_size, layer_ctr, col_ctr + col_offset, row_ctr + row_offset);
                        if (picked_test > picked_max) {
                            picked_max = picked_test;
                        }
                    }
                }
                *data_out++ = picked_max;
            }
        }
    }

    return output;
}

float iprocess_fixed_to_float(int x) {
    static const int point = 16;
    return ((float) x) / (1<<point);
}

int iprocess_float_to_fixed(float x) {
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
                nearby_response = iprocess_fixed_to_float(*(data_in + nearby_idx));
                response += a * powf(nearby_response, 2);
            }
        }
        response = iprocess_fixed_to_float(*(data_in + output_idx)) / powf(response, b);
        *(data_out + output_idx) = iprocess_float_to_fixed(response);
    }
    
    return output;
}
