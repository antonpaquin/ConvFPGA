#include <stdlib.h>
#include <stdio.h>

#include "image.h"

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

int image_read_file(struct image_struct *s, const char *fname) {
    FILE *fp;
    int *data;
    int in_buf[4];

    fp = fopen(fname, "r");
    if (fp == NULL)
        return -1;
    
    data = s -> data;

    while ((in_buf[0] = fgetc(fp)) != EOF) {
        in_buf[1] = fgetc(fp);
        in_buf[2] = fgetc(fp);
        in_buf[3] = fgetc(fp);
        *data++ = (
            ((in_buf[0] & 0xFF) <<  0) |
            ((in_buf[1] & 0xFF) <<  8) |
            ((in_buf[2] & 0xFF) << 16) | 
            ((in_buf[3] & 0xFF) << 24)
        );
    }
    return 0;
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
