---
title: "Bit sets"
description: "Check your understanding of StaticBitSet, DynamicBitSetUnmanaged, EnumSet and set operations."
group: "Data structures and algorithms"
order: 6
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 27-bitsets
competency: "I can pick the right data structure for a job and say why"
---

# Bit sets

**Read first:** [Bit sets](/guide/data-structures/27-bit-sets) in the Guide. This lesson checks you understood it.

## Recall

::: quiz The field's size is only known when the race starts. Which set records who has led?
- [ ] std.StaticBitSet(8)
- [x] std.DynamicBitSetUnmanaged, sized with initEmpty(gpa, riders.len)
- [ ] std.EnumSet(Rider)
- [ ] A [8]bool

A static bit set's size is fixed while compiling, and so is an array's; an `EnumSet` needs an enum. A field of any
size needs a dynamic one.
:::

::: quiz How much memory do 1000 yes/no answers take as a StaticBitSet(1000), compared with [1000]bool?
- [ ] The same
- [ ] Half
- [x] About an eighth: one bit each instead of a byte
- [ ] More: a bit set has overhead

The measured sizes were 128 bytes against 1000.
:::

## Predict

```zig
var a: std.StaticBitSet(8) = .empty;
var b: std.StaticBitSet(8) = .empty;
for ([_]usize{ 0, 2, 4, 6 }) |i| a.set(i);
for ([_]usize{ 2, 3, 4 }) |i| b.set(i);
a.toggle(4);
std.debug.print("{d} {d}\n", .{ a.intersectWith(b).count(), a.unionWith(b).count() });
```

::: quiz What does it print?
- [ ] 2 5
- [x] 1 5
- [ ] 1 6
- [ ] 2 6

`toggle(4)` clears bit 4, so `a` is `{0, 2, 6}`. In both: `{2}`, one. In either: `{0, 2, 3, 4, 6}`, five.
:::

## Fix it

```zig
var finished: std.StaticBitSet(8) = .empty;
finished.set(rider.name - 'A' + 1); // riders A to H
```

For rider H:

```text
thread 1041570 panic: reached unreachable code
```

::: quiz What's the fix?
- [x] finished.set(rider.name - 'A'): A is bit 0 and H is bit 7
- [ ] std.StaticBitSet(9)
- [ ] finished.toggle(rider.name - 'A' + 1)
- [ ] Use finished.setValue instead

Eight bits are numbered 0 to 7; `'H' - 'A' + 1` is 8, one past the end. A ninth bit would "work" and leave every
rider one bit off (and bit 0 never used).
:::

## Build it

### Exercise

Record who was in the top three at each kilometre mark, in a second bit set on `Race` (sized like `led`, set from
`race.order[0..3]` when a `.km` mark is reported). At the finish, print who was in the top three at some point but
never led: the difference of the two sets (`DynamicBitSetUnmanaged` has `setIntersection` and `toggleSet`; or loop
over the bits). Tests first: on Compile Pass, every rider who led was also in the top three at some kilometre.

```sh
zig build test --summary all
```
