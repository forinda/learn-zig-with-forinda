---
title: "Structs"
description: "Check your understanding of structs: fields, defaults, literals, methods and self."
group: "Structure"
order: 1
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 10-structs
competency: "I can model the game with structs, enums and tagged unions"
---

# Structs

**Read first:** [Structs](/guide/structure/10-structs) in the Guide. This lesson checks you understood it.

## Recall

::: quiz advance moves the rider. What should its self parameter be?
- [ ] self: Rider
- [x] self: *Rider
- [ ] self: *const Rider
- [ ] self: []Rider

A method that changes the fields needs a pointer it can write through: `*Rider`. `Rider` would change a copy, and
`*const Rider` can't change anything.
:::

::: quiz A struct literal leaves out a field that has no default. What happens?
- [ ] The field is set to 0
- [ ] The field is undefined
- [x] It doesn't compile: missing struct field
- [ ] It panics when the program runs

Every field needs a value, from the literal or from a default. Zig checks while compiling.
:::

## Predict

```zig
var a: Rider = .{ .name = 'A', .speed_mps = 10 };
var b = a;
b.advance(1);
std.debug.print("{d} {d}\n", .{ a.position_m, b.position_m });
```

::: quiz What does it print?
- [ ] 10 10
- [x] 0 10
- [ ] 10 0
- [ ] 0 0

`var b = a;` copies the whole struct. Moving `b` leaves `a` where it was.
:::

## Fix it

```zig
const a: Rider = .{ .name = 'A', .speed_mps = 10 };
a.advance(1);
```

```text
error: expected type '*rider.Rider', found '*const rider.Rider'
```

::: quiz What's the fix?
- [x] var a: Rider = ... (a rider that moves is a variable)
- [ ] a.*.advance(1);
- [ ] Rider.advance(a, 1);
- [ ] Change advance to take self: Rider

`advance` changes the rider, so it needs one that can change: a `var`. Making `advance` take `Rider` would compile,
but it would move a copy and the rider would never move.
:::

## Build it

### Exercise

Add a method `gapTo(self: Rider, other: Rider) f64`: how many metres `other` is ahead of `self` (negative if
behind). Write the test first: B at 120 m, A at 100 m, `a.gapTo(b)` is 20 and `b.gapTo(a)` is −20.

Hint: it only reads both riders, so `self: Rider` is right.

```sh
zig build test --summary all
```
