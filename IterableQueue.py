#
# Copied from http://stackoverflow.com/questions/11288158/python-iterable-queue
# Author: Raymond Hettinger
#
from queue import Queue

class IterableQueue(Queue): 

    _sentinel = object()

    def __iter__(self):
        return iter(self.get, self._sentinel)

    def close(self):
        self.put(self._sentinel)


