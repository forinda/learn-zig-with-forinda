---
title: "Arrays and slices"
description: "Eight riders: arrays, indexes, for loops with an index, and slices a function can read or change."
group: "Basics"
order: 5
layout: /src/layouts/lesson.tscl
steps: true
minutes: 25
step: 08-arrays-slices
competency: "I can work with arrays, slices and text"
---

# Arrays and slices

**Read first:** [Arrays and slices](/guide/basics/08-arrays-and-slices) in the Guide. This lesson checks you understood it.

## Recall

::: quiz A function only needs to read the riders' positions. Which parameter type fits best?
- [x] positions_m: []const f64
- [ ] positions_m: []f64
- [ ] positions_m: [8]f64
- [ ] positions_m: f64

A `[]const f64` slice reads any number of positions and promises not to change them.
:::

::: quiz What's the index of the last element of a [8]f64?
- [ ] 8
- [x] 7
- [ ] 1
- [ ] -1

Indexes start at 0, so eight elements are 0 to 7.
:::

## Predict

```zig
const speeds_mps = [_]f64{ 10.0, 12.0, 9.0 };
var best: usize = 0;
for (speeds_mps, 0..) |speed, i| {
    if (speed > speeds_mps[best]) best = i;
}
std.debug.print("{d}\n", .{best});
```

::: quiz What does it print?
- [ ] 12
- [x] 1
- [ ] 2
- [ ] 0

It prints the *index* of the fastest, not the speed: 12.0 is at index 1.
:::

## Fix it

```zig
fn reset(positions_m: []f64) void {
    for (positions_m) |*p| p.* = 0;
}

pub fn main() void {
    var positions_m = [_]f64{ 12.0, 30.5, 7.25 };
    reset(positions_m);
}
```

```text
error: local variable is never mutated
```

::: quiz reset clearly changes the positions. What's wrong?
- [ ] Make positions_m a const
- [x] Pass a slice of the array: reset(&positions_m)
- [ ] Change the parameter to [3]f64
- [ ] Add try in front of reset

Without `&`, nothing gives `reset` a way to change your array, so Zig sees a `var` that never changes. `&positions_m`
passes a slice of it, and then the error goes away.
:::

## Build it

### Exercise

Write `lastPlace(positions_m: []const f64) usize`, the index of the rider furthest back, with a test, and print
`last is G` at each kilometre.

Hint: it's `leader` with one comparison turned round. Test it where the last place is in the middle: `&.{ 5, 2, 9 }`.

```sh
zig build test --summary all
```
