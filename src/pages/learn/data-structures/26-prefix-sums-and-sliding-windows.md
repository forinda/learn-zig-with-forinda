---
title: "Prefix sums and sliding windows"
description: "Check your understanding of prefix sums, the off-by-one, fixed windows and two pointers."
group: "Data structures and algorithms"
order: 5
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 26-prefix-sums
competency: "I can solve a problem with prefix sums, windows or dynamic programming"
---

# Prefix sums and sliding windows

**Read first:** [Prefix sums and sliding windows](/guide/data-structures/26-prefix-sums-and-sliding-windows) in the
Guide. This lesson checks you understood it.

## Recall

::: quiz When do prefix sums pay off?
- [ ] When the data changes every second and you ask once
- [x] When the data doesn't change and you ask about many ranges
- [ ] Only for sorted data
- [ ] When the ranges are all the same size

Building them is one pass; each question after that is one subtraction. If the data keeps changing, they need
rebuilding every time.
:::

::: quiz Why is "the fastest kilometre" a two-pointer window and not a fixed-size one?
- [ ] Two pointers are always faster
- [x] A kilometre takes a different number of seconds on a climb and a descent, so the window's size in seconds changes
- [ ] A fixed window can't hold floats
- [ ] The riders' positions aren't sorted

The window is "at least 1000 m", not "N seconds". The right end moves a second at a time; the left end moves on
while the window still covers a kilometre.
:::

## Predict

```zig
const items = [_]u32{ 3, 1, 4, 1, 5 };
var sums: [items.len + 1]u32 = undefined;
sums[0] = 0;
for (items, 0..) |x, i| sums[i + 1] = sums[i] + x;
std.debug.print("{d} {d}\n", .{ sums[4] - sums[1], sums[5] - sums[0] });
```

::: quiz What does it print?
- [ ] 9 14
- [ ] 10 14
- [x] 6 14
- [ ] 5 13

`sums` is `{ 0, 3, 4, 8, 9, 14 }`. `sums[4] - sums[1]` covers items 1, 2 and 3: 1 + 4 + 1 = 6. `sums[5] - sums[0]`
is everything: 14.
:::

## Fix it

```zig
/// Metres from second a to second b, both included. sums[i]: metres in seconds 0..i.
fn metres(sums: []const f64, a: usize, b: usize) f64 {
    return sums[b] - sums[a - 1];
}
```

It works for `a = 1`. For a range starting at second 0:

```text
thread 1040098 panic: integer overflow
```

::: quiz What's the fix?
- [x] Store a leading 0 (sums[0] = 0, sums[i + 1] = sums[i] + items[i]) and return sums[b + 1] - sums[a]
- [ ] Use @max(a - 1, 0)
- [ ] Make a and b signed integers
- [ ] Special-case a == 0 by returning 0

`a - 1` on a `usize` 0 overflows. The leading zero makes every range one subtraction with no special case. `@max`
still computes `a - 1` first; returning 0 for `a == 0` is simply wrong (seconds 0 to b do have metres).
:::

## Build it

### Exercise

Find the steepest kilometre of a course: the kilometre with the most climbing. With the climb profile,
`profile.between(x, x + 1000)` is one subtraction for any `x`; slide `x` along the course in steps of 100 m and keep
the best. Tests first: on Compile Pass the steepest kilometre climbs 60 m, and starts somewhere from 4000 m to
5000 m; on a flat course it's 0.

```sh
zig build test --summary all
```
