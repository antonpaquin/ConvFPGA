from reg_types import ImageBuffer, FilterBuffer, FilterChannel, ImageChannel
from operation import Operation
from copy import deepcopy

from operation_conv_layer import ConvLayer


class Conv(Operation):
    def __init__(self, buffer_out: ImageBuffer, buffer_in: ImageBuffer, filtr: FilterBuffer):
        self.buffer_out = buffer_out
        self.buffer_in = buffer_in
        self.filtr = filtr

    def run_fpga(self):
        for channel_out_no in range(self.filtr.num_channels_out):
            filter_channel = FilterChannel(
                start_address=self.filtr.start_address + (channel_out_no * self.filtr.channel_length),
                filter_dimension=self.filtr.filter_dimension,
                num_channels_in=self.filtr.num_channels_in,
            )
            output_channel = ImageChannel(
                start_address=self.buffer_out.start_address + (channel_out_no * self.buffer_out.channel_length),
                row_length=self.buffer_out.row_length,
            )
            c = ConvLayer(image_out=output_channel, image_in=self.buffer_in, filtr=filter_channel)
            c.run_fpga()

    def run_python(self):
        img_in = self.buffer_in._get_image()
        filter_in = self.filtr._get_filter()

        fil_x = self.filtr.filter_dimension
        img_x = self.buffer_in.row_length
        img_y = self.buffer_in.row_length

        f_bound_low = fil_x - (fil_x // 2) - fil_x
        f_bound_high = fil_x - (fil_x // 2)

        output = []
        for output_z, filtr_channel_out in enumerate(filter_in):
            output_layer = (
                [
                    [
                        0
                        for _ in range(img_x)
                    ]
                    for _ in range(img_y)
                ]
            )
            for img_channel, filter_channel_in in zip(img_in, filtr_channel_out):
                for yy in range(img_y):
                    for xx in range(img_x):
                        for filter_y, offset_y in zip(filter_channel_in, range(f_bound_low, f_bound_high)):
                            for filter_weight, offset_x in zip(filter_y, range(f_bound_low, f_bound_high)):
                                ypos = yy + offset_y
                                xpos = xx + offset_x
                                if 0 <= xpos < img_x and 0 <= ypos < img_y:
                                    output_layer[yy][xx] += filter_weight * img_channel[ypos][xpos]
            output.append(deepcopy(output_layer))

        self.buffer_out._load_image(output)
