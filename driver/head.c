#include <cblas.h> // cblas_sgemv
#include <math.h> // expf
#include <string.h> // memcpy

#include "head.h"
#include "mat2d.h"

struct mat2d *head_fc(struct mat2d *a, struct mat2d *w, struct mat2d *b) {
    // (w * a) + b
    struct mat2d *res;

    res = mat2d_alloc(1, mat2d_get_cols(w));

    // Add bias to res first
    memcpy(mat2d_get_data_ptr(res), mat2d_get_data_ptr(b), mat2d_get_len(b));

    cblas_sgemv(
        CblasRowMajor,           // w stores data in row-major order
        CblasNoTrans,            // don't transpose w
        mat2d_get_rows(w),       // M = num rows of w
        mat2d_get_cols(w),       // N = num cols of w
        1,                       // alpha = scale output by 1
        mat2d_get_data_ptr(w),   // *A = w data
        mat2d_get_cols(w),       // lda = leading dimension of w (cols for row-major)
        mat2d_get_data_ptr(a),   // *X = a data
        1,                       // incX = a stores data at every address
        1,                       // beta = add res (currently contains bias)
        mat2d_get_data_ptr(res), // *Y = res data
        1                        // incY = res stores data at every address
    );

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
