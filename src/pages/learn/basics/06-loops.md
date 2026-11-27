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

**Read first:** [Loops](/guide/basics/06-loops) in the Guide. This lesson checks you understood it.

## Recall

::: quiz A while loop's condition is never false. What happens?
- [ ] The compiler refuses to build it
- [ ] It runs once
- [x] It runs forever, until you stop the program
- [ ] It runs a thousand times, then stops

Something in the loop has to move towards the end, like `position_m` growing every second.
:::

::: quiz How many times does `for (1..4) |lap|` run?
- [ ] 4
- [x] 3 (lap is 1, 2, 3)
- [ ] 5
- [ ] 1

A range includes its start and stops before its end.
:::

## Predict

```zig
var km: u32 = 0;
while (true) {
    km += 1;
    if (km == 3) break;
}
std.debug.print("{d}\n", .{km});
```

::: quiz What does it print?
- [ ] 0
- [ ] 2
- [x] 3
- [ ] Nothing: it loops forever

`while (true)` never stops on its own, but `break` leaves the loop as soon as `km` reaches 3.
:::

## Fix it

```zig
for (0..3) |lap| {
    std.debug.print("lap\n", .{});
}
```

```text
error: unused capture
```

::: quiz Which fix is right?
- [ ] for (0..3) |lap| { lap; ... }
- [x] Use it, print("lap {d}\n", .{lap}), or write |_| to say you don't need it
- [ ] for (0..3) { ... }
- [ ] Change 0..3 to 1..3

Like unused constants, unused captures are errors. `_` says you mean to ignore it.
:::

## Build it

### Exercise

Print a marker every 500 m instead of every kilometre (`km 0.5 at 50 s`, `km 1.0 at 100 s`, …). Then, with
`break`, stop the race at 5 km and print `stopped at 5 km`.

Hint: step the marker with `next_km_m += 500;` and print the kilometre with one decimal place, `{d:.1}`.

```sh
zig build run
zig build test --summary all
```
