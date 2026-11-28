---
title: "Binary search"
description: "Halving a sorted list: binary search by hand, partitionPoint, lowerBound, upperBound and binarySearch, the boundaries where bugs live, and linear vs binary measured."
group: "Data structures and algorithms"
order: 4
step: 25-binary-search
---

# Binary search

Every second, every rider asks the course: what's under my wheels? The course answers by walking its segments from
the start until it finds the right one. Compile Pass has four, so that's quick. A real stage has hundreds of
segments; a road mapped every 10 metres has thousands; ask that for every rider every second and the walking adds
up. The segments are already in order of where they start. In a sorted list, you never need to walk: look in the
middle, and throw away the half that can't hold the answer.

## Halving

To find which segment a position is on, count how many segments start at or before it. Keep a range `low..high`
where the boundary must be, and halve it until it's empty:

```zig
fn countAtOrBefore(starts: []const f64, position_m: f64) usize {
    var low: usize = 0; // everything before low starts at or before position_m
    var high: usize = starts.len; // everything from high on starts after it
    while (low < high) {
        const mid = low + (high - low) / 2;
        if (starts[mid] <= position_m) low = mid + 1 else high = mid;
    }
    return low;
}
```

With starts `{ 0, 4000, 6000, 8000 }`, positions −1, 0, 5000, 6000 and 9000 give:

```text
0 1 2 3 4
```

The segment is the count minus one; a count of 0 means "before the first segment". Each round halves the range:
a thousand segments take 10 rounds, a million take 20. That's `log₂ n`, against `n` for walking.

`low + (high - low) / 2` instead of `(low + high) / 2`: the same number, but it can't overflow when both are large.

### The precondition: sorted

Binary search on an unsorted list doesn't fail loudly: it returns a wrong answer. If the list might not be sorted,
check it (`std.sort.isSorted`) in a test, or sort it first.

## In the standard library

| Function | Returns | For |
|---|---|---|
| `std.sort.partitionPoint(T, items, ctx, pred)` | the first index where `pred` is false | "how many come before", like `countAtOrBefore` |
| `std.sort.lowerBound(T, items, ctx, cmp)` | the first index not less than the target | where to insert to stay sorted (before equals) |
| `std.sort.upperBound(T, items, ctx, cmp)` | the first index greater than the target | where to insert after equals |
| `std.sort.binarySearch(T, items, ctx, cmp)` | `?usize`: an index of an exact match | "is it there?" |

`partitionPoint` takes a `bool` predicate; the others take a function returning `std.math.Order` that compares the
target (the context) with an item:

```zig
fn cmp(target: f64, item: f64) std.math.Order {
    return std.math.order(target, item);
}
```

With the same starts:

```text
exact 6000: 2  exact 5000: null
lower 6000: 2  upper 6000: 3  lower 5000: 2
```

### Boundaries

Every binary search bug is at an edge: exactly on a start (is 6000 on segment 2 or 3?), before the first, past the
last, an empty list. Decide what each edge means, write a test for each, and use `<=` or `<` on purpose:
`partitionPoint` with `start <= position` puts 6000 on the segment that *starts* at 6000.

::: tip Try it
Change `<=` to `<` in `countAtOrBefore` and run the five positions again. Which ones change, and which segment
would a rider at exactly 6000 m now be on?
:::

## Linear or binary: measured

100 000 lookups at spread-out positions, in a `fast` build (on the machine this course was written on):

```text
      4 segments: linear       1.7 ns/lookup, binary    2.2 ns/lookup
   1000 segments: linear     128.6 ns/lookup, binary   14.2 ns/lookup
 100000 segments: linear   11747.4 ns/lookup, binary   40.9 ns/lookup
```

With four segments, walking wins: there's nothing to skip, and a straight loop is the simplest thing a processor
can run. With a thousand, binary search is nine times faster; with a hundred thousand, nearly three hundred. The
game switches anyway, because courses will grow (Part 9 loads them from files) and the answer has to be right at
every boundary either way.

## Which search when

| You have | Use | Because |
|---|---|---|
| a short list, or unsorted | a linear scan | nothing to gain, no precondition |
| a sorted list, "which range is this in?" | `partitionPoint` | the count before the boundary |
| a sorted list, "is it here?" | `binarySearch` | exact match or `null` |
| a sorted list you insert into | `lowerBound`/`upperBound` for where | stays sorted, no re-sort |
| lookups by key, no order needed | a hash map | O(1), no sorting |

## In the game

`Course` finds a position's segment with `partitionPoint`, and `terrainAt` uses it. In `Course`, replacing the old
`terrainAt`:

<<< @/code/steps/25-binary-search/src/main.zig#search

The tests keep the old linear scan as the reference and check every boundary, on Compile Pass and on a course of a
thousand segments:

<<< @/code/steps/25-binary-search/src/main.zig#tests

Run it (or copy `code/steps/25-binary-search`). The race is exactly the same as the last step's: the answer didn't
change, only how it's found.

```sh
zig build run
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/25-binary-search/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/25-binary-search.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/data-structures/25-binary-search) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
