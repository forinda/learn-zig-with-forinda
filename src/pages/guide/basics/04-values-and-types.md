---
title: "Values and types"
description: "Constants and variables, whole numbers and fractions, and making a rider move."
group: "Basics"
order: 1
step: 04-values
---

# Values and types

## Engage

<img class="lesson-art" src="/art/agama-road.svg" alt="Agama, the course's lizard, holding a stopwatch beside a road drawn in text" width="400" height="300" />

The race card says there's a race. Nothing moves yet. A rider in the game is really just a few numbers: where it
is, how fast it goes, how much time has passed. Change the numbers, and the rider moves.

To change numbers, a program has to keep them somewhere, and know what kind of number each one is.

## Explore

Save this as `values.zig` and run it with `zig run values.zig`:

```zig
const std = @import("std");

pub fn main() void {
    const speed_mps: f64 = 10.0;
    var position_m: f64 = 0;
    position_m = position_m + speed_mps;
    std.debug.print("{d} m\n", .{position_m});
}
```

It prints `10 m`. Now try two things, one at a time, and read what the compiler says:

1. Change `var position_m` to `const position_m`.
2. Change it back, and delete the line `position_m = position_m + speed_mps;`.

## Explain

A **constant** (`const`) is a value that never changes. A **variable** (`var`) is one that does. Zig holds you to
it both ways: you can't change a constant, and if you make a `var` but never change it, the compiler tells you:

```text
values.zig:5:9: error: local variable is never mutated
```

Use `const` unless the value really changes. It's one less thing to keep track of.

Every value has a **type**, which says what kind of value it is:

| Type | Holds | Examples in the game |
|---|---|---|
| `u32` | whole numbers from 0 up (unsigned, 32 bits) | riders: `8`, seconds: `1250` |
| `i32` | whole numbers, negative too | a gradient of `-5` % |
| `f64` | numbers with fractions (floating point, 64 bits) | speed `10.4` m/s, position `12.5` km |
| `bool` | `true` or `false` | has this rider finished? |

The names in this course carry their unit, `speed_mps` (metres per second) or `position_m` (metres), so mixing
up metres and kilometres is hard to do by accident.

Zig is careful when types meet. A `u32` times an `f64` works: every `u32` fits exactly in an `f64`, so Zig converts
it for you. But a `u64` doesn't always fit, and then Zig refuses to guess:

<<< @/code/broken/04-values/int-times-float.zig [int-times-float.zig]

```text
int-times-float.zig:7:19: error: incompatible types: 'u64' and 'f64'
```

You convert it yourself, saying what you mean: `@as(f64, @floatFromInt(riders)) * speed_mps`.

One more surprise: dividing two whole numbers gives a whole number, and the rest is dropped.

<<< @/code/broken/04-values/int-division.zig [int-division.zig]

```text
half of 7 laps is 3
```

To keep the half, make it a float first: `@as(f64, @floatFromInt(laps)) / 2` gives `3.5`.

Whole numbers that can be negative (`i32`) are stricter still. Should `-5 / 2` be `-2` or `-3`? Zig won't guess:

```zig
fn halfGradient(gradient_pct: i32) i32 {
    return gradient_pct / 2;
}
```

```text
error: division with 'i32' and 'comptime_int': signed integers must use @divTrunc, @divFloor, @divCeil, or @divExact
```

You say which you mean: `@divTrunc(gradient_pct, 2)` drops the rest towards zero (`-2`), `@divFloor` rounds down
(`-3`).

## Elaborate

**I do:** the race gets a clock tick, `dt_s` (one second), and a function, `advance`, that works out where a rider
is after one more tick: its position plus its speed times the time. Here's the change:

<<< @/code/diffs/04-values.diff

**We do:** make the change in your project (or copy `code/steps/04-values`), then run it:

```sh
zig build run
```

The race card, and then:

```text
after 1 s: 10.0 m
after 2 s: 20.0 m
after 3 s: 30.0 m
```

`{d:.1}` prints a number with one decimal place. `speed_mps` is a `const` (it never changes), `position_m` is a
`var` (it moves).


::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/04-values-and-types) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
