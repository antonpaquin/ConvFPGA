#ifndef _include_filter_h_
#define _include_filter_h_

struct filter_struct;

struct filter_struct *filter_alloc(int kernel_size, int depth, int stride, int bias);
void filter_free(struct filter_struct *s);

int filter_get_len(struct filter_struct *s);
int filter_get_kernel_size(struct filter_struct *s);
int filter_get_depth(struct filter_struct *s);
int filter_get_stride(struct filter_struct *s);
int filter_get_bias(struct filter_struct *s);

int *filter_get_data_ptr(struct filter_struct *s);

#endif // _include_filter_h_
