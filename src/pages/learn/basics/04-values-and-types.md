---
title: "Values and types"
description: "Constants and variables, whole numbers and fractions, and making a rider move."
group: "Basics"
order: 1
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 04-values
competency: "I can store values in constants and variables of the right type"
---

# Values and types

**Read first:** [Values and types](/guide/basics/04-values-and-types) in the Guide. This lesson checks you understood it.

## Recall

::: quiz A rider's position changes every second. How should it be declared?
- [ ] const position_m: u32 = 0;
- [x] var position_m: f64 = 0;
- [ ] var position_m: u32 = 0;
- [ ] const position_m: f64 = 0;

It changes, so it's a `var`; and riders can be partway between metres, so it needs fractions: `f64`.
:::

::: quiz What does std.debug.print("{d}", .{1000 / 3600}) print?
- [ ] 0.2777
- [x] 0
- [ ] 1
- [ ] It doesn't compile

Two whole numbers divide to a whole number, and the rest is dropped: 1000 / 3600 is 0.
:::

## Predict

```zig
const std = @import("std");

pub fn main() void {
    const speed_mps: f64 = 10.0;
    var position_m: f64 = 0;
    position_m = position_m + speed_mps;
    position_m = position_m + speed_mps;
    std.debug.print("{d} m\n", .{position_m});
}
```

::: quiz What does it print?
- [ ] 10 m
- [x] 20 m
- [ ] 0 m
- [ ] It doesn't compile: speed_mps is const

Each line adds 10 to the position: 0, then 10, then 20. `speed_mps` is only read, so `const` is right.
:::

## Fix it

```zig
fn totalDistance(riders: u64, speed_mps: f64) f64 {
    return riders * speed_mps;
}
```

```text
error: incompatible types: 'u64' and 'f64'
```

::: quiz What's the fix?
- [ ] Change f64 to u64 everywhere
- [x] return @as(f64, @floatFromInt(riders)) * speed_mps;
- [ ] return riders + speed_mps;
- [ ] return speed_mps * riders;

Not every `u64` fits exactly in an `f64`, so Zig won't convert it on its own. `@floatFromInt` says you want it
converted (here, `@as` names the type). Swapping the order changes nothing.
:::

## Build it

### Exercise

Riders talk about speed in km/h. Add `speed_kph: f64 = 36.0`, convert it to metres per second in code, and use it
instead of `10.0`. The output must not change.

Hint: `speed_kph * 1000 / 3600` works, because the `f64` comes first. Why would `speed_kph * (1000 / 3600)` give 0?

```sh
zig build run
zig build test --summary all
```
