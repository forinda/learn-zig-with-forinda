---
title: "Functions"
description: "Parameters, return values, functions that can fail, and printing race times as minutes and seconds."
group: "Basics"
order: 4
step: 07-functions
---

# Functions

## Engage

`finished in 1250 s` is accurate, but nobody says a race took twelve hundred and fifty seconds. They say *twenty
minutes fifty*. The game needs to print times the way people read them, in a lot of places: every kilometre, at
the finish, later on the results.

When you need the same thing in many places, you write it once, give it a name, and use the name: a **function**.

## Explore

You've used functions since lesson 1: `title()`, `advance(...)`, `finished(...)`. Look at `advance` in your
`src/main.zig`:

```zig
fn advance(position_m: f64, speed_mps: f64, dt: f64) f64 {
    return position_m + speed_mps * dt;
}
```

Try adding `position_m = 0;` as the first line inside it, and build. What does the compiler say about changing a
parameter?

## Explain

A function has a **name**, **parameters** (the values it's given, each with a type), and a **return type** (what it
gives back):

```text
fn  advance (position_m: f64, speed_mps: f64, dt: f64)  f64  { ... }
    name     parameters                                 returns
```

- Parameters are constants inside the function: you can't change them (that's what the compiler told you).
- `return` hands a value back to whoever called the function.
- A function that gives nothing back returns `void`.
- A function that can *fail* returns `!void` or `!T`: "this, or an error". Writing to the screen can fail, so
  functions that print return `!void`, and the caller writes `try` in front of them.

Two kinds of function are worth telling apart. Some **compute** (`advance`, `speedFor`): same inputs, same answer,
nothing else happens. Some **do** things, like printing. The first kind is the easiest to test, which is why the game
keeps its maths in small functions like those.

To turn seconds into minutes and seconds, two operators on whole numbers do the work: `/` (how many whole minutes,
the rest dropped) and `%` (the remainder, what's left over): `1250 / 60` is `20`, `1250 % 60` is `50`.

## Elaborate

**I do:** `printTime` writes a number of seconds as `m:ss`. It takes the writer to print through as a parameter,
so the game prints to the screen and the test prints into a buffer it can check. `{d:0>2}` pads the seconds with a
zero to two digits, so 65 s is `1:05`, not `1:5`:

<<< @/code/diffs/07-functions.diff

**We do:** make the change (or copy `code/steps/07-functions`) and run it:

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


::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/07-functions) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
