---
title: "Loops"
description: "while and for: run the race second by second until the line, with a marker every kilometre."
group: "Basics"
order: 3
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 06-loops
competency: "I can make decisions and repeat work with if, while and for"
---

# Loops

## Engage

The rider moves three seconds, because we wrote the same two lines three times. A race of 12.5 km at 10 m/s is
1250 seconds. Nobody wants to write that out.

Computers are good at doing the same thing over and over. You just have to say *what* to repeat and *when to stop*.

## Explore

Save this as `count.zig` and run it:

```zig
const std = @import("std");

pub fn main() void {
    var second: u32 = 0;
    while (second < 5) {
        second += 1;
        std.debug.print("second {d}\n", .{second});
    }
}
```

Now change `< 5` to `< 50`. Then think: what would happen if you deleted the line `second += 1;`? (If you try it,
stop the program with Ctrl+C.)

## Explain

A **`while`** loop repeats its block as long as its condition is true. Something in the block has to change so the
condition eventually becomes false, or it never stops:

```mermaid
flowchart TD
    check{"not finished?"} -- yes --> body["advance one second<br/>count it<br/>a new kilometre? print it"]
    body --> check
    check -- no --> done["print the time"]
```

A **`for`** loop goes through a list of things, or a range of numbers:

```zig
for (1..4) |lap| {
    std.debug.print("lap {d}\n", .{lap}); // lap 1, lap 2, lap 3 (4 is not included)
}
```

Two words change the flow inside any loop: **`break`** leaves the loop at once, **`continue`** skips to the next
round.

## Elaborate

**I do:** the three copied lines become one loop that runs until `finished`. Each time the rider passes a whole
kilometre, it prints a marker. `secondsToFinish` does the same counting, without printing, so a test can check it:

<<< @/code/diffs/06-loops.diff

**We do:** make the change (or copy `code/steps/06-loops`) and run it:

```sh
zig build run
```

```text
km 1 at 100 s
km 2 at 200 s
km 3 at 300 s
...
km 12 at 1200 s
finished in 1250 s
```

Why does the test `secondsToFinish(100, 30)` expect 4, not 3.33? The loop counts whole seconds: after 3 seconds the
rider is at 90 m, not finished, so it takes a fourth.

## Evaluate

::: quiz A while loop's condition is never false. What happens?
- [ ] The compiler refuses to build it
- [ ] It runs once
- [x] It runs forever, until you stop the program
- [ ] It runs a thousand times, then stops

Zig can't know your condition will never change, so it builds it. That's why the body must move towards the end:
here, `position_m` grows every second until `finished` is true.
:::

```sh
zig build test --summary all
```

### Exercise

Print a marker every 500 m instead of every kilometre (`km 0.5 at 50 s`, `km 1 at 100 s`, …). Then, with `break`,
stop the race early at 5 km and print `stopped at 5 km`.

Hint: the marker steps by `next_km_m += 500;`, and the printed number needs one decimal place: `{d:.1}`.
