---
title: "Reading compiler errors"
description: "Read what the compiler tells you, fix three classic mistakes, and print the first race card."
group: "Start"
order: 3
step: 03-race-card
---

# Reading compiler errors

## Engage

You will write code that doesn't compile. Everyone does, every day. The Zig compiler is strict, and that's a
gift: it catches mistakes before your game ever runs, and it tells you exactly where they are.

The skill isn't avoiding errors. It's reading them.

## Explore

Here are three small programs, each broken on purpose. Make a folder, save each one there under its name
(`a.zig`, `b.zig`, `c.zig`), or find them in the course repository in `code/broken/03-race-card/`.

<<< @/code/broken/03-race-card/a.zig [a.zig]

<<< @/code/broken/03-race-card/b.zig [b.zig]

<<< @/code/broken/03-race-card/c.zig [c.zig]

In that folder, run each one and read the **first line** of what comes back:

```sh
zig run a.zig
zig run b.zig
zig run c.zig
```

Before reading on, guess what each one is complaining about.

## Explain

Every error has the same shape:

```text
b.zig:5:25: error: fractional component prevents float value '8.5' from coercion to type 'u32'
    const riders: u32 = 8.5;
                        ^~~
```

- `b.zig:5:25` is **where**: the file, the line (5) and the column (25).
- After `error:` comes **what** is wrong.
- Below it, the line itself, with `^` under the exact spot.

Fix the first error first: one mistake can cause others further down, and they disappear with it.

The three you just met are the ones you'll see most:

| Error | What it means | The fix |
|---|---|---|
| `unused local constant` | You made a value and never used it. | Use it, or remove it. |
| `fractional component prevents float value '8.5' from coercion to type 'u32'` | A whole-number type (`u32`) can't hold `8.5`. | Use a whole number, or a type that holds fractions (`f64`). |
| `error union of type 'error{WriteFailed}!void' is ignored` | Something that can fail wasn't checked. | Put `try` in front of it. |

## Elaborate

Now the game gets its first real screen: a **race card** for the first race. **I do:** three facts about the
race become constants (values that never change), and a new function, `raceCard`, prints them in a box. Here's the new code, piece by piece, and where
each goes.

At the top, under the `std` import, the race:

<<< @/code/steps/03-race-card/src/main.zig#race

Below `title()`, the race card:

<<< @/code/steps/03-race-card/src/main.zig#card

In `main`, print the card instead of the title:

<<< @/code/steps/03-race-card/src/main.zig#main

And its test, at the end of the file:

<<< @/code/steps/03-race-card/src/main.zig#test

**We do:** make the changes in your project (or copy `code/steps/03-race-card`), then run it:

```sh
zig build run
```

```text
+------------------------------+
| Terminal Tour                |
|                              |
| Course:   Compile Pass       |
| Distance:  12.5 km           |
| Field:    8 riders           |
+------------------------------+
```

`{s:<28}` means "a string, padded on the right to 28 characters", which keeps the box's right edge straight.
`{d:>5.1}` means "a number, one decimal place, padded on the left to 5 characters".

Notice the test: it doesn't print to the screen. It prints the card into a fixed buffer and checks the buffer
holds the course, the distance and the field.

<details>
<summary>The whole <code>src/main.zig</code> after this step</summary>

<<< @/code/steps/03-race-card/src/main.zig

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/start/03-reading-compiler-errors) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
