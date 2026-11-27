---
title: "Loops"
description: "while and for in all their forms, break and continue, loops that give a value, and which loop to use when."
group: "Basics"
order: 3
step: 06-loops
---

# Loops

The race so far moves one rider three seconds, because we wrote the same two lines three times. A race of
12.5 km at 10 m/s is 1250 seconds. Repeating work is what loops are for, and Zig has two: **`while`**, which
repeats until something changes, and **`for`**, which goes through things one by one. Each has a few forms, and
picking the right one prevents a whole class of bugs.

## while: repeat until something changes

`while` checks a condition, runs its block, and checks again. It stops the first time the condition is false:

```zig
var position_m: f64 = 0;
while (position_m < 12_500) {
    position_m += 10; // one second at 10 m/s
}
```

Something inside the block must move towards the end. If nothing does, the loop never stops: the program hangs
and you stop it with Ctrl+C. Zig can't warn you, because it can't know your condition will never change.

Use `while` when you don't know in advance how many rounds it takes: "ride until the line", "read until the end".

## Counting with while: the continue expression

When a `while` counts, put the counting step after a colon. It runs at the end of every round, even when the
round ends early with `continue`, so it can't be forgotten:

```zig
var km: u32 = 0;
while (km < 3) : (km += 1) {
    std.debug.print("km {d}\n", .{km});
}
```

```text
km 0
km 1
km 2
```

## for: one round per item

`for` goes through an array or a slice, one item per round. It knows where the end is, so it can't run past it:

```zig
const speeds_mps = [_]f64{ 10.0, 10.4, 9.8 };
for (speeds_mps) |speed| {
    std.debug.print("{d}\n", .{speed});
}
```

The name between the bars, `|speed|`, is the **capture**: the current item. It's a constant: you read it, you
can't change it.

### With the index

Add a range starting at 0 and capture it too:

```zig
for (speeds_mps, 0..) |speed, i| {
    std.debug.print("{c}: {d}\n", .{ 'A' + @as(u8, @intCast(i)), speed });
}
```

```text
A: 10
B: 10.4
C: 9.8
```

### Changing the items

To change items as you go, capture a pointer with `*` and loop over the array's address with `&`. `.*` reaches
the item the pointer points at:

```zig
var positions_m: [3]f64 = @splat(0);
for (&positions_m) |*position| {
    position.* += 10;
}
```

### Two arrays side by side

`for` can walk several arrays at once, one item from each per round. They must be the same length. When Zig
knows the lengths while compiling, a mismatch won't build:

```text
error: non-matching for loop lengths
note: length 3 here
note: length 2 here
```

When the lengths are only known while running (two slices passed to a function), the program stops instead:

```text
thread 596054 panic: for loop over objects with non-equal lengths
```

Either way, a mismatch never quietly reads past the end of one of them.

### Ranges

`0..3` counts 0, 1, 2: the end is not included. A range's capture is always a `usize` (the type Zig uses for
sizes and indexes), so mixing it with other whole-number types needs a conversion:

```zig
var total: u32 = 0;
for (1..4) |lap| total += lap; // error: expected type 'u32', found 'usize'
```

`total += @intCast(lap);` says "I know it fits".

::: tip Try it
Print the riders backwards: C, B, A. There's no reverse `for` in Zig; a counting `while` going down from
`speeds_mps.len` works. Watch out for the last round: a `usize` can't go below 0.
:::

## Leaving early: break and continue

**`break`** leaves the loop at once. **`continue`** skips the rest of this round and starts the next:

```zig
for (speeds_mps) |speed| {
    if (speed < 10) continue; // skip the slow ones
    std.debug.print("fast: {d}\n", .{speed});
}
```

### Labelled loops

Inside a loop within a loop, `break` leaves only the inner one. To leave both, give the outer loop a label and
break to it:

```zig
const lap_times_s = [_][3]f64{ .{ 101, 98, 99 }, .{ 97, 95, 96 } };
outer: for (lap_times_s, 0..) |lap, l| {
    for (lap) |t| {
        if (t < 96) {
            std.debug.print("a sub-96 split in lap {d}\n", .{l});
            break :outer;
        }
    }
}
```

## Loops that give a value

A loop can be an expression: `break` with a value hands it out, and `else` gives the value for when the loop
finishes without breaking. Searching becomes one statement:

```zig
const first_fast: ?usize = for (speeds_mps, 0..) |speed, i| {
    if (speed > 10.2) break i;
} else null;
```

`first_fast` is `1` (B). If nobody were over 10.2, it would be `null`: "no value". You'll meet that `?` properly
in Part 3.

## Loops over an iterator: while with a capture

Some things hand out items one at a time until they run out: an **iterator**. `while` with a capture takes items
until there are none left:

```zig
var words = std.mem.tokenizeScalar(u8, "flat climb descent", ' ');
while (words.next()) |word| {
    std.debug.print("[{s}]", .{word});
}
```

```text
[flat][climb][descent]
```

This is how the game will read courses from text in Part 3.

## Which loop when

| You want to | Use | Because |
|---|---|---|
| go through every item of an array or slice | `for (items) \|item\|` | it can't miss one or run past the end |
| change every item | `for (&items) \|*item\|` | the pointer reaches the item itself |
| walk two lists together | `for (a, b) \|x, y\|` | Zig checks they're the same length |
| repeat until something happens | `while (condition)` | you don't know how many rounds |
| count | `for (0..n)` or `while (i < n) : (i += 1)` | `for` when counting up through a range; `while` for anything else |
| take items until none are left | `while (it.next()) \|item\|` | the iterator says when it's done |

What goes wrong with the wrong one: a `while` over an array with your own index can run one past the end (a
runtime panic) or stop one short (a wrong answer, silently); a `for` can't. A `while` whose condition never
changes hangs. A `for` over two lists of different lengths is caught, never silently wrong.

## In the game

The race needs to run second by second until the rider crosses the line, and nobody says in advance how many
seconds that takes: a `while`. Inside it, an `if` prints a marker each time the rider passes a whole kilometre.

In `main`, the three copied "after" lines (and the rider setup above them) become this loop:

<<< @/code/steps/06-loops/src/main.zig#loop

`secondsToFinish` does the same counting without printing, so a test can check it. Add it below `speedFor`:

<<< @/code/steps/06-loops/src/main.zig#seconds

and its tests at the end of the file:

<<< @/code/steps/06-loops/src/main.zig#tests

Run it (or copy `code/steps/06-loops` and run that):

```sh
zig build run
```

```text
km 1 at 100 s
km 2 at 200 s
...
km 12 at 1200 s
finished in 1250 s
```

Why does `secondsToFinish(100, 30)` give 4, not 3.33? The loop counts whole seconds: after 3 the rider is at 90 m,
not finished, so it takes a fourth.

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/06-loops/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/06-loops.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/06-loops) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
