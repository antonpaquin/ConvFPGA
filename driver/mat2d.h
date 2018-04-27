#ifndef _include_mat2d_h_
#define _include_mat2d_h_

#include "image.h"

struct mat2d;

struct mat2d *mat2d_convert_flatten_image(struct image_struct *s);
struct mat2d *mat2d_alloc(int rows, int cols); 
void mat2d_free(struct mat2d *m);

float *mat2d_get_data_ptr(struct mat2d *m);
int mat2d_get_rows(struct mat2d *m);
int mat2d_get_cols(struct mat2d *m);
int mat2d_get_len(struct mat2d *m);

#endif //_include_mat2d_h_
