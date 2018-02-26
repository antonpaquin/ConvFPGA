from executor import Executor
from executor_domain import ExecutorDomain, filter_channel_regfile_size, \
    image_channel_regfile_size, LoadImageChannel, LoadFilterChannel, ConvLayer, MaxpoolLayer
from operation import Operation, noop
from reg_types import ImageBuffer, FilterBuffer

domains_per_accel = 22
imgbuffer_regfile_size = 2
filtrbuffer_regfile_size = 2


class ExecutorAccel(Executor):
    def __init__(self):
        super().__init__()
        self.domains = [ExecutorDomain(self) for _ in range(domains_per_accel)]
        self.domain_fchannel_ring = [0 for _ in range(domains_per_accel)]
        self.domain_ichannel_ring = [0 for _ in range(domains_per_accel)]

        self.image_buffers = [ImageBuffer(0, 0, 0) for _ in range(imgbuffer_regfile_size)]
        self.image = self.image_buffers[0]

        self.filter_buffers = [FilterBuffer(0, 0, 0, 0) for _ in range(filtrbuffer_regfile_size)]

    def exec(self):
        cur = self.step_instruction()

        if cur == noop:
            pass

        elif isinstance(cur, Conv):
            self.conv(
                buffer_out=self.image_buffers[cur.buffer_out],
                buffer_in_idx=cur.buffer_in,
                filtr=self.filter_buffers[cur.filtr],
            )

        elif isinstance(cur, MaxPool):
            self.maxpool(
                buffer_out=self.image_buffers[cur.buffer_out],
                buffer_in_idx=cur.buffer_in,
            )

        elif isinstance(cur, LoadFilterBuffer):
            self.filter_buffers[cur.target] = FilterBuffer(
                start_address=cur.start_address,
                filter_dimension=cur.filter_dimension,
                num_channels_in=cur.num_channels_in,
                num_channels_out=cur.num_channels_out,
            )

        elif isinstance(cur, LoadImageBuffer):
            self.image_buffers[cur.target] = ImageBuffer(
                start_address=cur.start_address,
                row_length=cur.row_length,
                depth=cur.depth,
            )

    def conv(self, buffer_out: ImageBuffer, buffer_in_idx: int, filtr: FilterBuffer):
        self.image = self.image_buffers[buffer_in_idx]

        domain_idx = 0
        for cc in range(filtr.num_channels_out):
            domain = self.domains[domain_idx]
            domain_fchannel_idx = self.domain_fchannel_ring[domain_idx]
            domain_ichannel_idx = self.domain_ichannel_ring[domain_idx]

            # Setup the output channel for this layer
            domain.enqueue(LoadImageChannel(
                target=domain_ichannel_idx,
                start_address=buffer_out.start_address + (cc*buffer_out.channel_length),
                row_length=buffer_out.row_length,
            ))

            # Take out the filter that will be used for this layer
            domain.enqueue(LoadFilterChannel(
                target=domain_fchannel_idx,
                start_address=filtr.start_address + (cc*filtr.channel_length),
                filter_dimension=filtr.filter_dimension,
                num_channels_in=filtr.num_channels_in,
            ))

            # And convolve
            domain.enqueue(ConvLayer(
                image_out=domain_ichannel_idx,
                filtr_idx=domain_fchannel_idx,
            ))

            self.domain_fchannel_ring[domain_idx] = (domain_fchannel_idx + 1) % filter_channel_regfile_size
            self.domain_ichannel_ring[domain_idx] = (domain_ichannel_idx + 1) % image_channel_regfile_size
            domain_idx = (domain_idx + 1) % domains_per_accel

    def maxpool(self, buffer_out: ImageBuffer, buffer_in_idx):
        self.image = self.image_buffers[buffer_in_idx]

        domain_idx = 0
        for cc in range(self.image.depth):
            domain = self.domains[domain_idx]
            domain_ichannel_idx = self.domain_ichannel_ring[domain_idx]

            # We're going to trivially assume maxpool(2,2) stride 2
            domain.enqueue(LoadImageChannel(
                target=domain_ichannel_idx,
                start_address=buffer_out.start_address + (cc*buffer_out.channel_length),
                row_length=buffer_out.row_length,
            ))
            domain.enqueue(MaxpoolLayer(
                image_out=domain_ichannel_idx,
                layer=cc,
            ))

            self.domain_ichannel_ring[domain_idx] = (domain_ichannel_idx + 1) % image_channel_regfile_size
            domain_idx = (domain_idx + 1) % domains_per_accel

        pass

    def pre_enqueue(self, inst: Operation):
        print(inst)

    def post_enqueue(self, inst: Operation):
        self.exec()


class Conv(Operation):
    def __init__(self, buffer_out: int, buffer_in: int, filtr: int):
        super().__init__()
        self.buffer_out = buffer_out
        self.buffer_in = buffer_in
        self.filtr = filtr

    def __str__(self):
        return 'conv ib{buffer_out} ib{buffer_in} fb{filtr}'.format(
            buffer_out=self.buffer_out,
            buffer_in=self.buffer_in,
            filtr=self.filtr,
        )


class MaxPool(Operation):
    def __init__(self, buffer_out: int, buffer_in: int):
        super().__init__()
        self.buffer_out = buffer_out
        self.buffer_in = buffer_in

    def __str__(self):
        return 'maxpool ib{buffer_out} ib{buffer_in}'.format(
            buffer_out=self.buffer_out,
            buffer_in=self.buffer_in,
        )


class LoadFilterBuffer(Operation):
    def __init__(self, target, start_address, filter_dimension, num_channels_in, num_channels_out):
        super().__init__()
        self.target = target
        self.start_address = start_address
        self.filter_dimension = filter_dimension
        self.num_channels_in = num_channels_in
        self.num_channels_out = num_channels_out

    def __str__(self):
        return 'load.filterbuffer fb{target} {start_address} {filter_dimension} {num_channels_in} {num_channels_out}'.format(
            target=self.target,
            start_address=self.start_address,
            filter_dimension=self.filter_dimension,
            num_channels_out=self.num_channels_out,
            num_channels_in=self.num_channels_in,
        )


class LoadImageBuffer(Operation):
    def __init__(self, target: int, start_address: int, row_length: int, depth: int):
        super().__init__()
        self.target = target
        self.start_address = start_address
        self.row_length = row_length
        self.depth = depth

    def __str__(self):
        return 'load.imagebuffer ib{target} {start_address} {row_length} {depth}'.format(
            target=self.target,
            start_address=self.start_address,
            row_length=self.row_length,
            depth=self.depth,
        )
