from reg_types import ImageBuffer, ImageChannel, FilterChannel, ImageCoords, Addr
from operation import Operation
from operation_conv_output import ConvOutput


class ConvLayer(Operation):
    def __init__(self, image_out: ImageChannel, image_in: ImageBuffer, filtr: FilterChannel):
        self.image_out = image_out
        self.image_in = image_in
        self.filtr = filtr

    def run_fpga(self):
        for yy in range(self.image_out.row_length):
            for xx in range(self.image_out.row_length):
                coords = ImageCoords(x_pos=xx, y_pos=yy)
                addr = Addr(address=self.image_out.start_address + self.image_out.row_length*yy + xx)
                c = ConvOutput(addr_out=addr, image_in=self.image_in, coords=coords, filtr=self.filtr)
                c.run_fpga()

    def run_python(self):
        filtr_channel = self.filtr._get_filter()
        img_in = self.image_in._get_image()

        fil_x = self.filtr.filter_dimension
        img_x = self.image_out.row_length
        img_y = self.image_out.row_length

        f_bound_low = fil_x - (fil_x // 2) - fil_x
        f_bound_high = fil_x - (fil_x // 2)

        output = (
            [
                [
                    0
                    for _ in range(img_x)
                ]
                for _ in range(img_y)
            ]
        )

        for img_channel, filter_channel_in in zip(img_in, filtr_channel):
            for yy in range(img_y):
                for xx in range(img_x):
                    for filter_y, offset_y in zip(filter_channel_in, range(f_bound_low, f_bound_high)):
                        for filter_weight, offset_x in zip(filter_y, range(f_bound_low, f_bound_high)):
                            ypos = yy + offset_y
                            xpos = xx + offset_x
                            if 0 <= xpos < img_x and 0 <= ypos < img_y:
                                output[yy][xx] += filter_weight * img_channel[ypos][xpos]

        self.image_out._load_image(output)

