---
title: "Enums and switch"
description: "Enums as named choices, methods on enums, switch and why it must cover every case, else, several values and ranges, and a course made of segments."
group: "Structure"
order: 3
step: 12-enums
---

# Enums and switch

Every race so far is won by B, because every rider rides one speed all day. Real roads climb and descend, and
riders differ: some fly on the flat, some climb best. The game needs to know *what kind of road* is under each
rider. A gradient of 6 % is a number; "climb" is a **kind**. Zig has a type for a fixed set of kinds, the **enum**,
and a statement that makes sure you handled every one, **`switch`**.

## Enums: a fixed set of names

```zig
const Terrain = enum { flat, climb, descent };

const t: Terrain = .climb;
```

A `Terrain` can only ever be one of those three. Write a value with a dot, `.climb`, when Zig knows the type from
where it goes; otherwise in full, `Terrain.climb`. Compare with `==` (`t == .climb`), and print the name with
`@tagName(t)` (`climb`) or the value with `{any}` (`.climb`).

Why not a number (0 flat, 1 climb, 2 descent) or a string? A number can be 7, and a string can be `"clmb"`; an
enum can only be what's in its list, and the compiler checks every use.

### Methods on enums

Like structs, enums can hold functions. One that turns a gradient into a terrain belongs with `Terrain`:

```zig
const Terrain = enum {
    flat,
    climb,
    descent,

    fn of(gradient_pct: f64) Terrain {
        if (gradient_pct > 3) return .climb;
        if (gradient_pct < -3) return .descent;
        return .flat;
    }
};
```

`Terrain.of(6)` is `.climb`.

### From text to an enum

`std.meta.stringToEnum(Terrain, "climb")` gives `.climb`, and `null` for a name that isn't one (`"cobbles"`):
handy when the course comes from text, in [Errors](/guide/structure/15-errors).

## switch: one branch per case

`switch` picks a branch by value. On an enum, each branch (a **prong**) names a case:

```zig
fn speedFor(terrain: Terrain) f64 {
    return switch (terrain) {
        .flat => 10.0,
        .climb => 6.0,
        .descent => 14.0,
    };
}
```

Like `if`, a `switch` can give a value, as here, or run blocks: `.climb => { ... },`.

### Every case, or it won't build

Leave a case out and the compiler says which:

```text
miss.zig:4:12: error: switch must handle all possibilities
miss.zig:2:37: note: unhandled enumeration value: 'descent'
```

That's the point of `switch` over an `else if` chain. Add a fourth terrain, `cobbles`, and every `switch` on
`Terrain` in the program stops building until you've decided what cobbles mean there. An `if` chain would silently
treat cobbles as whatever its last `else` says.

### else, several values, ranges

With a fourth terrain, `cobbles`:

```zig
fn hard(terrain: Terrain) bool {
    return switch (terrain) {
        .climb, .cobbles => true, // several values, one prong
        else => false,            // everything else
    };
}
```

On integers, a prong can be a range (both ends included), and since nobody can list every `u32`, integer switches
need an `else`:

```zig
fn label(km: u32) []const u8 {
    return switch (km) {
        0 => "start",
        1...4 => "valley",
        5, 6 => "the climb",
        else => "run-in",
    };
}
```

`label(3)` is `valley`, `label(6)` is `the climb`, `label(11)` is `run-in`. Without the `else`: `switch must handle
all possibilities`.

Strings can't be switched on (`error: cannot switch on strings`): compare them with `std.mem.eql`, or turn them into
an enum first.

### else on an enum: use it sparingly

`else` on an enum switch turns off the check that saves you when a case is added. `hard` above is fine with it ("a
new terrain is easy unless I say so" is a real rule). `speedFor` must not have one: a new terrain needs its own speed,
and the compiler should make you choose it.

::: tip Try it
Add `cobbles` to `Terrain`, build, and read the errors: each is a `switch` that needs a decision. Give cobbles a speed
of 8 m/s.
:::

## Which choice when

| You're choosing by | Use |
|---|---|
| a yes/no question | `if` |
| ranges of a number, in order | `if ... else if`, or `switch` with ranges |
| which of a fixed set of kinds | an enum and a `switch` without `else` |
| text | `std.mem.eql`, or `stringToEnum` then `switch` |

## A course made of segments

A course is a list of **segments**: each starts somewhere and has a gradient, until the next one starts. The terrain
at a position is the last segment that starts at or before it.

```text
height
          /\
         /  \
________/    \________
0 km   4    6    8   12.5
 flat   climb descent flat
```

## In the game

Terrain arrives, and the course gets its climb. Each rider has a speed on the flat and on a climb (the strongest
climbers aren't the fastest on the flat), and flies 40 % faster downhill. Under the rider speeds, the climb speeds:

<<< @/code/steps/12-enums/src/main.zig#speeds

Below `dt_s`, `Terrain` and `speedFor`:

<<< @/code/steps/12-enums/src/main.zig#terrain

`Rider` gets a `climb_mps` field and a `speedOn` method, a `switch` over the terrain:

<<< @/code/steps/12-enums/src/main.zig#speed-on

The course gets its segments, and Compile Pass its climb:

<<< @/code/steps/12-enums/src/main.zig#course

`Race.step` asks the course what's under each rider's wheels:

<<< @/code/steps/12-enums/src/main.zig#step

The tests, at the end of the file:

<<< @/code/steps/12-enums/src/main.zig#tests

Run it (or copy `code/steps/12-enums`). For the first time the race changes:

```sh
zig build run
```

```text
km 4 at 6:25: leader is B
km 5 at 9:18: leader is H
km 6 at 11:51: leader is E
km 7 at 13:06: leader is E
km 8 at 14:20: leader is E
km 9 at 16:03: leader is H
...
H wins in 21:43
```

B leads to the foot of the climb, H takes over on it, E (the best climber) crests first, and H wins it back on the
flat.

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/12-enums/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/12-enums.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/structure/12-enums-and-switch) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
