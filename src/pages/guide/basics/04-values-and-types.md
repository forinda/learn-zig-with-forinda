---
title: "Values and types"
description: "const and var, integer and float types, overflow, number literals, conversions between types, and division."
group: "Basics"
order: 1
step: 04-values
---

# Values and types

The race card says there's a race; nothing moves yet. A rider in the game is a few numbers: where it is, how fast it
goes, how much time has passed. Change the numbers and the rider moves. To change numbers, a program keeps them in
named places, and it has to know what kind of number each one is. That's what this page is about.

<img class="lesson-art" src="/art/agama-road.svg" alt="Agama, the course's lizard, holding a stopwatch beside a road drawn in text" width="400" height="300" />

## const and var

A **constant** never changes; a **variable** does:

```zig
const speed_mps: f64 = 10.0; // never changes
var position_m: f64 = 0;     // changes as the rider moves
position_m = position_m + speed_mps;
```

Zig holds you to both. Changing a `const` won't build (`cannot assign to constant`), and a `var` that never changes
won't either:

```text
values.zig:5:9: error: local variable is never mutated
```

Use `const` unless the value really changes. It's one less thing that can surprise you.

The `: f64` is the **type**. You can often leave it out of a `const` and Zig works it out, but a `var` needs it:

```zig
var riders = 8; // error: variable of type 'comptime_int' must be const or comptime
```

`8` on its own is a number Zig only knows while compiling (`comptime_int`); a `var` needs a real size to live in
while the program runs: `var riders: u32 = 8;`.

## Whole numbers

Integer types say how many bits they have and whether they can be negative:

| Type | Holds | In the game |
|---|---|---|
| `u8` | 0 to 255 | a letter, a lap count |
| `u32` | 0 to about 4.3 billion | riders, seconds |
| `u64` | 0 to about 18 billion billion | big counters |
| `i32` | about −2.1 billion to 2.1 billion | a gradient of −5 % |
| `usize` | the size of memory on this machine | indexes and lengths |

`u` is unsigned (0 and up), `i` is signed (negative too). The number is the bits: any width works, `u1` to `u65535`.

### Too big for its type

A constant that doesn't fit is caught while compiling:

```zig
const laps: u8 = 255 + 1;
```

```text
error: type 'u8' cannot represent integer value '256'
```

When it only happens while running, the program stops:

```text
thread 643017 panic: integer overflow
```

That's a safety check: in `fast` and `small` builds it's off, and the number wraps round silently. When wrapping is
what you want, say so with `+%` (wrap round) or `+|` (stop at the limit):

```zig
var laps: u8 = 255;
laps +%= 1;   // 0
var seats: u8 = 250;
seats +|= 10; // 255
```

## Numbers with fractions

`f64` and `f32` are **floating-point** numbers: fractions, with 64 or 32 bits of precision. The game uses `f64` for
positions and speeds. They're not exact:

```zig
const b: f64 = 0.1;
std.debug.print("{d} {}\n", .{ b + 0.2, b + 0.2 == 0.3 });
```

```text
0.30000000000000004 false
```

Never test floats with `==` for things that matter; check "close enough", or use whole numbers (metres, not
kilometres; seconds, not minutes) where exactness counts.

## Writing numbers

```zig
12_500 // underscores for readability: 12500
0xff   // hexadecimal: 255
0b101  // binary: 5
1e3    // 1000.0, a float
```

## Converting between types

Zig converts by itself only when nothing can be lost. A `u32` fits exactly in an `f64`, so this works:

```zig
fn total(riders: u32, speed_mps: f64) f64 {
    return riders * speed_mps;
}
```

A `u64` doesn't always fit, so Zig refuses to guess:

<<< @/code/broken/04-values/int-times-float.zig [int-times-float.zig]

```text
int-times-float.zig:7:19: error: incompatible types: 'u64' and 'f64'
```

When a conversion could lose something, you write it, and Zig checks it (in safe builds) when the program runs:

| Builtin | Converts | If it doesn't fit |
|---|---|---|
| `@floatFromInt(x)` | a whole number to a float | (always fits, maybe rounded) |
| `@intFromFloat(x)` | a float to a whole number, dropping the fraction (12.7 → 12) | `panic: integer part of floating point value out of bounds` |
| `@intCast(x)` | one integer type to another | `panic: integer does not fit in destination type` |
| `@as(T, x)` | names the type for a conversion Zig would allow anyway | won't compile |

The result type comes from where the value goes: `const whole: u32 = @intFromFloat(km);`. When there's nowhere to
take it from, wrap it in `@as`: `@as(f64, @floatFromInt(riders))`.

## Division

Two whole numbers divide to a whole number, and the rest is dropped:

<<< @/code/broken/04-values/int-division.zig [int-division.zig]

```text
half of 7 laps is 3
```

To keep the half, make it a float first: `@as(f64, @floatFromInt(laps)) / 2` gives `3.5`. `%` gives the remainder:
`7 % 2` is `1`.

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

::: tip Try it
Print `1000 / 3600` and `1000.0 / 3600.0`. Then make a `var laps: u8 = 250;`, add 10 to it, and run it in
`debug` and then with `zig run -O fast`.
:::

## Which type when

| Value | Type | Because |
|---|---|---|
| positions, speeds, times with fractions | `f64` | fractions, plenty of precision |
| counts: riders, seconds, laps | `u32` | whole, never negative |
| something that can go below zero | `i32` | signed |
| an index or a length | `usize` | what arrays and slices use |
| a single character | `u8` | a byte |

Picking a type too small gives overflow; picking a float for a count gives rounding where you didn't want it.

## In the game

The race gets a clock tick, `dt_s` (one second), and a function, `advance`, that works out where a rider is after
one more tick: its position plus its speed times the time. Under the race constants, the clock tick:

<<< @/code/steps/04-values/src/main.zig#dt

Below `raceCard`, `advance`:

<<< @/code/steps/04-values/src/main.zig#advance

In `main`, after the race card, move one rider three times. Its speed is a `const`, its position a `var`:

<<< @/code/steps/04-values/src/main.zig#main

Its tests, at the end of the file:

<<< @/code/steps/04-values/src/main.zig#tests

Run it (or copy `code/steps/04-values`):

```sh
zig build run
```

After the race card:

```text
after 1 s: 10.0 m
after 2 s: 20.0 m
after 3 s: 30.0 m
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/04-values/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/04-values.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/04-values-and-types) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
