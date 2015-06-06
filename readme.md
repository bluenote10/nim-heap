Nim-Heap [![Build Status](https://travis-ci.org/bluenote10/nim-heap.svg?branch=master)](https://travis-ci.org/bluenote10/nim-heap)
========

This is a simple binary heap implementation, using a dynamic array (`seq`) as
backend. Apart from the standard functionality peek/push/pop it also provides
optimized versions for performing push+pop or pop+push, which can be handy for
fixed-sized priority queues. The code should be self-explanatory.
