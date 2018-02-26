from executor_accel import ExecutorAccel, LoadImageBuffer, LoadFilterBuffer, Conv, MaxPool
from test_inputs import filter_test, im_test
from reg_types import ImageBuffer, FilterBuffer
import memory

buf_in = ImageBuffer(0, 3, 3)
filtr = FilterBuffer(28, 3, 3, 2)
buf_in._load_image(im_test)
filtr._load_filter(filter_test)


executor = ExecutorAccel()
executor.enqueue(LoadImageBuffer(
    target=0,
    start_address=0,
    row_length=3,
    depth=3
))
executor.enqueue(LoadFilterBuffer(
    target=0,
    start_address=28,
    filter_dimension=3,
    num_channels_in=3,
    num_channels_out=2,
))
executor.enqueue(LoadImageBuffer(
    target=1,
    start_address=85,
    row_length=3,
    depth=2,
))
executor.enqueue(Conv(
    buffer_out=1,
    buffer_in=0,
    filtr=0,
))
executor.enqueue(LoadImageBuffer(
    target=0,
    start_address=104,
    row_length=2,
    depth=2,
))
executor.enqueue(MaxPool(
    buffer_out=0,
    buffer_in=1,
))

print('')
print('full memory dump')
for ii in range(20):
    for jj in memory.memory[ii*10:(ii+1)*10]:
        print(jj, end='\t')
    print('')
print('')

print('output after maxpool')
for ii in range(2):
    for jj in range(2):
        for kk in range(2):
            print(memory.memory[104 + 2*2*ii + 2*jj + kk], end='\t')
        print('')
    print('')
print('')

print('output before maxpool')
for ii in range(2):
    for jj in range(3):
        for kk in range(3):
            print(memory.memory[85 + 3*3*ii + 3*jj + kk], end='\t')
        print('')
    print('')
print('')
