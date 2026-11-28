---
title: "Binary search"
description: "Check your understanding of binary search, its precondition, the std.sort searches and boundaries."
group: "Data structures and algorithms"
order: 4
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 25-binary-search
competency: "I can sort and search, and measure what they cost"
---

# Binary search

**Read first:** [Binary search](/guide/data-structures/25-binary-search) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz About how many rounds does a binary search take over a million sorted items?
- [ ] 1 000 000
- [ ] 1 000
- [x] 20
- [ ] 1

Each round halves the range: 2²⁰ is about a million.
:::

::: quiz Course segments start at { 0, 4000, 6000, 8000 }. Which std.sort function answers "which segment is 5000 m on?" most directly?
- [ ] binarySearch
- [x] partitionPoint, counting the segments that start at or before 5000 (then minus one)
- [ ] upperBound with an exact compare
- [ ] std.mem.indexOfScalar

`binarySearch` looks for an exact match, and no segment starts at 5000. `partitionPoint` gives the count before
the boundary: 2, so segment 1.
:::

## Predict

The Guide's `countAtOrBefore` with `<` instead of `<=`:

```zig
if (starts[mid] < position_m) low = mid + 1 else high = mid;
```

Over starts `{ 0, 4000, 6000, 8000 }`, for positions −1, 0, 5000, 6000 and 9000:

::: quiz What does it give?
- [ ] 0 1 2 3 4
- [x] 0 0 2 2 4
- [ ] 0 1 2 2 4
- [ ] 1 1 2 3 4

With `<`, a start equal to the position doesn't count, so 0 and 6000 each give one fewer. A rider exactly at 6000 m
would be on the climb that ends there, not the descent that starts there: a boundary bug.
:::

## Fix it

```zig
const starts = [_]f64{ 6000, 0, 8000, 4000 };
std.debug.print("{any}\n", .{std.sort.binarySearch(f64, &starts, @as(f64, 4000), cmp)});
```

```text
null
```

4000 is in the list, and the search says it isn't.

::: quiz What's wrong?
- [x] The list isn't sorted: sort it first (or keep it sorted), because binary search assumes it is
- [ ] binarySearch only finds the first item
- [ ] cmp has its arguments the wrong way round
- [ ] 4000 needs to be a float literal

Binary search throws away half the list on the assumption that it's in order. On an unsorted list it gives wrong
answers silently, with no error.
:::

## Build it

### Exercise

Add `fn kmAt(position_m: f64) u32` to `Course`: which kilometre a position is in (0 for the first). Build a sorted
list of kilometre marks once (in `planMarks`, or a small slice on the course), and find the answer with
`std.sort.lowerBound` or `partitionPoint`. Tests first, at the boundaries: 0 m is km 0, 999.9 m km 0, 1000 m km 1,
the line itself the last km, past the line still the last.

```sh
zig build test --summary all
```
