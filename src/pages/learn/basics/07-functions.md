---
title: "Functions"
description: "Parameters, return values, functions that can fail, and printing race times as minutes and seconds."
group: "Basics"
order: 4
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 07-functions
competency: "I can write functions that take and return values"
---

# Functions

**Read first:** [Functions](/guide/basics/07-functions) in the Guide. This lesson checks you understood it.

## Recall

::: quiz printTime returns !void. What does the exclamation mark tell you?
- [ ] It returns a number
- [x] It can fail with an error, so callers put try in front of it
- [ ] It's private to this file
- [ ] It never returns

`!void` means "nothing, or an error". Writing can fail, so `printTime` passes that possibility on.
:::

::: quiz What are 1250 / 60 and 1250 % 60 (whole numbers)?
- [ ] 20.83 and 0
- [x] 20 and 50
- [ ] 21 and 10
- [ ] 20 and 0.83

`/` gives the whole minutes, `%` what's left over: 20 minutes 50 seconds.
:::

## Predict

```zig
fn printTime(w: *std.Io.Writer, seconds: u32) !void {
    try w.print("{d}:{d:0>2}", .{ seconds / 60, seconds % 60 });
}
```

::: quiz What does printTime(out, 65) print?
- [ ] 1:5
- [x] 1:05
- [ ] 65
- [ ] 0:65

65 seconds is 1 minute and 5 seconds, and `{d:0>2}` pads the seconds to two digits with a zero.
:::

## Fix it

```zig
fn halve(laps: u32) u32 {
    laps = laps / 2;
    return laps;
}
```

```text
error: cannot assign to constant
```

::: quiz Which fix is right?
- [ ] Make laps a var parameter: fn halve(var laps: u32)
- [x] return laps / 2; (or copy it into a new var first)
- [ ] Remove the return type
- [ ] Use laps * 0.5

Parameters are constants. Compute the new value and return it, or copy the parameter into a `var` inside the function.
:::

## Build it

### Exercise

Write `printPace(w: *std.Io.Writer, seconds: u32, distance_m: f64) !void`, printing minutes per kilometre like
`1:40 /km`, and use it under the finish line. Write its test first, with a fixed buffer like the `printTime` test.

Hint: seconds per kilometre is `seconds / (distance_m / 1000)`: a fraction. Turn it back into a whole number with
`@intFromFloat`, then reuse `printTime`.

```sh
zig build test --summary all
```
