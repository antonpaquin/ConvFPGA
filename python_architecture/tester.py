from operation_conv import Conv
from reg_types import ImageBuffer, FilterBuffer
import memory
import reg_types
from copy import deepcopy

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


buf_in = ImageBuffer(0, 3, 3)
filtr = FilterBuffer(28, 3, 3, 2)
buf_out = ImageBuffer(83, 3, 2)

buf_in._load_image(im_test)
filtr._load_filter(filter_test)

c = Conv(buf_out, buf_in, filtr)
c.run_python()
out_py = deepcopy(buf_out._get_image())

print('Mem check, should be some value')
print(sum(memory.memory[:1000]))
memory.clear()
print('Mem check, should be 0')
print(sum(memory.memory[:1000]))
print('')

buf_in._load_image(im_test)
filtr._load_filter(filter_test)

c = Conv(buf_out, buf_in, filtr)
c.run_fpga()
out_vg = deepcopy(buf_out._get_image())

print('Printing output:')
for img in out_vg:
    for row in img:
        print(row)
    print('')

print('Memory dump')
for i in range(15):
    print('\t'.join([str(x) for x in memory.memory[i*10:i*10+10]]))

if out_py == out_vg:
    print('I think they match!')
else:
    print('Mismatch!')
    print('fpga / python')
    for vg_channel, py_channel in zip(out_vg, out_py):
        for vg_row, py_row in zip(vg_channel, py_channel):
            print(vg_row, end='\t')
            print(py_row)
        print('')
