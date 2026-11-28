---
title: "Sorting"
description: "Check your understanding of merge sort, std.mem.sort, stability, insertion sort and measuring."
group: "Data structures and algorithms"
order: 3
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 24-sorting
competency: "I can sort and search, and measure what they cost"
---

# Sorting

**Read first:** [Sorting](/guide/data-structures/24-sorting) in the Guide. This lesson checks you understood it.

## Recall

::: quiz Why does the game keep its order with insertion sort and not std.mem.sort?
- [ ] Insertion sort is always faster
- [ ] std.mem.sort isn't stable
- [x] After one second the order is nearly right, and insertion sort only moves the few riders who changed places; measured, it's faster for 8 riders
- [ ] Insertion sort needs no comparison function

On nearly sorted data insertion sort is close to `n`. On data that isn't (10 000 riders swapping places all the
time) it's `n²`, and the measurements showed the full sort winning there.
:::

::: quiz A list of finishers is sorted by team with std.mem.sortUnstable. What can happen to riders of the same team?
- [x] Their finishing order can be shuffled
- [ ] They're always kept in finishing order
- [ ] They're sorted by name
- [ ] Nothing: unstable sorts only differ in speed

Unstable means equal items may move relative to each other. Use `std.mem.sort` (stable), or compare the finishing
place as a second key.
:::

## Predict

```zig
fn ahead(pos: []const f64, a: usize, b: usize) bool {
    if (pos[a] != pos[b]) return pos[a] > pos[b];
    return a < b;
}

const positions = [_]f64{ 30, 50, 30, 10 };
var order = [_]usize{ 0, 1, 2, 3 };
std.mem.sort(usize, &order, @as([]const f64, &positions), ahead);
std.debug.print("{any}\n", .{order});
```

::: quiz What does it print?
- [ ] { 3, 0, 2, 1 }
- [ ] { 1, 2, 0, 3 }
- [x] { 1, 0, 2, 3 }
- [ ] { 50, 30, 30, 10 }

It sorts indexes, furthest first: index 1 (50 m), then 0 and 2 (both 30 m, the second key puts 0 first), then 3.
The positions themselves don't move.
:::

## Fix it

```zig
fn faster(a: f64, b: f64) bool {
    return a < b;
}

std.mem.sort(f64, &times_s, {}, faster);
```

```text
fx.zig:7:37: error: expected type 'fn (void, f64, f64) bool', found 'fn (f64, f64) bool'
fx.zig:7:37: note: function with 2 parameters cannot cast into a function with 3 parameters
```

::: quiz What's the fix?
- [x] Give faster a first parameter for the context: fn faster(_: void, a: f64, b: f64) bool
- [ ] Pass null instead of {}
- [ ] Call std.mem.sort(f64, &times_s, faster)
- [ ] Return std.math.Order instead of bool

The comparison always gets the context first; with `{}` as the context, its type is `void`, and `_` says it's not
used. `std.math.Order` is what a priority queue wants, not a sort.
:::

## Build it

### Exercise

Riders who didn't finish are placed by how far they got. Add the finishers' times: record each rider's finishing
second in `Race` (an array of `?u32`, set when its `finished` event happens, and keep stepping until everyone has
crossed). Then sort the results by time, and by name for riders on the same time. Test first: two riders on the
same second come out alphabetically, and a rider with no time comes after everyone with one.

```sh
zig build test --summary all
```
