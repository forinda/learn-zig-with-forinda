---
title: "Arrays and slices"
description: "Eight riders: arrays, indexes, for loops with an index, and slices a function can read or change."
group: "Basics"
order: 5
step: 08-arrays-slices
---

# Arrays and slices

## Engage

A race with one rider isn't a race. The race card promises 8 riders. Eight speeds, eight positions: we could make
eight `var`s for each, but then every loop and every function would need sixteen names.

What we want is *one* name for all eight positions, and a way to say "rider 3's position".

## Explore

Save this as `riders.zig` and run it:

```zig
const std = @import("std");

pub fn main() void {
    const speeds_mps = [_]f64{ 10.0, 10.4, 9.8 };
    std.debug.print("{d} riders, the second at {d} m/s\n", .{ speeds_mps.len, speeds_mps[1] });
}
```

Notice: the *second* rider is `speeds_mps[1]`. Now change the `1` to `3`, run it, and read the message carefully.

## Explain

An **array** is a fixed number of values of one type, side by side: `[3]f64` is three `f64`s. Write `[_]` and Zig
counts them for you. `.len` is how many there are.

Each value has an **index**, its position, starting from **0**: the first is `[0]`, the last is `[len - 1]`. Asking
for one past the end is always caught. When Zig knows the index while compiling, as in the Explore, it won't build
the program:

```text
riders.zig:5:90: error: index 3 outside array of length 3
```

When the index is only known while the program runs (counted in a loop, say), the check happens then, and the program
stops instead of reading memory that isn't the array's. This loop goes one step too far (`<=` instead of `<`):

```zig
var i: usize = 0;
while (i <= speeds_mps.len) : (i += 1) {
    std.debug.print("{d}\n", .{speeds_mps[i]});
}
```

```text
10
10.4
9.8
thread 468387 panic: index out of bounds: index 3, len 3
```

(`: (i += 1)` after the condition runs at the end of each round: a tidy place for the counter.)

To give every element the same starting value, use `@splat`:

```zig
var positions_m: [8]f64 = @splat(0); // eight riders, all at the start
```

A `for` loop can walk an array and count as it goes, or walk two arrays side by side:

```zig
for (positions_m, 0..) |position_m, i| { ... }         // each value, and its index
for (positions_m, speeds_mps) |*position_m, speed| { ... } // two at once; * lets you change the first
```

A **slice** is a view of some or all of an array: a pointer to the first element and a length. Functions take slices
so they work for any number of riders:

| Slice type | The function can |
|---|---|
| `[]const f64` | read the values |
| `[]f64` | read and change them |

Pass an array to a slice parameter with `&`: `leader(&positions_m)`.

## Elaborate

**I do:** the field gets one array of speeds (rider A to H) and one of positions. `advanceAll` moves everyone by
one tick, changing the positions in place through a `[]f64`. `leader` reads them through a `[]const f64` and
returns the index of the furthest, and `riderName` turns an index into a letter. Letters are numbers in Zig (the
next lesson's subject), so `'A' + 1` is `'B'`; `@intCast` turns the `usize` index into the `u8` a letter needs (it
checks the number fits), and `{c}` prints a `u8` as its character:

<<< @/code/diffs/08-arrays-slices.diff

**We do:** make the change (or copy `code/steps/08-arrays-slices`) and run it:

```sh
zig build run
```

```text
km 1 at 1:37: leader is B
km 2 at 3:13: leader is B
...
km 12 at 19:14: leader is B
B wins in 20:02
```

B leads all the way: every rider rides at one fixed speed, and B's is the highest. Real racing (drafting, tiring,
attacking) arrives with the Simulation part; for now the field is in place.


::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/08-arrays-and-slices) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
