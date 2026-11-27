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

**Read first:** [Reading compiler errors](/guide/start/03-reading-compiler-errors) in the Guide. This lesson checks you understood it.

## Recall

::: quiz The compiler says `error union of type 'error{WriteFailed}!void' is ignored` on a line with out.print(...). What does it want?
- [ ] Delete the line
- [ ] Change print to write
- [x] Put try in front of out.print(...), so a failed print is handled
- [ ] Add a test

`print` can fail, so it returns an error union. Zig won't let you ignore that: `try` passes the error on.
:::

::: quiz In `b.zig:5:25: error: ...`, what is 25?
- [ ] The error's number
- [ ] The number of errors
- [x] The column on line 5 where the problem is
- [ ] How many lines the file has

`file:line:column`. The line below the message shows the code, with `^` under that column.
:::

## Predict

```zig
const std = @import("std");

pub fn main() void {
    const laps: u8 = 300;
    std.debug.print("{d} laps\n", .{laps});
}
```

::: quiz What happens?
- [ ] It prints 300 laps
- [ ] It prints 44 laps (300 wraps round)
- [x] It doesn't compile: a u8 can't hold 300
- [ ] It crashes when it runs

A `u8` holds 0 to 255. Zig checks constants while compiling: `error: type 'u8' cannot represent integer value '300'`.
:::

## Fix it

```zig
pub fn main() void {
    const riders: u32 = 8;
    std.debug.print("Terminal Tour\n", .{});
}
```

```text
error: unused local constant
```

::: quiz Which fix is right?
- [ ] Change const to var
- [x] Use riders (print it), or delete the line
- [ ] Give it a type of u8
- [ ] Add pub in front of it

Zig doesn't allow values you never use: they're usually a mistake. Use it or remove it.
:::

## Build it

### Exercise

Make the race card's field 12 riders. The box's right edge moves out by one: fix it so the box stays straight for
both 8 and 12 riders.

Hint: print the number with a fixed width, `{d:>2}`, and take one space off the padding after it: `{s:<9}`.

```sh
zig build run
zig build test --summary all
```

## Stretch

**Part 1's challenge: make your own race card.** Pick a race you'd like to ride and change the constants to describe
it. Change the test so it checks *your* race. Then break your code on purpose in each of the three ways from the
guide page, and read each error before you fix it.
