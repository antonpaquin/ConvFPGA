from reg_types import FilterChannel, ImageBuffer, Addr, ImageCoords
from operation import Operation, DSP
import memory


class ConvOutput(Operation):
    def __init__(self, addr_out: Addr, image_in: ImageBuffer, coords: ImageCoords, filtr: FilterChannel):
        self.addr_out = addr_out
        self.image_in = image_in
        self.coords = coords
        self.filtr = filtr

    def run_fpga(self):
        dsp = DSP()  # We'll have to assign this better -- as it is, this isn't synthesizable
        dsp.clear()

        filter_half_size = (2 if self.filtr.filter_dimension == 5 else 1)
        filter_offset_x = 0
        filter_offset_y = 0
        y_min_t = self.coords.y_pos - filter_half_size
        y_max_t = self.coords.y_pos + filter_half_size
        x_min_t = self.coords.x_pos - filter_half_size
        x_max_t = self.coords.x_pos + filter_half_size

        if y_min_t < 0:
            filter_offset_y = -y_min_t
            ymin = 0
        else:
            ymin = y_min_t
        ymax = y_max_t if y_max_t < self.image_in.row_length else (self.image_in.row_length - 1)
        if x_min_t < 0:
            filter_offset_x = -x_min_t
            xmin = 0
        else:
            xmin = x_min_t
        xmax = x_max_t if x_max_t < self.image_in.row_length else (self.image_in.row_length - 1)

        for zz in range(self.filtr.num_channels_in):
            for yy, iy in enumerate(range(ymin, ymax + 1)):
                for xx, ix in enumerate(range(xmin, xmax + 1)):
                    filter_weight = memory.memory[self.filtr.start_address + (zz*self.filtr.filter_length) + ((yy + filter_offset_y)*self.filtr.filter_dimension) + (xx + filter_offset_x)]
                    dsp.set_input_a(filter_weight)

                    img_activation = memory.memory[self.image_in.start_address + (zz*self.image_in.channel_length) + (iy*self.image_in.row_length) + ix]
                    dsp.set_input_b(img_activation)

                    dsp.mac()

        self.addr_out._load_value(dsp.get_output())

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
