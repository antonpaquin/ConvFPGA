#ifndef _include_driver_h_
#define _include_driver_h_

#include "image.h"
#include "filter.h"

void accel_open(void);
void accel_close(void);

void accel_set_image(struct image_struct *im);
void accel_set_filters(struct filter_struct **fi, int len);
struct image_struct *accel_run(void); // Caller must image_free()

#endif // _include_driver_h_
