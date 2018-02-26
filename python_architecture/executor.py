from queue import Queue

from operation import Operation, noop


class Executor:
    def __init__(self):
        self.instruction_queue = Queue()
        self.queue_size = 0

    def step_instruction(self) -> Operation:
        # This could be implemented with registers -- on posedge step, each reg moves forward one space, and pop index 0
        if self.queue_size == 0:
            return noop
        else:
            self.queue_size -= 1
            return self.instruction_queue.get()

    def pre_enqueue(self, inst: Operation):
        pass

    def post_enqueue(self, inst: Operation):
        pass

    def enqueue(self, inst: Operation):
        self.pre_enqueue(inst)
        self.instruction_queue.put(inst)
        self.queue_size += 1
        self.post_enqueue(inst)

    def count_instructions_in_queue(self):
        return self.queue_size

    def exec(self):
        pass

    def exec_all(self):
        while self.queue_size > 0:
            self.exec()


