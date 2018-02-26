from executor import Executor
from executor_dsp import DSP, DspIncrement, DspRelu, DspMAC, DspClear
from reg_types import FilterChannel, ImageBuffer, Addr, ImageCoords
from operation import noop, Operation
import memory


coords_regfile_size = 2


class ExecutorLane(Executor):
    gid = 0

    def __init__(self, domain):
        super().__init__()
        self.dsp = DSP()
        self.domain = domain  # filter_channels
        self.coords = [ImageCoords(0, 0) for _ in range(coords_regfile_size)]

        self.iid = ExecutorLane.gid
        ExecutorLane.gid += 1

    # exec grabs an instruction, decodes it, and puts it on the queue of the next executor
    def exec(self):
        cur = self.step_instruction()

        if cur is noop:
            pass

        elif isinstance(cur, ConvOutput):
            self.conv_output(
                addr_out=Addr(cur.addr_out),
                image_in=self.domain.accel.image,
                coords=self.coords[cur.coords],
                filtr=self.domain.filter_channels[cur.filtr],
            )

        elif isinstance(cur, MaxpoolOutput):
            self.maxpool_output(
                addr_out=Addr(cur.addr_out),
                image_in=self.domain.accel.image,
                coords=self.coords[cur.coords],
                layer=cur.layer,
            )

        elif isinstance(cur, LoadCoords):
            self.coords[cur.target] = cur.coords

    def conv_output(self, addr_out: Addr, image_in: ImageBuffer, coords: ImageCoords, filtr: FilterChannel):
        self.dsp.enqueue(DspClear())
        filter_half_size = (2 if filtr.filter_dimension == 5 else 1)
        filter_offset_x = 0
        filter_offset_y = 0
        y_min_t = coords.y_pos - filter_half_size
        y_max_t = coords.y_pos + filter_half_size
        x_min_t = coords.x_pos - filter_half_size
        x_max_t = coords.x_pos + filter_half_size

        if y_min_t < 0:
            filter_offset_y = -y_min_t
            ymin = 0
        else:
            ymin = y_min_t
        ymax = y_max_t if y_max_t < image_in.row_length else (image_in.row_length - 1)
        if x_min_t < 0:
            filter_offset_x = -x_min_t
            xmin = 0
        else:
            xmin = x_min_t
        xmax = x_max_t if x_max_t < image_in.row_length else (image_in.row_length - 1)

        for zz in range(filtr.num_channels_in):
            for yy, iy in enumerate(range(ymin, ymax + 1)):
                for xx, ix in enumerate(range(xmin, xmax + 1)):
                    filter_weight = memory.memory[filtr.start_address + (zz*filtr.filter_length) + ((yy + filter_offset_y)*filtr.filter_dimension) + (xx + filter_offset_x)]
                    img_activation = memory.memory[image_in.start_address + (zz*image_in.channel_length) + (iy*image_in.row_length) + ix]
                    self.dsp.enqueue(DspMAC(
                        a=filter_weight,
                        b=img_activation,
                    ))

        self.dsp.enqueue(DspIncrement(
            bias=memory.memory[filtr.start_address + filtr.filter_length*filtr.num_channels_in]
        ))
        # TODO: Vikram will decide what leak factor we want (it should be an inverse exponent of 2)
        self.dsp.enqueue(DspRelu(leak=0))

        self.dsp.exec_all()

        addr_out._load_value(self.dsp.get_output())

    def maxpool_output(self, addr_out: Addr, image_in: ImageBuffer, coords: ImageCoords, layer: int):
        cx = lambda: (coords.x_pos * 2 + 1) < image_in.row_length
        cy = lambda: (coords.y_pos * 2 + 1) < image_in.row_length

        start = image_in.start_address + (layer*image_in.channel_length)
        row = image_in.row_length

        i0 = memory.memory[start + 2*row*coords.y_pos + 2*coords.x_pos]
        i1 = memory.memory[start + 2*row*coords.y_pos + 2*coords.x_pos + 1] if cx() else 0
        i2 = memory.memory[start + 2*row*coords.y_pos + row + 2*coords.x_pos] if cy() else 0
        i3 = memory.memory[start + 2*row*coords.y_pos + row + 2*coords.x_pos + 1] if cx() and cy() else 0

        addr_out._load_value(max([i0, i1, i2, i3]))

    def pre_enqueue(self, inst: Operation):
        print('\t\tlane.{iid:02}: {op}'.format(
            iid=self.iid,
            op=inst,
        ))

    def post_enqueue(self, inst: Operation):
        self.exec()


class LoadCoords(Operation):
    # ImageCoords (uint1), coords (uint8, uint8)
    def __init__(self, target: int, coords: ImageCoords):
        super().__init__()
        self.target = target
        self.coords = coords

    def __str__(self):
        return 'load.imagecoords ix{target} {x_pos} {y_pos}'.format(
            target=self.target,
            x_pos=self.coords.x_pos,
            y_pos=self.coords.y_pos,
        )


class ConvOutput(Operation):
    # Address (uint?), ImageBuffer (uint?), ImageCoords (uint1), filtr (uint?)
    def __init__(self, addr_out: int, coords: int, filtr: int):
        super().__init__()
        self.addr_out = addr_out
        self.coords = coords
        self.filtr = filtr

    def __str__(self):
        return 'conv.output {addr_out} ix{coords} fc{filtr}'.format(
            addr_out=self.addr_out,
            coords=self.coords,
            filtr=self.filtr,
        )


class MaxpoolOutput(Operation):
    def __init__(self, addr_out: int, coords: int, layer: int):
        super().__init__()
        self.addr_out = addr_out
        self.coords = coords
        self.layer = layer

    def __str__(self):
        return 'maxpool.output {addr_out} ix{coords} {layer}'.format(
            addr_out=self.addr_out,
            coords=self.coords,
            layer=self.layer,
        )
