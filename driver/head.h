#ifndef _include_head_h_
#define _include_head_h_

#include "image.h"
#include "mat2d.h"

struct mat2d *head_fc(struct mat2d *a, struct mat2d *w, struct mat2d *b);
struct mat2d *head_softmax(struct mat2d *m);

#endif //_include_head_h_
