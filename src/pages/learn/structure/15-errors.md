---
title: "Errors"
description: "Check your understanding of error sets, try, catch, mapping errors and expectError, then design your own course."
group: "Structure"
order: 6
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 15-errors
competency: "I can handle missing values with optionals and failures with errors"
---

# Errors

**Read first:** [Errors](/guide/structure/15-errors) in the Guide. This lesson checks you understood it.

## Recall

::: quiz parseCourse returns an error and main says try parseCourse(...). What happens?
- [ ] The race runs on an empty course
- [ ] The error is ignored
- [x] main returns the error: the program stops and prints it with an error return trace
- [ ] It doesn't compile

`try` passes the error on to `main`'s caller. Nobody is above `main`, so Zig prints the error and the trace of
`try`s it came through.
:::

::: quiz "There's no rider called Z" or "this course text is broken": which is an error?
- [ ] Both
- [ ] Neither: both are optionals
- [x] The broken text; a missing rider is an optional
- [ ] The missing rider; the broken text is an optional

No rider Z is a normal answer to a question (`?*Rider`); broken text is something going wrong, and the caller wants
to know what (`ParseError!Course`).
:::

## Predict

```zig
fn number(word: ?[]const u8) E!f64 {
    const w = word orelse return error.MissingNumber;
    return std.fmt.parseFloat(f64, w) catch error.BadNumber;
}

const a = number("12") catch 0;
const b = number(null) catch 1;
const c = number("x") catch |err| if (err == error.BadNumber) @as(f64, 2) else 3;
std.debug.print("{d} {d} {d}\n", .{ a, b, c });
```

::: quiz What does it print?
- [ ] 0 1 2
- [x] 12 1 2
- [ ] 12 1 3
- [ ] 12 0 0

`"12"` parses, so `catch` isn't used. `null` gives `MissingNumber`, caught as 1. `"x"` gives `BadNumber`, so 2.
:::

## Fix it

```zig
const E = error{ MissingNumber, BadNumber };

fn number(word: ?[]const u8) E!f64 {
    const w = word orelse return error.MissingNumber;
    return std.fmt.parseFloat(f64, w);
}
```

```text
fix.zig:5:30: error: expected type 'error{BadNumber,MissingNumber}!f64', found 'error{InvalidCharacter}!f64'
fix.zig:5:30: note: 'error.InvalidCharacter' not a member of destination error set
```

::: quiz Which fix keeps number's errors to E and reports "far" as an error?
- [x] return std.fmt.parseFloat(f64, w) catch error.BadNumber;
- [ ] return try std.fmt.parseFloat(f64, w);
- [ ] return std.fmt.parseFloat(f64, w) catch unreachable;
- [ ] return std.fmt.parseFloat(f64, w) catch 0;

`try` passes on the same `InvalidCharacter`, which still isn't in `E`. `catch unreachable` builds but panics on
`"far"` (`attempt to unwrap error: InvalidCharacter`). `catch 0` builds but turns `"far"` into a 0 m segment,
silently.
:::

## Build it

### Exercise

Add a terrain kind to the text format: `sprint 300`, a flat stretch where everyone rides 20 % faster. Tests first:
`test "a sprint segment parses"` (`"flat 1000\nsprint 300"` gives two segments and 1300 m) and `test "a sprint
needs a length"` (`"sprint"` is `error.MissingNumber`). Then parse it: `Segment` needs to know it's a sprint (a
`sprint: bool = false` field, or better, give `Segment` a `Terrain` and add `.sprint` to it, letting the compiler
find every `switch`).

```sh
zig build test --summary all
```

## Stretch

**Part 3's challenge: design your own course.** Write a course in the text format with at least four segments and
at least one terrain the game doesn't have yet (cobbles, sprint, gravel: your choice, with a speed rule you decide).

- A test that parses it and checks its distance and one segment's terrain.
- A test that a broken version of it (a typo, a missing number) is rejected with the right error.
- Race it: swap it in for Compile Pass in `main` and see who wins on your roads.

Any course that parses, races, and has both tests counts. If the winner surprises you, that's the point: the
terrain changes who's strongest.
