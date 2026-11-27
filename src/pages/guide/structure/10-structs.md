---
title: "Structs"
description: "Grouping values into a type: fields and defaults, struct literals, methods with self, *T versus T, comparing and printing structs."
group: "Structure"
order: 1
step: 10-structs
---

# Structs

The game keeps its riders in two parallel arrays: speeds in one, positions in the other, and the letter worked out
from the index. Rider 3 is "index 3 of each array", and nothing stops one array getting out of step with the other.
A rider is really one thing with a few parts. A **struct** says exactly that: a new type made of named **fields**,
kept together.

## Declaring a struct

```zig
const Rider = struct {
    name: u8,
    speed_mps: f64,
    position_m: f64 = 0, // a default value
};
```

`Rider` is now a type, like `f64`. Type names start with a capital letter by convention. Each field has a name and
a type, and can have a **default** used when you don't give one.

## Making one: struct literals

```zig
var a: Rider = .{ .name = 'A', .speed_mps = 10.4 };
```

`.{ ... }` builds a struct whose type comes from where it goes (here, the `Rider` on the left). Each field is set
with `.field = value`. `position_m` takes its default, 0. Leave out a field without a default and it won't build:

```text
error: missing struct field: speed_mps
```

Read and set fields with a dot: `a.position_m`, `a.position_m = 100;`.

## Methods

Functions declared inside a struct belong to it. When the first parameter is the struct itself, conventionally
named `self`, you can call the function with a dot on a value: a **method**.

```zig
const Rider = struct {
    name: u8,
    speed_mps: f64,
    position_m: f64 = 0,

    fn advance(self: *Rider, dt: f64) void {
        self.position_m += self.speed_mps * dt;
    }

    fn finished(self: Rider, distance_m: f64) bool {
        return self.position_m >= distance_m;
    }
};
```

```zig
var a: Rider = .{ .name = 'A', .speed_mps = 10.4 };
a.advance(1);                  // the same as Rider.advance(&a, 1)
const done = a.finished(12_500);
```

### *Rider or Rider: will it change?

The type of `self` says whether the method changes the value:

| `self` is | The method | Call it on |
|---|---|---|
| `Rider` | reads a copy | anything |
| `*const Rider` | reads, without copying | anything |
| `*Rider` | can change the fields | a `var` only |

`advance` moves the rider, so it takes `*Rider`; `finished` only looks, so `Rider` is enough. Calling a changing
method on a `const` won't build:

```text
rider.zig:18:6: error: expected type '*rider.Rider', found '*const rider.Rider'
```

(Zig names a type after the file it's in: `rider.Rider` is the `Rider` in `rider.zig`.)

You don't write `&` or `.*` at the call: `a.advance(1)` passes `&a` for you, and `self.position_m` reaches through
the pointer.

### Names inside a struct

Inside the struct, a method's name hides any function of the same name outside it, and Zig refuses to guess which
you mean:

```text
error: ambiguous reference
```

That happens in the game: a free function `advance` and a method `advance`. The fix is to rename one; the game's
free function becomes `advance_m` ("advance, in metres").

## Structs are values

Like arrays, structs are copied when assigned or passed by value, and `==` doesn't compare them:

```text
error: operator == not allowed for type 'rider.Rider'
```

`std.meta.eql(a, b)` compares field by field. `{any}` prints every field:

```text
.{ .name = 65, .speed_mps = 10.4, .position_m = 10.4 }
```

(`name` shows as 65: it's a `u8`, printed as a number by `{any}`.)

## Arrays of structs

An array of `Rider`s replaces the parallel arrays: one index, one rider, all of its fields together.

```zig
var field: [8]Rider = undefined;
for (&field, field_speeds_mps, 0..) |*rider, speed_mps, i| {
    rider.* = .{ .name = riderName(i), .speed_mps = speed_mps };
}
```

`undefined` leaves the array unfilled; the loop fills every rider before any is read. Functions take a slice of
riders, `[]Rider` to change them or `[]const Rider` to read them, exactly like slices of numbers.

::: tip Try it
Add a field `team: []const u8 = "Team Allocator"` to `Rider`, make two riders, change one's team, and print both
with `{any}`. Then try to call `advance` on a `const` rider.
:::

## Parallel arrays or structs

| | Parallel arrays | An array of structs |
|---|---|---|
| a rider's data | spread across arrays, joined by index | in one place |
| adding a field | a new array, and every loop changes | a new field |
| passing a rider to a function | several values | one value |
| risk | arrays getting out of step | none of that |

Part 13 comes back to when parallel arrays win (data-oriented design, for speed); for the game's logic, structs
read better.

## In the game

The parallel arrays become one array of `Rider`s. A `Rider` knows its name, speed and position, how to move on, and
whether it has finished. Below `dt_s`:

<<< @/code/steps/10-structs/src/main.zig#rider

In `main`, the field is built from the speeds and the loop asks the riders themselves:

<<< @/code/steps/10-structs/src/main.zig#main

The field functions now take slices of riders (the parameter is called `field`, because a file-level `riders`
constant already holds the rider count):

<<< @/code/steps/10-structs/src/main.zig#field

<<< @/code/steps/10-structs/src/main.zig#draw

The tests build riders with a small helper:

<<< @/code/steps/10-structs/src/main.zig#helper

and two new tests check the struct itself, at the end of the file:

<<< @/code/steps/10-structs/src/main.zig#tests

Run it (or copy `code/steps/10-structs`). The race prints exactly what it printed before: the same race, better
organised.

```sh
zig build run
```

```text
km 1 at 1:37: leader is B
  ---B----------------------------------------------
...
km 12 at 19:14: leader is B
  -------------------------------------------EGAHB--
B wins in 20:02
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/10-structs/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/10-structs.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/structure/10-structs) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
