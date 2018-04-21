#include "filter.h"
#include "stdlib.h"

struct filter_struct {
    int kernel_size;
    int depth;
    int stride;
    int bias;
    int *data;
};


struct filter_struct *filter_alloc(int kernel_size, int depth, int stride, int bias) {
    int len;
    struct filter_struct *res;

    len = kernel_size * kernel_size * depth;

    res = malloc(sizeof(struct filter_struct));
    res -> kernel_size = kernel_size;
    res -> depth = depth;
    res -> stride = stride;
    res -> bias = bias;
    res -> data = malloc(sizeof(int) * len);

    return res;
}

int filter_get_len(struct filter_struct *s) {
    return s -> kernel_size * s -> kernel_size * s -> depth;
}

int filter_get_kernel_size(struct filter_struct *s) {
    return s -> kernel_size;
}

int filter_get_depth(struct filter_struct *s) {
    return s -> depth;
}

int filter_get_stride(struct filter_struct *s) {
    return s -> stride;
}

int filter_get_bias(struct filter_struct *s) {
    return s -> bias;
}

void filter_free(struct filter_struct *s) {
    free(s -> data);
    free(s);
}

int *filter_get_data_ptr(struct filter_struct *s) {
    return s -> data;
}
