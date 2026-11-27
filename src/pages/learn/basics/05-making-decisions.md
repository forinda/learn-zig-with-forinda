---
title: "Making decisions"
description: "true and false, comparisons, and if, else if and else: climbs are slow, descents fast."
group: "Basics"
order: 2
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 05-decisions
competency: "I can make decisions and repeat work with if, while and for"
---

# Making decisions

**Read first:** [Making decisions](/guide/basics/05-making-decisions) in the Guide. This lesson checks you understood it.

## Recall

::: quiz With the code from the guide, what speed does a 3 % climb get?
- [ ] 6 m/s, because 3 % is a climb
- [x] 10 m/s, because 3 is not greater than 3
- [ ] 14 m/s
- [ ] It doesn't compile

`gradient_pct > 3` is false at exactly 3, and so is `gradient_pct < -3`: the `else` gives 10 m/s.
:::

::: quiz What does `!finished` mean?
- [ ] finished, but louder
- [x] not finished: true when finished is false
- [ ] finished must not be null
- [ ] It's an error

`!` flips a `bool`.
:::

## Predict

```zig
const position_m: f64 = 12_500;
const distance_m: f64 = 12_500;
const label = if (position_m >= distance_m) "done" else "riding";
std.debug.print("{s}\n", .{label});
```

::: quiz What does it print?
- [x] done
- [ ] riding
- [ ] true
- [ ] It doesn't compile: if can't give a value

`>=` includes equal, so a rider exactly on the line has finished. `if` can give a value, as here.
:::

## Fix it

```zig
const gradient_pct: f64 = 5.0;
if (gradient_pct) {
    std.debug.print("climbing\n", .{});
}
```

```text
error: expected type 'bool', found 'f64'
```

::: quiz What's the fix?
- [ ] if (gradient_pct == true)
- [x] if (gradient_pct > 0)
- [ ] if (@as(bool, gradient_pct))
- [ ] Make gradient_pct a var

An `if` needs a `bool`. A number isn't true or false on its own in Zig: you say what you mean by comparing it.
:::

## Build it

### Exercise

Steep climbs are slower still: over 8 %, riders go 4 m/s. Write the test first, watch it fail, then make it pass.
Does the order of your checks matter? Put the 8 % check after the 3 % one and see.

Hint: the first true condition wins, so the steepest check has to come first.

```sh
zig build test --summary all
```
