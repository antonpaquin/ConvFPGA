from executor import Executor
from executor_lane import ExecutorLane, coords_regfile_size, LoadCoords, ConvOutput, MaxpoolOutput
from operation import Operation, noop
from reg_types import FilterChannel, ImageChannel, ImageCoords

filter_channel_regfile_size = 4
image_channel_regfile_size = 4
lanes_per_domain = 10


class ExecutorDomain(Executor):
    gid = 0

    def __init__(self, accel):
        super().__init__()
        self.accel = accel

        self.filter_channels = [FilterChannel(0, 0, 0) for _ in range(filter_channel_regfile_size)]
        self.image_channels = [ImageChannel(0, 0) for _ in range(image_channel_regfile_size)]

        self.lanes = [ExecutorLane(self) for _ in range(lanes_per_domain)]
        self.lane_coord_buffers = [0 for _ in range(lanes_per_domain)]

        self.iid = ExecutorDomain.gid
        ExecutorDomain.gid += 1

    def exec(self):
        cur = self.step_instruction()

        if cur == noop:
            pass

        elif isinstance(cur, ConvLayer):
            self.conv_layer(
                image_out=self.image_channels[cur.image_out],
                filtr_idx=cur.filtr_idx,
            )

        elif isinstance(cur, MaxpoolLayer):
            self.maxpool_layer(
                image_out=self.image_channels[cur.image_out],
                layer=cur.layer,
            )

        elif isinstance(cur, LoadFilterChannel):
            self.filter_channels[cur.target] = FilterChannel(
                start_address=cur.start_address,
                filter_dimension=cur.filter_dimension,
                num_channels_in=cur.num_channels_in,
            )

        elif isinstance(cur, LoadImageChannel):
            self.image_channels[cur.target] = ImageChannel(
                start_address=cur.start_address,
                row_length=cur.row_length,
            )

    def conv_layer(self, image_out: ImageChannel, filtr_idx: int):
        lane_idx = 0
        for yy in range(image_out.row_length):
            for xx in range(image_out.row_length):
                lane = self.lanes[lane_idx]
                coord_buffer = self.lane_coord_buffers[lane_idx]
                addr = image_out.start_address + image_out.row_length*yy + xx

                lane.enqueue(LoadCoords(coord_buffer, ImageCoords(x_pos=xx, y_pos=yy)))
                lane.enqueue(ConvOutput(
                    addr_out=addr,
                    coords=coord_buffer,
                    filtr=filtr_idx,
                ))

                self.lane_coord_buffers[lane_idx] = (coord_buffer + 1) % coords_regfile_size
                lane_idx = (lane_idx + 1) % lanes_per_domain

    def maxpool_layer(self, image_out: ImageChannel, layer: int):
        lane_idx = 0
        for yy in range(image_out.row_length):
            for xx in range(image_out.row_length):
                lane = self.lanes[lane_idx]
                coord_buffer = self.lane_coord_buffers[lane_idx]
                addr = image_out.start_address + image_out.row_length*yy + xx

                lane.enqueue(LoadCoords(coord_buffer, ImageCoords(x_pos=xx, y_pos=yy)))
                lane.enqueue(MaxpoolOutput(
                    addr_out=addr,
                    coords=coord_buffer,
                    layer=layer,
                ))

                self.lane_coord_buffers[lane_idx] = (coord_buffer + 1) % coords_regfile_size
                lane_idx = (lane_idx + 1) % lanes_per_domain

        pass

    def pre_enqueue(self, inst: Operation):
        print('\tdomain.{iid:02}: {op}'.format(
            iid=self.iid,
            op=inst,
        ))

    def post_enqueue(self, inst: Operation):
        self.exec_all()


class ConvLayer(Operation):
    def __init__(self, image_out: int, filtr_idx: int):
        super().__init__()
        self.image_out = image_out
        self.filtr_idx = filtr_idx

    def __str__(self):
        return 'conv.layer ic{image_out} fc{filtr}'.format(
            image_out=self.image_out,
            filtr=self.filtr_idx,
        )


class MaxpoolLayer(Operation):
    def __init__(self, image_out: int, layer: int):
        super().__init__()
        self.image_out = image_out
        self.layer = layer

    def __str__(self):
        return 'maxpool.layer ic{image_out} {layer}'.format(
            image_out=self.image_out,
            layer=self.layer,
        )


class LoadFilterChannel(Operation):
    def __init__(self, target: int, start_address: int, filter_dimension: int, num_channels_in: int):
        super().__init__()
        self.target = target
        self.start_address = start_address
        self.filter_dimension = filter_dimension
        self.num_channels_in = num_channels_in

    def __str__(self):
        return 'load.filterchannel fc{target} {start_address} {dimension} {num_channels_in}'.format(
            target=self.target,
            start_address=self.start_address,
            dimension=self.filter_dimension,
            num_channels_in=self.num_channels_in,
        )


class LoadImageChannel(Operation):
    def __init__(self, target: int, start_address: int, row_length: int):
        super().__init__()
        self.target = target
        self.start_address = start_address
        self.row_length = row_length

    def __str__(self):
        return 'load.imagechannel ic{target} {start_address} {row_length}'.format(
            target=self.target,
            start_address=self.start_address,
            row_length=self.row_length,
        )
