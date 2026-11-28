---
title: "Sorting"
description: "Merge sort by hand, std.mem.sort and sortUnstable, comparison functions with a context, several keys, insertion sort on nearly sorted data, and measuring which is faster."
group: "Data structures and algorithms"
order: 3
step: 24-sorting
---

# Sorting

"Leader is H" says who's first. Who's second? Who's last? A results table needs the whole field in order, and so
does the commentary every kilometre. Sorting eight riders once is nothing. Sorting them every second, for twenty
minutes, for every race, starts to matter, and the obvious way (sort them all again from scratch) isn't always
the best. This page writes a sort by hand, then uses the standard library's, and measures instead of guessing.

## Merge sort, by hand

Split the list in half, sort each half (the same way, by **recursion**), then **merge**: walk both halves at once,
always taking the smaller front item.

```zig
fn mergeSort(items: []u32, scratch: []u32) void {
    if (items.len <= 1) return; // one item is already sorted: the recursion stops here
    const mid = items.len / 2;
    mergeSort(items[0..mid], scratch[0..mid]);
    mergeSort(items[mid..], scratch[mid..]);
    var i: usize = 0;
    var j: usize = mid;
    for (scratch[0..items.len]) |*out| {
        const take_left = j == items.len or (i < mid and items[i] <= items[j]);
        out.* = if (take_left) items[i] else items[j];
        if (take_left) i += 1 else j += 1;
    }
    @memcpy(items, scratch[0..items.len]);
}
```

```text
{ 1250, 1250, 1290, 1303, 1388, 1411 }
```

That's **divide and conquer**: a big problem made of smaller copies of itself. Each level of halving does `n`
work merging, and there are `log₂ n` levels: `n log n` in all, whatever the input. The `<=` (not `<`) takes the left
item when two are equal, so equal items keep their order: the sort is **stable**.

## std.mem.sort

You'll rarely write your own. `std.mem.sort` takes the item type, the slice, a **context**, and a function that says
whether `a` goes before `b`:

```zig
fn fasterThan(_: void, a: f64, b: f64) bool {
    return a < b;
}
std.mem.sort(f64, &times_s, {}, fasterThan);
```

The context is passed to every comparison, so the rule can use data that isn't in the items. The game sorts
*indexes* of riders, and the context is the riders themselves:

```zig
fn aheadOf(field: []const Rider, a: usize, b: usize) bool {
    if (field[a].position_m != field[b].position_m) return field[a].position_m > field[b].position_m;
    return a < b; // level on the road: letter order
}
std.mem.sort(usize, order, riders, aheadOf);
```

A second key (`return a < b`) decides ties, so the order never depends on how the sort happened to move things.

### Stable or not

| Function | Equal items | Speed |
|---|---|---|
| `std.mem.sort` | keep their order (stable) | fast |
| `std.mem.sortUnstable` | may be shuffled | usually faster, no extra memory |
| `std.sort.insertion` | keep their order | fast only when nearly sorted |

Forty riders in finishing order, sorted by team (three teams), first eight places of the first team:

```text
stable:   1 4 7 10 13 16 19 22
unstable: 19 40 37 4 34 28 7 25
```

Stable keeps finishing order inside the team; unstable doesn't. If you need "by team, then by place", either sort
stably, or put both keys in the rule (then stability doesn't matter).

## Insertion sort, and nearly sorted data

**Insertion sort** takes each item and slides it left past the bigger ones before it. On random data that's
`n²`. But riders rarely swap places in one second: the order from a second ago is almost right, and insertion sort
on almost-sorted data only moves the few that changed: close to `n`.

```zig
std.sort.insertion(usize, self.order, self.riders, aheadOf); // the order from last second, fixed up
```

## Measure, don't guess

`std.Io.Timestamp` reads a clock; `untilNow` says how long since:

```zig
const t0: std.Io.Timestamp = .now(io, .awake);
std.mem.sort(usize, order, positions, ahead);
total_ns += t0.untilNow(io, .awake).nanoseconds;
```

Fields of 8, 1 000 and 10 000 riders, moved on one second at a time, the order fixed up every second both ways
(on the machine this course was written on; your numbers will differ, the shape shouldn't):

```text
debug:
     8 riders: sort every tick       0.6 us/tick, insertion       0.2 us/tick
  1000 riders: sort every tick     141.8 us/tick, insertion      75.3 us/tick
 10000 riders: sort every tick    4253.6 us/tick, insertion   15283.7 us/tick
fast:
  1000 riders: sort every tick       9.2 us/tick, insertion      18.4 us/tick
 10000 riders: sort every tick     393.5 us/tick, insertion    4319.0 us/tick
```

For the game's eight riders, insertion sort wins. With ten thousand riders packed onto the same road, so many swap
places every second that "nearly sorted" stops being true, and insertion sort's `n²` side shows: the full sort wins
by ten times. Same algorithms, different data, opposite answer. The **big-O** (`n log n`, `n²`) tells you how the
cost grows; only measuring tells you where your data sits.

Measure in the build you ship: a `fast` build changed the 1 000-rider answer.

::: tip Try it
Run the merge sort above on 20 random numbers (`std.Random.DefaultPrng.init(1)` makes a reproducible random
source; `random().intRangeAtMost(u32, 0, 99)` a number). Then change `<=` to `<` in the merge and sort pairs that
share a key: is it still stable?
:::

## Which sort when

| You have | Use | Because |
|---|---|---|
| any list, sorted once | `std.mem.sort` | stable, `n log n` |
| no need for stability, big data | `std.mem.sortUnstable` | faster, no extra memory |
| a list that was sorted and changed a little | `std.sort.insertion` | close to `n` when few items moved |
| a sorted list you keep adding to | insert in place (binary search for where) | no re-sort at all |
| a stream where you only need the smallest | a priority queue | `log n` per item |

## In the game

The race keeps its order: rider indexes, leader first, fixed up with insertion sort after every second. `Race`
gains the order:

<<< @/code/steps/24-sorting/src/main.zig#order-field

made when the race starts tracking it (letter order to begin with):

<<< @/code/steps/24-sorting/src/main.zig#track-order

kept up in `step`, after everyone has moved:

<<< @/code/steps/24-sorting/src/main.zig#sort-step

The rule and the results table, above the marks:

<<< @/code/steps/24-sorting/src/main.zig#order

In `playRace`, the race tracks its order (each kilometre line now names the next two as well):

<<< @/code/steps/24-sorting/src/main.zig#track

and prints the results after the finale:

<<< @/code/steps/24-sorting/src/main.zig#results-use

The tests compare the insertion-sorted order with a fresh full sort after every second of a whole race:

<<< @/code/steps/24-sorting/src/main.zig#tests

Run it (or copy `code/steps/24-sorting`):

```sh
zig build run
```

```text
km 5 at 9:18: leader is H, then A, D
...
results:
   1  H  Heap      21:43
   2  B  Buffer    +88 m
   3  A  Alloc     +125 m
   4  D  Defer     +127 m
   5  F  Flush     +152 m
   6  G  Generic   +164 m
   7  C  Comptime  +219 m
   8  E  Errdefer  +242 m
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/24-sorting/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/24-sorting.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/data-structures/24-sorting) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
