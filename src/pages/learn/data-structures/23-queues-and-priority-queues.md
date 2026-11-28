---
title: "Queues and priority queues"
description: "Check your understanding of stacks, queues, priority queues, ties and linked lists."
group: "Data structures and algorithms"
order: 2
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 23-queues
competency: "I can pick the right data structure for a job and say why"
---

# Queues and priority queues

**Read first:** [Queues and priority queues](/guide/data-structures/23-queues-and-priority-queues) in the Guide.
This lesson checks you understood it.

## Recall

::: quiz Players' key presses must be handled in the order they were pressed. Which structure?
- [ ] A stack
- [x] A queue
- [ ] A priority queue
- [ ] A hash map

First in, first out: a queue (a `std.Deque`, `pushBack` and `popFront`). A stack would handle the last key first.
:::

::: quiz Three marks at the same metre come out of a std.PriorityQueue. In what order?
- [ ] The order they were pushed
- [ ] The reverse of the order they were pushed
- [x] Any order: a heap promises nothing about equals, unless the compare function breaks the tie
- [ ] Alphabetical

The heap only guarantees the smallest comes first. To make equal items come out in a fixed order, compare a
second key when the first is `.eq`.
:::

## Predict

```zig
for ("XYZ") |c| {
    try stack.append(gpa, c);
    try queue.pushBack(gpa, c);
}
_ = stack.pop();
_ = queue.popFront();
try stack.append(gpa, 'W');
try queue.pushBack(gpa, 'W');
std.debug.print("{c}{c}\n", .{ stack.pop().?, queue.popFront().? });
```

::: quiz What does it print?
- [ ] ZX
- [x] WY
- [ ] WW
- [ ] YW

The stack gives back the last in: W. The queue lost X, so its front is Y.
:::

## Fix it

```zig
fn nearer(_: void, a: Mark, b: Mark) bool {
    return a.at_m < b.at_m;
}

var marks: std.PriorityQueue(Mark, void, nearer) = .empty;
```

```text
fx.zig:7:46: error: expected type 'fn (void, fx.Mark, fx.Mark) math.Order', found 'fn (void, fx.Mark, fx.Mark) bool'
fx.zig:7:46: note: return type 'bool' cannot cast into return type 'math.Order'
```

::: quiz What's the fix?
- [x] Return std.math.order(a.at_m, b.at_m) and make the return type std.math.Order
- [ ] Return @intFromBool(a.at_m < b.at_m)
- [ ] Use std.mem.sort's lessThan instead
- [ ] Wrap the call: std.PriorityQueue(Mark, void, &nearer)

A priority queue's rule says less, equal or greater (`.lt`, `.eq`, `.gt`), not just "less or not": that's what
`std.math.Order` is. `std.mem.sort` takes the `bool` kind.
:::

## Build it

### Exercise

Add a sprint line to a course: a new `MarkKind`, `.sprint`, announced as "intermediate sprint", at a distance from
a new course line `sprint 6000` (`parseCourse` records it; `planMarks` pushes it). Test first: a course with
`sprint 6000` gets a sprint mark at 6000 m, and it comes out just after "km 6" (they share the metre; the
tie-breaker, kind order, puts kilometres first). Let the compiler show you each `switch` on `MarkKind` to update.

```sh
zig build test --summary all
```
