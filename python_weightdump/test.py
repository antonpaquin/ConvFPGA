#! /usr/bin/python

from weight_dump import weight_dump

x = 0
test_filter = []

for depth in range(3):
    f_layer = []
    for dim_y in range(3):
        f_row = []
        for dim_x in range(3):
            f_row.append(10*x)
            x += 1
        f_layer.append(f_row)
    test_filter.append(f_layer)

weight_dump("test.fb", test_filter)


x = 0
test_image = []

for depth in range(3):
    i_layer = []
    for dim_y in range(5):
        i_row = []
        for dim_x in range(5):
            i_row.append(x)
            x += 1
        i_layer.append(i_row)
    test_image.append(i_layer)

weight_dump("test.ib", test_image)
