from reg_types import FilterChannel, ImageBuffer, Addr, ImageCoords
from operation import Operation


class ConvOutput(Operation):
    def __init__(self, addr_out: Addr, image_in: ImageBuffer, coords: ImageCoords, filtr: FilterChannel):
        self.addr_out = addr_out
        self.image_in = image_in
        self.coords = coords
        self.filtr = filtr

    def run_fpga(self):
        pass

    def run_python(self):
        filtr_channel = self.filtr._get_filter()

        fil_x = self.filtr.filter_dimension
        img_x = self.image_in.row_length
        img_y = self.image_in.row_length

        f_bound_low = fil_x - (fil_x // 2) - fil_x
        f_bound_high = fil_x - (fil_x // 2)

        output = 0

        for channel_id, filter_channel_in in enumerate(filtr_channel):
            for filter_y, offset_y in zip(filter_channel_in, range(f_bound_low, f_bound_high)):
                for filter_weight, offset_x in zip(filter_y, range(f_bound_low, f_bound_high)):
                    ypos = self.coords.y_pos + offset_y
                    xpos = self.coords.x_pos + offset_x
                    if 0 <= xpos < img_x and 0 <= ypos < img_y:
                        output += filter_weight * self.image_in._get_value(xpos, ypos, channel_id)

        self.addr_out._load_value(output)
