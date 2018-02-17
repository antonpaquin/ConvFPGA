from operation_conv import Conv
from reg_types import ImageBuffer, FilterBuffer

im_test = (
    [
        [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ],
        [
            [10, 20, 30],
            [40, 50, 60],
            [70, 80, 90],
        ],
        [
            [100, 200, 300],
            [400, 500, 600],
            [700, 800, 900],
        ],
    ]
)
buf_in = ImageBuffer(0, 3, 3)
buf_in._load_image(im_test)

filter_test = (
    [
        [
            [
                [1, 1, 1],
                [1, 1, 1],
                [1, 1, 1],
            ],
            [
                [.2, .2, .2],
                [.2, .2, .2],
                [.2, .2, .2],
            ],
            [
                [.3, .3, .3],
                [.3, .3, .3],
                [.3, .3, .3],
            ],
        ],
        [
            [
                [0, 1, 0],
                [0, 0, 0],
                [0, 0, 0],
            ],
            [
                [0, 1, 0],
                [0, 0, 0],
                [0, 0, 0],
            ],
            [
                [0, 1, 0],
                [0, 0, 0],
                [0, 0, 0],
            ]
        ]
    ]
)
filtr = FilterBuffer(28, 3, 3, 2)
filtr._load_filter(filter_test)

buf_out = ImageBuffer(83, 3, 2)

c = Conv(buf_out, buf_in, filtr)
c.run_python()

out = buf_out._get_image()
for oo in out:
    for row in oo:
        print(row)
    print('')
