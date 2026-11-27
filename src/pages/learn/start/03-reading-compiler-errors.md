---
title: "Reading compiler errors"
description: "Read what the compiler tells you, fix three classic mistakes, and print the first race card."
group: "Start"
order: 3
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 03-race-card
competency: "I can read a compiler error and fix the code it points to"
---

# Reading compiler errors

## Engage

You will write code that doesn't compile. Everyone does, every day. The Zig compiler is strict, and that's a
gift: it catches mistakes before your game ever runs, and it tells you exactly where they are.

The skill isn't avoiding errors. It's reading them.

## Explore

The course repository has three small programs that are broken on purpose, in `code/broken/03-race-card/`.
Run each one and read the **first line** of what comes back:

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
race become constants (values that never change), and a new function, `raceCard`, prints them in a box. Here's the
change:

<<< @/code/diffs/03-race-card.diff

**We do:** make the change in your project (or copy `code/steps/03-race-card`), then run it:

```sh
zig build run
```

```text
+------------------------------+
| Terminal Tour                |
|                              |
| Course:   Ngong Road         |
| Distance:  12.5 km           |
| Field:    8 riders           |
+------------------------------+
```

`{s:<28}` means "a string, padded on the right to 28 characters", which keeps the box's right edge straight.
`{d:>5.1}` means "a number, one decimal place, padded on the left to 5 characters".

Notice the test: it doesn't print to the screen. It prints the card into a fixed buffer and checks the buffer
holds the course, the distance and the field.

## Evaluate

::: quiz The compiler says `error union of type 'error{WriteFailed}!void' is ignored` on a line with `out.print(...)`. What does it want?
- [ ] Delete the line
- [ ] Change `print` to `write`
- [x] Put `try` in front of `out.print(...)`, so a failed print is handled
- [ ] Add a test

`print` can fail, so it returns an error union. Zig won't let you ignore that: `try` passes the error on to
whoever called your function.
:::

Check the race card's test passes:

```sh
zig build test --summary all
```

### Exercise

**Part 1's challenge: make your own race card.** Pick a race you know (a road near you, a famous climb, a loop of
your town) and change the constants to describe it. Then:

1. Change the test so it checks *your* race.
2. Make the field 12 riders. The box's right edge moves. Why? Fix it.
3. Break your code on purpose in one of the three ways from this lesson, and read the error before you fix it.

Hint for 2: `8 riders` is shorter than `12 riders`, and the padding after it doesn't know. One way is to print
the number with a fixed width, like `{d:>2}`.
