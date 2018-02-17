from memory import memory

# This more for clarity than any functionality
class Register:
    pass


class GlobalRegister(Register):
    def __init__(self, value):
        self.v = value

    def set(self, value):
        self.v = value

    def get(self):
        return self.v


class ImageBuffer(Register):
    def __init__(self, start_address, row_length, depth):
        self.start_address = start_address
        self.row_length = row_length
        self.channel_length = row_length ** 2
        self.depth = depth

    # DEBUG -- not for verilog
    def _get_image(self):
        img_x = self.row_length
        img_y = self.row_length
        img_z = self.depth
        img = (
            [
                [
                    [
                        memory[self.start_address + z*img_x*img_y + y*img_x + x]
                        for x in range(img_x)
                    ]
                    for y in range(img_y)
                ]
                for z in range(img_z)
            ]
        )
        return img

    # DEBUG -- not for verilog
    def _load_image(self, image):
        ii = self.start_address
        for channel in image:
            for row in channel:
                for value in row:
                    memory[ii] = value
                    ii += 1


class FilterBuffer(Register):
    def __init__(self, start_address, filter_dimension, num_channels_in, num_channels_out):
        self.start_address = start_address
        self.filter_dimension = filter_dimension
        self.filter_length = (filter_dimension ** 2) * num_channels_in
        self.num_channels_in = num_channels_in
        self.num_channels_out = num_channels_out

    def _get_filter(self):
        fil_x = self.filter_dimension
        fil_y = self.filter_dimension
        fil_z = self.num_channels_in
        fil_w = self.num_channels_out
        filtr = (
            [
                [
                    [
                        [
                            memory[self.start_address + w*fil_x*fil_y*fil_z + z*fil_y*fil_x + y*fil_x + x]
                            for x in range(fil_x)
                        ]
                        for y in range(fil_y)
                    ]
                    for z in range(fil_z)
                ]
                for w in range(fil_w)
            ]
        )
        return filtr

    def _load_filter(self, filtr):
        ii = self.start_address
        for channel_out in filtr:
            for channel_in in channel_out:
                for row in channel_in:
                    for value in row:
                        memory[ii] = value
                        ii += 1
