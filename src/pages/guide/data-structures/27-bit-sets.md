---
title: "Bit sets"
description: "A yes or no for each of many things in one bit each: StaticBitSet, DynamicBitSetUnmanaged and EnumSet, set operations, and the memory they save."
group: "Data structures and algorithms"
order: 6
step: 27-bitsets
---

# Bit sets

Who led the race at some point? Which kinds of terrain does this course have? Each answer is a yes or a no for each
of a few things: eight riders, three or four kinds of terrain. A `bool` per thing works, but a `bool` takes a whole
byte to store one bit of information. A **bit set** stores each yes or no in one bit, and lets you ask questions of
whole sets at once.

## StaticBitSet: a size known while compiling

```zig
var led: std.StaticBitSet(8) = .empty; // eight bits, all clear
led.set(1);
led.set(7);
led.set(4);
led.isSet(7); // true
led.count();  // 3
```

`unset(i)`, `toggle(i)` and `setValue(i, b)` change one bit. `iterator(.{})` gives the indexes of the set bits,
lowest first:

```zig
var it = led.iterator(.{});
while (it.next()) |i| std.debug.print("{c} ", .{'A' + @as(u8, @intCast(i))});
```

```text
B E H
```

### Whole sets at once

Riders who led *and* made the podium, riders who did *either*:

```zig
const both = led.intersectWith(podium);
const either = led.unionWith(podium);
```

```text
led 3, both 2, either 4, 7 in both: true
```

Each of those is a handful of machine instructions, not a loop over the riders: the processor combines 64 bits in
one step.

### The size

```text
sizes: [1000]bool 1000 bytes, StaticBitSet(1000) 128 bytes
```

Eight times smaller, which matters when there are many of them (one per rider per kilometre, one per map tile)
and when the processor's cache can hold eight times as many.

## DynamicBitSetUnmanaged: a size known while running

The game's field can be any size, so its sets are sized when the race starts, from an allocator:

```zig
var led: std.DynamicBitSetUnmanaged = try .initEmpty(gpa, riders.len);
defer led.deinit(gpa);
led.set(11);
```

`bit_length` is its size; everything else works like the static one.

## EnumSet: one bit per kind

When the things are the values of an enum, `std.EnumSet` gives you a bit for each, by name:

```zig
var kinds: std.EnumSet(Terrain) = .empty;
kinds.insert(.climb);
kinds.insert(.flat);
kinds.contains(.cobbles); // false
```

It's one byte for `Terrain`'s four kinds. Its relatives use an enum as the key too: `std.EnumArray(Terrain, f64)`
holds one value per kind (a speed for each terrain), `std.EnumMap` one optional value per kind.

::: tip Try it
Make two `std.EnumSet(Terrain)` for two courses and print the terrain they have in common
(`intersectWith`) and the terrain only the first has (`differenceWith`).
:::

## Which set when

| You're tracking | Use | Because |
|---|---|---|
| yes/no for a fixed number of things | `StaticBitSet(n)` | no allocator, a bit each |
| yes/no for a number known while running | `DynamicBitSetUnmanaged` | sized once, a bit each |
| yes/no per value of an enum | `EnumSet(E)` | by name, checked by the compiler |
| a value per value of an enum | `EnumArray(E, T)` | an array indexed by kind |
| yes/no for a few unrelated flags | separate `bool` fields | clearer when they aren't "a set" |
| membership in a huge, sparse set | a hash map (or set) | bits for every possible member would waste memory |

What goes wrong with the wrong one: a `[]bool` per rider per kilometre uses eight times the memory; a bit set over
something sparse (a few of millions) wastes almost all of its bits.

## In the game

Who led at some point: one bit per rider, sized when the race starts. `Race` gains the set:

<<< @/code/steps/27-bitsets/src/main.zig#led-field

<<< @/code/steps/27-bitsets/src/main.zig#track-leaders

and every second, the leader's bit is set:

<<< @/code/steps/27-bitsets/src/main.zig#led-step

What terrain a course has, as a set. In `Course`:

<<< @/code/steps/27-bitsets/src/main.zig#kinds

In `playRace`, the course line lists its kinds:

<<< @/code/steps/27-bitsets/src/main.zig#kinds-use

and after the results, who led:

<<< @/code/steps/27-bitsets/src/main.zig#led-use

The tests, at the end of the file:

<<< @/code/steps/27-bitsets/src/main.zig#tests

Run it (or copy `code/steps/27-bitsets`):

```sh
zig build run
```

```text
race 1: Compile Pass
12.5 km, 120 m of climbing; terrain: flat climb descent
...
led the race: Buffer Errdefer Heap
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/27-bitsets/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/27-bitsets.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/data-structures/27-bit-sets) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
