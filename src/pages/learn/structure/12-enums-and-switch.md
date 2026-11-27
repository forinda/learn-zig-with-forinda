---
title: "Enums and switch"
description: "Check your understanding of enums, switch, exhaustiveness, else and ranges."
group: "Structure"
order: 3
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 12-enums
competency: "I can model the game with structs, enums and tagged unions"
---

# Enums and switch

**Read first:** [Enums and switch](/guide/structure/12-enums-and-switch) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz You add .cobbles to Terrain. speedFor has a switch on Terrain with no else. What happens?
- [ ] cobbles gets speed 0
- [ ] cobbles uses the last prong's speed
- [x] It doesn't build until speedFor handles .cobbles
- [ ] The program panics when a rider reaches cobbles

A `switch` on an enum must handle every value. The compiler names the missing one: `unhandled enumeration value:
'cobbles'`.
:::

::: quiz Which switch needs an else?
- [ ] A switch on Terrain that lists all three terrains
- [x] A switch on a u32 that lists 0, 1...4 and 5
- [ ] Every switch
- [ ] None: else is always optional

An enum's values can all be listed; a `u32`'s can't, so an integer switch needs `else` (or a range covering
everything).
:::

## Predict

```zig
for ([_]f64{ 3, -4, 6 }) |g| {
    std.debug.print("{s} ", .{@tagName(Terrain.of(g))});
}
```

with `Terrain.of` from the game (over 3 % is a climb, under −3 % a descent).

::: quiz What does it print?
- [ ] climb descent climb
- [x] flat descent climb
- [ ] flat flat climb
- [ ] 0 2 1

3 is not over 3, so it's flat; −4 is under −3, a descent; 6 a climb. `@tagName` gives the name, not a number.
:::

## Fix it

```zig
const Terrain = enum { flat, climb, descent };

fn speedFor(terrain: Terrain) f64 {
    return switch (terrain) {
        .flat => 10.0,
        .climb => 6.0,
    };
}
```

```text
miss.zig:4:12: error: switch must handle all possibilities
miss.zig:2:37: note: unhandled enumeration value: 'descent'
```

::: quiz What's the best fix?
- [x] Add a prong: .descent => 14.0,
- [ ] Add else => 14.0,
- [ ] Add else => unreachable,
- [ ] Remove descent from Terrain

All four build, but only the first keeps the check: with `else`, the next terrain someone adds silently gets 14 m/s
(or, with `unreachable`, crashes the race). Removing `descent` loses the descent.
:::

## Build it

### Exercise

Add a fourth terrain, `cobbles`: flat cobbled road, where everyone rides at 8 m/s whatever their usual speed.
Write the test first, `test "cobbles slow everyone to 8 m/s"`, checking `speedFor(.cobbles)` and a rider's
`speedOn(.cobbles)`. Then add `.cobbles` to `Terrain` and let the compiler list each `switch` you have to update.

Cobbles can't come from a gradient (`Terrain.of` never returns it), so they won't show up in the race yet: the
test is what proves they work. Part 3's last lesson reads terrain names from text, and that's where cobbles can join
a course.

```sh
zig build test --summary all
```
