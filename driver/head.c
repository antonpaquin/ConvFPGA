#include <math.h> // expf

#include "head.h"
#include "mat2d.h"

struct mat2d *head_fc(struct mat2d *a, struct mat2d *w, struct mat2d *b) {
    // (w * a) + b
    struct mat2d *res;

    int a_row_ctr, col_ctr;
    int rows_a_in;
    int rows_out;
    float cur;

    float *data_a, *data_w, *data_b, *data_r;

    res = mat2d_alloc(1, mat2d_get_cols(w));

    rows_a_in = mat2d_get_rows(a);
    rows_out = mat2d_get_cols(a);

    data_a = mat2d_get_data_ptr(a);
    data_b = mat2d_get_data_ptr(b);
    data_r = mat2d_get_data_ptr(res);

    for (a_row_ctr=0; a_row_ctr<rows_a_in; a_row_ctr++) {
        data_w = mat2d_get_data_ptr(w);
        cur = *(data_b++);
        for (col_ctr=0; col_ctr<rows_out; col_ctr++) {
            cur += (*(data_w++) * *(data_a++));
        }
        *(data_r++) = cur;
    }

    return res;
}

struct mat2d *head_softmax(struct mat2d *a) {
    struct mat2d *output;
    int full_length;
    float *input_data, *output_data;
    float den;
    int ii;

    full_length = mat2d_get_len(a);
    output = mat2d_alloc(1, full_length);

    input_data = mat2d_get_data_ptr(a);
    output_data = mat2d_get_data_ptr(output);
    
    den = 0;
    for (ii=0; ii<full_length; ii++) {
        den += expf(*(input_data + ii));
    }

    for (ii=0; ii<full_length; ii++) {
        *(output_data + ii) = expf(*(input_data + ii)) / den;
    }

    return output;
}
