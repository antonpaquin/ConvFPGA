#ifndef _include_image_h_
#define _include_image_h_

struct image_struct;

struct image_struct *image_alloc(int dim, int depth);
void image_free(struct image_struct *s);

int image_read_file(struct image_struct *s, const char *fname);
int image_get_len(struct image_struct *s);
int image_get_dim(struct image_struct *s);
int image_get_depth(struct image_struct *s);
int *image_get_data_ptr(struct image_struct *s);

#endif // _include_image_h_
