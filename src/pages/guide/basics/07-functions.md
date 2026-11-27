---
title: "Functions"
description: "Parameters and return values, void and !void, try, pointers to change what's passed in, pub, recursion, and printing times."
group: "Basics"
order: 4
step: 07-functions
---

# Functions

`finished in 1250 s` is accurate, but nobody says a race took twelve hundred and fifty seconds; they say *twenty
minutes fifty*. The game needs times the way people read them, in a lot of places: every kilometre, at the finish,
later on the results. When you need the same work in many places, you write it once, give it a name, and use the
name: a **function**. You've used them from the start (`main`, `title`, `advance`); this page covers what they can
do.

## The parts of a function

```text
fn  advance (position_m: f64, speed_mps: f64, dt: f64)  f64  { ... }
    name     parameters                                 returns
```

```zig
fn advance(position_m: f64, speed_mps: f64, dt: f64) f64 {
    return position_m + speed_mps * dt;
}
```

- **Parameters** are the values it's given, each with its type.
- The **return type** is what it gives back; `return` hands it to whoever called.
- A function can be defined after the code that uses it: Zig reads the whole file first.

### Every path must return

A function that promises an `f64` must return one on every path through it:

```text
error: function with non-void return type 'f64' implicitly returns
```

### Using what comes back

A returned value can't be dropped by accident:

```zig
advance(0, 10, 1); // the result goes nowhere
```

```text
error: value of type 'f64' ignored
```

Use it, or say you mean to drop it: `_ = advance(0, 10, 1);`.

## void and !void

| Return type | Means |
|---|---|
| `f64`, `u32`, … | gives back a value of that type |
| `void` | gives nothing back |
| `!void` | nothing, or an **error** |
| `!u32` | a `u32`, or an error |

Functions that write to the screen can fail, so they return `!void`, and whoever calls them puts **`try`** in front:
if an error comes back, `try` stops here and passes it on to its own caller. Part 3's
[Errors](/guide/structure/15-errors) page covers errors in full.

## Parameters are constants

Inside a function, its parameters can't be changed:

```zig
fn halve(laps: u32) u32 {
    laps = laps / 2; // error: cannot assign to constant
    return laps;
}
```

Compute the new value and return it (`return laps / 2;`), or copy it into a `var` first. This makes functions
easier to read: what you were given is what you have.

## Changing the caller's value: a pointer

To let a function change something of the caller's, pass its **address** with `&`. The parameter's type is a
**pointer**, `*f64`, and `.*` reaches the value it points at:

```zig
fn moveOn(position_m: *f64, speed_mps: f64) void {
    position_m.* += speed_mps;
}

var position_m: f64 = 0;
moveOn(&position_m, 10);
moveOn(&position_m, 10); // position_m is now 20
```

Use this sparingly: a function that returns its result is easier to follow and to test than one that changes things
you have to go and look at. You'll use pointers properly with structs in Part 3.

## pub: who can call it

Functions are private to their file unless marked `pub`. `pub fn main` must be public so Zig can start the
program; the game's other functions stay private until Part 10 splits the game into several files.

## A function that calls itself

A function can call itself (**recursion**), as long as each call gets closer to a case that stops:

```zig
fn lapsToCover(distance_m: u32, lap_m: u32) u32 {
    if (distance_m <= lap_m) return 1;
    return 1 + lapsToCover(distance_m - lap_m, lap_m);
}
```

`lapsToCover(12_500, 4_000)` is 4. Each call uses a little memory until it returns, so a very deep recursion can run
out; in Zig a loop is usually the better choice, and the game won't need recursion.

## Two kinds of function

Some functions **compute**: same inputs, same answer, nothing else happens (`advance`, `speedFor`). Some **do**
things: print, change a pointer's value. Computing functions are the easiest to test: call, compare, done. So the
game keeps its rules in small computing functions and lets `main` do the printing.

## Splitting time: / and %

On whole numbers, `/` gives how many whole times one goes into the other, and `%` what's left over:

```text
1250 / 60 = 20   (minutes)
1250 % 60 = 50   (seconds)
```

::: tip Try it
Write `fn kph(speed_mps: f64) f64` that turns metres per second into km/h (× 3.6), with a test that `kph(10)` is
`36`. Then try calling it without using the result.
:::

## In the game

`printTime` writes a number of seconds as `m:ss`. It takes the writer to print through as a parameter, so the game
prints to the screen and the test prints into a buffer it can check. `{d:0>2}` pads the seconds with a zero to two
digits, so 65 s is `1:05`, not `1:5`. Below `secondsToFinish`:

<<< @/code/steps/07-functions/src/main.zig#print-time

In `main`, the loop prints its times with it (replace the loop and the finish line):

<<< @/code/steps/07-functions/src/main.zig#loop

Its test, at the end of the file:

<<< @/code/steps/07-functions/src/main.zig#tests

Run it (or copy `code/steps/07-functions`):

```sh
zig build run
```

```text
km 1 at 1:40
km 2 at 3:20
km 3 at 5:00
...
km 12 at 20:00
finished in 20:50
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/07-functions/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/07-functions.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/07-functions) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
