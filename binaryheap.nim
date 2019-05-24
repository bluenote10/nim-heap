import strutils

# helper functions to calculate parent/child relationships
proc parentInd(i: int): int {.inline.} = (i-1) div 2
proc childLInd(i: int): int {.inline.} = 2*i + 1
proc childRInd(i: int): int {.inline.} = 2*i + 2


type
  # defining this causes strange Nim bugs
  # CompareProc[T] = proc (x: T, y: T): int

  Heap*[T] = object
    data: seq[T]
    size: int
    comp: proc (x: T, y: T): int {.gcsafe.} # CompareProc[T], why int not byte?

  EmptyHeapError* = object of Exception



proc size*[T](h: Heap[T]): int {.inline.} = h.size
  ## returns the size of a heap.


proc hasChildAt[T](h: Heap[T], i: int): bool {.inline.} =
  ## similar to hasIndex but if we already have the parent it suffices to check.
  i < h.size

proc hasParentAt[T](h: Heap[T], i: int): bool {.inline.} =
  ## similar to hasIndex but if we already have the child it suffices to check.
  0 <= i


proc indicesWithChildren*[T](h: Heap[T]): Slice[int] {.inline.} =
  ## helper function returning a slice of nodes with children
  ## Useful, since some iterations can be omitted for leaves.
  let lastIndexWithChildren = (h.size div 2) - 1
  0 .. lastIndexWithChildren



proc propFulfilled[T](h: Heap[T], indParent, indChild: int): bool {.inline.} =
  ## checks the heap property between a given parent/child pair.
  h.comp(h.data[indParent], h.data[indChild]) <= 0


template assertHeapProperty[T](h: Heap[T], enabled = true) =
  ## only for debugging: explicit check if the heap property
  ## is fulfilled for all nodes
  when enabled:
    for i in h.indicesWithChildren:
      # note: we only know that i has a left child
      # the right child is optional and requires a check
      let j = childLInd(i)
      let k = childRInd(i)
      #echo i, j, k
      if not h.propFulfilled(i, j):
        raise newException(AssertionError, format(
          "Propertiy not fulfilled for $#, $# values $#, $#",
          i, j, h.data[i], h.data[j]
        ))
      if h.hasChildAt(k) and not h.propFulfilled(i, k):
        raise newException(AssertionError, format(
          "Propertiy not fulfilled for $#, $# values $#, $#",
          i, k, h.data[i], h.data[k]
        ))


proc swap[T](h: var Heap[T], i, j: int) {.inline.} =
  ## swaps two nodes in the heap.
  let t = h.data[j]
  h.data[j] = h.data[i]
  h.data[i] = t
  #echo "swapping ", i, " with ", j



proc siftup[T](h: var Heap[T], i: int) =
  ## establishes heap property "upwards".
  let j = i.parentInd
  if h.hasParentAt(j) and not h.propFulfilled(j,i):
    h.swap(i,j)
    h.siftup(j)

proc siftdown[T](h: var Heap[T], i: int) =
  ## establishes heap property "downwards".
  let j = i.childLInd
  let k = i.childRInd
  # Note: Most often we have both children, since siftdown is commonly called
  # for the root (after swapping it for removal). Therefore, we check for this
  # first:
  if h.hasChildAt(j) and h.hasChildAt(k):
    # any child violated the heap property?
    if not h.propFulfilled(i,j) or not h.propFulfilled(i,k):
      # is j a valid parent of k => swap i with j
      if h.propFulfilled(j,k):
        h.swap(i,j)
        h.siftdown(j)
      # otherwise k must be the valid parent
      else:
        h.swap(i,k)
        h.siftdown(k)
  elif h.hasChildAt(j):
    if not h.propFulfilled(i,j):
      h.swap(i,j)
      h.siftdown(j)
  # no children, no hassle



proc newHeap*[T](comparator: proc (x: T, y: T): int): Heap[T] =
  ## constructs an empty heap using an explicit comparator.
  Heap[T](data: newSeq[T](), size: 0, comp: comparator)



proc newHeapFromArray*[T](arr: openarray[T], comparator: proc (x: T, y: T): int = system.cmp): Heap[T] =
  ## constructs a heap from a given openarray. This performs
  ## the famous heapify algorithm with a complexity of O(N).

  # in order to convert from openarray to seq, we fill manually
  var h = Heap[T](data: newSeq[T](arr.len), size: arr.len, comp: comparator)
  for i, x in arr:
    h.data[i] = x
  let indicesWithChildren = h.indicesWithChildren
  for i in countdown(indicesWithChildren.b, indicesWithChildren.a):
    h.siftdown(i)
    #debug i, h.data

  result = h



proc peek*[T](h: Heap[T]): T = h.data[0]
  ## returns the element with highest priority
  ## without removing it.


proc push*[T](h: var Heap[T], x: T) =
  ## push (enqueue) an element in the heap
  h.data.add(x)
  h.siftup(h.size)
  h.size.inc
  h.assertHeapProperty(defined(debugHeaps))

proc pop*[T](h: var Heap[T]): T =
  ## pop (dequeue) the min/max element of the heap
  if not h.size > 0:
    raise newException(EmptyHeapError, "cannot pop element, heap is empty")
  # store root for return
  result = h.data[0]
  # make last node the new root
  h.data[0] = h.data[^1] # TODO handle root == last
  # handle size modification
  h.size.dec
  h.data.setlen(h.size)
  # restore heap property
  h.siftdown(0)
  h.assertHeapProperty(defined(debugHeaps))


proc pushPop*[T](h: var Heap[T], x: T): (bool, T) =
  ## Optimized version of performing a push + pop.
  ##
  ## Technical note:
  ## If the new inserted element ``x`` is a proper parent
  ## of the current root, a manual push + pop would lead to:
  ##   (1) push ``x`` would "siftup" ``x``
  ##       making it the new root.
  ##   (2) pop would return just ``x`` leading
  ##       to a "siftdown" of some swapped leaf.
  ## This combined function avoids this. It returns
  ## the whether the new element has been stored and
  ## the value that has been popped.
  if h.size == 0:
    return (false, x)
  elif h.comp(x, h.data[0]) <= 0: # cannot call propFulfilled, since x has no index yet
    return (false, x)
  else:
    # x will not end up as new root, but is actually stored
    result = (true, h.data[0])
    h.data[0] = x
    h.siftdown(0)


proc popPush*[T](h: var Heap[T], x: T): T =
  ## Optimized version of performing a pop + push.
  ##
  ## Technical note:
  ## A regular pop + push would require
  ##   (1) a siftdown of the swapped leaf when
  ##       popping the root
  ##   (2) a siftup of the inserted value
  ## This combined functions avoids this by
  ## using the inserted ``x`` directly for
  ## the siftdown instead of another leaf.
  if not h.size > 0:
    raise newException(EmptyHeapError, "cannot pop element, heap is empty")
  result = h.data[0]
  h.data[0] = x
  h.siftdown(0)



iterator items*[T](h: Heap[T]): T =
  ## iterates over all items in the heap in _unsorted_ order
  ## (i.e., items are generated in O(1)).
  for x in h.data:
    yield x

iterator sortedItems*[T](h: Heap[T]): T =
  ## iterates over all items in the heap in sorted order.
  ## Items are generated in O(log N), resulting in a
  ## traditional heap sort.
  var tmp = h
  while tmp.size > 0:
    let x = tmp.pop
    yield x






when isMainModule:
  import unittest
  import math
  import random
  import algorithm
  import sequtils

  proc randomData[T](N: int, maxVal: T): seq[T] =
    result = newSeq[T](N)
    for i in 0 ..< N:
      result[i] = rand(maxVal-1)

  const iterations = 1 .. 100

  suite "Heap":

    test "relation parent/child":
      assert childLInd(0) == 1
      assert childRInd(0) == 2
      assert parentInd(1) == 0
      assert parentInd(2) == 0
      for N in 0 .. 100:
        assert N == N.childLInd.parentInd
        assert N == N.childRInd.parentInd
      for N in 1 .. 100:
        if N mod 2 == 1:
          assert N == N.parentInd.childLInd
        else:
          assert N == N.parentInd.childRInd

    test "push/pop":
      for iter in iterations:
        randomize(iter)
        for N in [1, 10, 100]:
          var h = newHeap[int](system.cmp)
          for i in 1..N:
            h.push(rand(99))
            h.assertHeapProperty
          for i in 1..N:
            discard h.pop
            h.assertHeapProperty
          h.assertHeapProperty

    test "heapify":
      for iter in iterations:
        for N in [10, 100]:
          let data = randomData(N, 100)
          let h = newHeapFromArray[int](data) # removing [T] causes internal error! report?
          h.assertHeapProperty
          let sorted1 = data.sorted(system.cmp)
          let sorted2 = toSeq(h.sortedItems)
          check sorted1 == sorted2

    test "pushPop":
      for iter in iterations:
        randomize(iter)
        for N in [1, 10, 100]:
          var h1 = newHeap[int](system.cmp)
          var h2 = newHeap[int](system.cmp)
          # prefill both
          for i in 1..N:
            let x = rand(99)
            h1.push(x)
            h2.push(x)
          for i in 1..1000:
            let x = rand(99)
            h1.push(x)
            let y1 = h1.pop
            let (_, y2) = h2.pushPop(x)
            check y1 == y2
          let sorted1 = toSeq(h1.sortedItems)
          let sorted2 = toSeq(h2.sortedItems)
          check sorted1 == sorted2

    test "popPush":
      for iter in iterations:
        randomize(iter)
        for N in [1, 10, 100]:
          var h1 = newHeap[int](system.cmp)
          var h2 = newHeap[int](system.cmp)
          # prefill both
          for i in 1..N:
            let x = rand(99)
            h1.push(x)
            h2.push(x)
          for i in 1..1000:
            let x = rand(99)
            let y1 = h1.pop
            h1.push(x)
            let y2 = h2.popPush(x)
            check y1 == y2
          let sorted1 = toSeq(h1.sortedItems)
          let sorted2 = toSeq(h2.sortedItems)
          check sorted1 == sorted2
