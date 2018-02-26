from executor import Executor
from operation import Operation, noop


class DSP(Executor):
    gid = 0

    def __init__(self):
        super().__init__()

        self.accumulator = 0

        self.iid = DSP.gid
        DSP.gid += 1

    def exec(self):
        cur = self.step_instruction()
        if cur is noop:
            pass
        elif isinstance(cur, DspMAC):
            self.accumulator += cur.a * cur.b
        elif isinstance(cur, DspIncrement):
            self.accumulator += cur.bias
        elif isinstance(cur, DspClear):
            self.accumulator = 0
        elif isinstance(cur, DspRelu):
            if self.accumulator < 0:
                self.accumulator = self.accumulator * cur.leak

    def get_output(self):
        return self.accumulator

    def pre_enqueue(self, inst: Operation):
        print('\t\t\tdsp.{iid:03} {op}'.format(
            iid=self.iid,
            op=inst,
        ))

    def post_enqueue(self, inst: Operation):
        self.exec()


class DspMAC(Operation):
    def __init__(self, a: float, b: float):
        super().__init__()
        self.a = a
        self.b = b

    def __str__(self):
        return 'dsp.mac {a} {b}'.format(
            a=self.a,
            b=self.b,
        )


class DspIncrement(Operation):
    def __init__(self, bias: int):
        super().__init__()
        self.bias = bias

    def __str__(self):
        return 'dsp.increment {bias}'.format(
            bias=self.bias,
        )


class DspClear(Operation):
    def __init__(self):
        super().__init__()

    def __str__(self):
        return 'dsp.clear'


class DspRelu(Operation):
    def __init__(self, leak):
        super().__init__()
        self.leak = leak

    def __str__(self):
        return 'dsp.relu {leak}'.format(
            leak=self.leak,
        )
