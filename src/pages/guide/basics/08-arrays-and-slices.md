---
title: "Arrays and slices"
description: "Arrays, indexes and bounds, @splat, arrays as values, comparing them, slices and slicing, and slices a function can read or change."
group: "Basics"
order: 5
step: 08-arrays-slices
---

# Arrays and slices

A race with one rider isn't a race; the race card promises eight. Eight speeds and eight positions as sixteen
separate names would make every loop and every function sixteen times longer. What the game needs is *one* name for
all eight positions, and a way to say "rider 3's position". That's an **array**, and the way to hand part or all of
one to a function is a **slice**.

## Arrays

An array is a fixed number of values of one type, side by side in memory:

```zig
const speeds_mps = [3]f64{ 10.0, 10.4, 9.8 };
const same = [_]f64{ 10.0, 10.4, 9.8 }; // [_]: Zig counts them for you
```

The type `[3]f64` says both: three of them, each an `f64`. The length is part of the type, and fixed: an array never
grows or shrinks (Part 4's lists do).

### Indexes and length

Each value has an **index**, its position, counting from **0**: the first is `speeds_mps[0]`, the last is
`speeds_mps[speeds_mps.len - 1]`. `.len` is how many there are.

```zig
std.debug.print("{d} riders, the second at {d} m/s\n", .{ speeds_mps.len, speeds_mps[1] });
```

```text
3 riders, the second at 10.4 m/s
```

### Out of bounds is always caught

When Zig knows the index while compiling, a wrong one won't build:

```text
riders.zig:5:90: error: index 3 outside array of length 3
```

When the index is only known while running, the check happens then. This loop goes one step too far (`<=` instead
of `<`):

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

The program stops rather than reading memory that isn't the array's (in `debug` and `safe` builds; see
[Optimize modes](/guide/start/02-build-run-test)).

### Filling an array

To give every element the same starting value, `@splat`:

```zig
var positions_m: [8]f64 = @splat(0); // eight riders, all at the start
```

(Older Zig wrote this `[_]f64{0} ** 8`; 0.17 doesn't have `**` for arrays.)

### Arrays of arrays

An array's items can be arrays: two laps of split times, say. Index twice:

```zig
const lap_times_s = [_][2]u32{ .{ 101, 98 }, .{ 97, 95 } };
const second_lap_first_split = lap_times_s[1][0]; // 97
```

## Arrays are values

Assigning an array **copies** all of it. Changing the copy leaves the original alone:

```zig
var start_m = [_]f64{ 0, 0, 0 };
var now_m = start_m; // a copy of all three
now_m[0] = 10;
```

```text
start_m: { 0, 0, 0 }   now_m: { 10, 0, 0 }
```

That's safe, but for big arrays it's a lot of copying, which is one reason functions take **slices** instead.

### Comparing arrays

`==` doesn't work on arrays:

```text
error: operator == not allowed for type '[2]u32'
```

Compare them item by item with `std.mem.eql`: `std.mem.eql(f64, &start_m, &now_m)` is `false` here.

## Slices

A **slice** is a view of some or all of an array: where it starts and how long it is. It doesn't copy anything.
Take one with a range:

```zig
const speeds_mps = [_]f64{ 10.0, 10.4, 9.8, 10.1, 9.6 };
const front = speeds_mps[0..2]; // the first two: { 10, 10.4 }
const rest = speeds_mps[2..];   // from the third to the end: { 9.8, 10.1, 9.6 }
```

`front.len` is 2, `rest.len` is 3. A range past the end is caught like an index: `panic: index out of bounds: index
9, len 5`.

### Slices as parameters

Functions take slices, so they work for any number of riders. `&` turns an array into a slice of all of it:

```zig
fn leader(positions_m: []const f64) usize { ... }
const first = leader(&positions_m);
```

| Parameter | The function can | Pass |
|---|---|---|
| `[]const f64` | read the values | `&array`, or any slice |
| `[]f64` | read and change them | `&array` of a `var` |
| `[8]f64` | read a copy of exactly eight | the array itself |

Prefer `[]const T` when the function only reads: it promises not to change anything, and it takes arrays of any
length. Use `[]T` when it changes the items, and a fixed `[N]T` only when the number really is part of the meaning.

### Walking a slice

`for` goes through slices like arrays. Capture a pointer to change items, and walk two slices of the same length
side by side ([Loops](/guide/basics/06-loops) has all the forms):

```zig
for (positions_m, speeds_mps) |*position_m, speed_mps| {
    position_m.* += speed_mps;
}
```

::: tip Try it
Make an array of five speeds, take a slice of the middle three with `[1..4]`, and print its `.len` and items with
`{any}`. Then change an item of the array and print the slice again: it sees the change, because it's a view, not a
copy.
:::

## Arrays or slices

| You have | Use | Because |
|---|---|---|
| a fixed number of things you own | an array `[N]T` | it holds the values |
| a function reading a list | `[]const T` | any length, no copy, read only |
| a function changing a list | `[]T` | any length, no copy |
| part of a list | a slice `a[i..j]` | a view, no copy |

## In the game

The field gets one array of speeds (rider A to H) and one of positions. `advanceAll` moves everyone by one tick,
changing the positions in place through a `[]f64`; `leader` reads them through a `[]const f64` and returns the
index of the furthest; `riderName` turns an index into a letter. Letters are numbers in Zig (the
[next page](/guide/basics/09-text-on-the-road)'s subject), so `'A' + 1` is `'B'`; `@intCast` turns the `usize`
index into the `u8` a letter needs (checking it fits), and `{c}` prints a `u8` as its character.

Under the race constants, every rider's speed:

<<< @/code/steps/08-arrays-slices/src/main.zig#speeds

Below `printTime`, the functions that work on the whole field:

<<< @/code/steps/08-arrays-slices/src/main.zig#field

In `main`, replace the one-rider loop with the field's:

<<< @/code/steps/08-arrays-slices/src/main.zig#main

Their tests, at the end of the file:

<<< @/code/steps/08-arrays-slices/src/main.zig#tests

Run it (or copy `code/steps/08-arrays-slices`):

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

B leads all the way: every rider rides at one fixed speed, and B's is the highest. Racing with climbs (and leaders
who change) comes in Part 3.

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/08-arrays-slices/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/08-arrays-slices.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/08-arrays-and-slices) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
