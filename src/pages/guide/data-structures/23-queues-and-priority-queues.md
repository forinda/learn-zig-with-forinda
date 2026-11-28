---
title: "Queues and priority queues"
description: "Stacks, queues and priority queues: which item comes out next, a heap underneath, ordering with std.math.Order and breaking ties; linked lists and why arrays usually win."
group: "Data structures and algorithms"
order: 2
step: 23-queues
---

# Queues and priority queues

A course has places worth announcing: every kilometre, the foot of the climb, its top, "1 km to go". The game
finds them in whatever order is easy (all the kilometres, then the climbs), but it must announce them in the
order the leader reaches them. Three structures answer "which comes out next?" in three different ways, and
picking the right one is most of the work.

## Three orders

| Structure | Next out is | Add / take | In Zig |
|---|---|---|---|
| **stack** | the newest (last in, first out) | push and pop at one end | `ArrayList`: `append`, `pop` |
| **queue** | the oldest (first in, first out) | push at the back, take at the front | `std.Deque`: `pushBack`, `popFront` |
| **priority queue** | the smallest, by a rule you give | push anywhere, take the smallest | `std.PriorityQueue` |

```zig
for ("ABC") |c| try stack.append(gpa, c);   // pop: C B A
for ("ABC") |c| try queue.pushBack(gpa, c); // popFront: A B C
```

```text
stack: C B A
queue: A B C
```

A stack fits "undo" and "go back" (the last thing done is the first undone), nesting, and depth-first search. A
queue fits "in the order they arrived": inputs, messages, breadth-first search ([Graphs](/guide/data-structures/31-graphs)).

## A priority queue

A priority queue hands out the smallest item first, whatever order they went in. You give it the rule as a
function returning `std.math.Order` (`.lt`, `.eq`, `.gt`):

```zig
const Job = struct { at_m: f64, name: []const u8 };

fn nearer(_: void, a: Job, b: Job) std.math.Order {
    return std.math.order(a.at_m, b.at_m);
}

var pq: std.PriorityQueue(Job, void, nearer) = .empty;
defer pq.deinit(gpa);
try pq.push(gpa, .{ .at_m = 4000, .name = "a" });
while (pq.pop()) |job| { ... } // nearest first
```

The first parameter is a **context**, passed to every comparison; `void` when the rule needs nothing else.
`peek()` looks at the smallest without taking it; `count()` says how many are waiting.

### A heap underneath

It doesn't keep everything sorted. It keeps a **heap**: a tree stored in an array where every parent is smaller
than its children, so the smallest is always at index 0. A push or a pop moves one item up or down one branch:
`log n` steps, not `n`. Sorting the whole list after every push would be `n log n` each time.

### Ties come out in any order

A heap promises the smallest first, and nothing about equals. Three jobs at 4000 m, pushed as a, c, d:

```text
1000b 2000e 4000d 4000a 4000c
```

If the order of equals matters (and when you print it, it does), make the rule decide it: compare a second key
when the first is equal. `@backingInt` gives an enum value's number (older Zig called it `@intFromEnum`, and
`zig fmt` rewrites the old name to the new one).

```zig
fn nearer(_: void, a: Mark, b: Mark) std.math.Order {
    const by_distance = std.math.order(a.at_m, b.at_m);
    if (by_distance != .eq) return by_distance;
    return std.math.order(@backingInt(a.kind), @backingInt(b.kind));
}
```

## Linked lists

A **linked list** keeps items anywhere in memory, each pointing to the next (and, doubly linked, the previous).
Adding or removing next to a node you already have is O(1), with no shifting. Zig's lists are **intrusive**: the
`Node` (its `prev` and `next`) goes inside your own struct, and `@fieldParentPtr` gets back from the node to the
struct:

```zig
const Rider = struct { name: u8, node: std.DoublyLinkedList.Node = .{} };

var list: std.DoublyLinkedList = .{};
for (&riders) |*r| list.append(&r.node);
list.remove(&riders[1].node); // no search, no shifting
var it = list.first;
while (it) |node| : (it = node.next) {
    const rider: *Rider = @fieldParentPtr("node", node);
    std.debug.print("{c} ", .{rider.name});
}
```

```text
A C
```

The list allocates nothing: the riders are wherever they already are. That's when lists pay off: things that live
elsewhere and join and leave many lists (an operating system's tasks, a cache's entries). For most game data they
lose: each step is a jump to somewhere else in memory, and the processor is fastest on arrays read in order. The
game uses arrays.

::: tip Try it
Push five marks into a `std.PriorityQueue` with the plain `nearer` (distance only), three of them at the same
metre with different labels, and pop them all. Then add the second key and run it again.
:::

## Which order when

| You need the next item to be | Use | Because |
|---|---|---|
| the last one added | a stack (`ArrayList`) | undo, nesting, depth-first |
| the first one added | a queue (`Deque`) | fairness, arrival order, breadth-first |
| the smallest (or most urgent) | a priority queue | O(log n) push and pop |
| in sorted order, all at once, once | sort a list | simpler when nothing is added later |
| removed from the middle often, items owned elsewhere | an intrusive linked list | O(1) with the node in hand |

What goes wrong with the wrong one: a queue built on `ArrayList` takes from the front by shifting everything; a
list re-sorted after every push does `n log n` work for what a heap does in `log n`; a priority queue with no
tie-breaker prints equal items in an order that changes when the code around it does.

## In the game

Course marks: each kilometre, the foot and top of each climb, and "1 km to go", in a priority queue nearest first,
popped as the leader reaches them. Below the results code:

<<< @/code/steps/23-queues/src/main.zig#marks

`Event` reports a mark instead of a bare kilometre:

<<< @/code/steps/23-queues/src/main.zig#event

`Race` holds the marks still ahead:

<<< @/code/steps/23-queues/src/main.zig#marks-field

and `step` pops every one the leader has reached (in place of the old `next_km_m` check):

<<< @/code/steps/23-queues/src/main.zig#marks-step

In `playRace`, the marks are planned in the race's arena:

<<< @/code/steps/23-queues/src/main.zig#plan-marks

and printed: kilometres with the road, the others on a line of their own:

<<< @/code/steps/23-queues/src/main.zig#mark-print

The tests (the old km test now plans the marks), at the end of the file:

<<< @/code/steps/23-queues/src/main.zig#tests

Run it (or copy `code/steps/23-queues`):

```sh
zig build run
```

```text
km 4 at 6:25: leader is B
  --------------GB----------------------------------
  foot of the climb at 6:25
  H takes the lead
km 5 at 9:18: leader is H
...
km 6 at 11:51: leader is E
  ----------------------FE--------------------------
  top of the climb at 11:51
...
  1 km to go at 20:06
km 12 at 20:54: leader is H
```

At 4000 m, "km 4" and "foot of the climb" share a metre; the tie-breaker puts the kilometre first, every time.

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/23-queues/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/23-queues.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/data-structures/23-queues-and-priority-queues) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
