Nim-Heap [![Build Status](https://travis-ci.org/bluenote10/nim-heap.svg?branch=master)](https://travis-ci.org/bluenote10/nim-heap)
========

This is a simple binary heap implementation, using a dynamic array (`seq`) as
backend. Apart from the standard functionality peek/push/pop it also provides
optimized versions for performing push+pop or pop+push, which can be handy for
fixed-sized priority queues. The code should be self-explanatory.

A Partial Tour
--------------

Below is an example of how to use this module. It contains a few of the
procs available, but not all. Check out the source for the full set of
functionality.

```nimrod
import binaryheap

# Create a heap of ints
var heap = newHeap[int]() do (a, b: int) -> int:
    return a - b

# Push a bunch of values
heap.push(30)
heap.push(4)
heap.push(15)
heap.push(1)

# Prints "1" because our comparison function keeps the smallest value on top.
# This also removes the value from the heap
echo heap.pop

# Prints "4" and leaves the value on the heap
echo heap.peek

# Print all values in the heap in unsorted order
for item in heap:
    echo item
```
