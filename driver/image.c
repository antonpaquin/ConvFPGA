#include "image.h"
#include "stdlib.h"

struct image_struct {
    int dim;
    int depth;
    int *data;
};


struct image_struct *image_alloc(int dim, int depth) {
    int len;
    struct image_struct *res;

    len = dim * dim * depth;

    res = malloc(sizeof(struct image_struct));
    res -> dim = dim;
    res -> depth = depth;
    res -> data = malloc(sizeof(int) * len);

    return res;
}

void image_free(struct image_struct *s) {
    free(s -> data);
    free(s);
}

int image_get_len(struct image_struct *s) {
    return s -> dim * s -> dim * s -> depth;
}

int image_get_dim(struct image_struct *s) {
    return s -> dim;
}

int image_get_depth(struct image_struct *s) {
    return s -> depth;
}

int *image_get_data_ptr(struct image_struct *s) {
    return s -> data;
}
