class Operation:
    pass


class DSP:
    def __init__(self):
        self.input_a = 0
        self.input_b = 0
        self.accumulator = 0

    def set_input_a(self, value):
        self.input_a = value

    def set_input_b(self, value):
        self.input_b = value

    def mac(self):
        self.accumulator += self.input_a * self.input_b

    def get_output(self):
        return self.accumulator

    def clear(self):
        self.accumulator = 0
