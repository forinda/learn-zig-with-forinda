---
title: "A race type"
description: "Structs made of structs, init functions, *const self, and testing well: one rule per test, names that say the rule, edges, expectEqualDeep."
group: "Structure"
order: 2
step: 11-race
---

# A race type

`main` still holds the race together by hand: a course name, a distance, the field, a clock, and a loop that knows
how all of them fit. A race *is* those things. When they live in one value with its own operations ("take a step",
"who leads?", "is it over?"), `main` gets short, and every rule of the race can be tested without running one.
This page builds that type, then looks hard at how to test it well.

## Structs made of structs

A field can be any type, including another struct or an array of them:

```zig
const Course = struct {
    name: []const u8,
    distance_m: f64,
};

const Race = struct {
    course: Course,
    riders: [8]Rider,
    clock_s: u32 = 0,
};
```

Reach inside with more dots: `race.course.distance_m`, `race.riders[1].position_m`. The whole `Race` is one value:
copy it and you copy the course, all eight riders and the clock.

## init: a function that makes the value

Building a `Race` by hand means filling eight riders every time. A function inside the struct that returns a new
one does it once. By convention it's called `init`:

```zig
fn init(course: Course, speeds_mps: []const f64) Race {
    var race: Race = .{ .course = course, .riders = undefined };
    for (&race.riders, 0..) |*rider, i| {
        const speed_mps = if (i < speeds_mps.len) speeds_mps[i] else 10.0;
        rider.* = .{ .name = riderName(i), .speed_mps = speed_mps };
    }
    return race;
}
```

```zig
var race = Race.init(compile_pass, &field_speeds_mps);
```

`init` has no `self`: it doesn't work on a race, it makes one, so you call it on the type, `Race.init(...)`.
Returning a struct returns the whole value; nothing is left pointing at `init`'s local `race`.

## Methods that read: *const self

A `Race` is big (eight riders), so methods that only read take `self: *const Race`: a pointer, so nothing is copied,
and `const`, so they promise not to change it:

```zig
fn leader(self: *const Race) usize { ... }
fn done(self: *const Race) bool { ... }
fn step(self: *Race) void { ... } // changes the race
```

Readers can be called on a `const` race; `step` can't:

```text
init.zig:14:9: error: expected type '*init.Race', found '*const init.Race'
```

For a small struct like `Rider`, `self: Rider` is fine; for a big one, prefer `*const`.

::: tip Try it
Add `fn riderCount(self: *const Race) usize` returning `self.riders.len`, and call it on a `const` race. Then try
`step` on the same `const` race.
:::

## Testing well

A test is only as useful as what it tells you when it fails. Four habits:

### One rule per test, and the name says the rule

```zig
test "the race is done when the leader is exactly on the line" { ... }
```

When it fails, the name alone says which rule broke. `test "race works"` says nothing; and a test that checks
five things stops at the first failure and hides the other four.

### Test the edges

Bugs live at the boundaries: exactly on the line, the first rider, the last one, a list shorter than expected.
`done` uses `>=`; a test with a rider at exactly 100 m of 100 m is the one that catches someone changing it to `>`.

### Make the rule visible in the test

Use a tiny course (100 m) and round speeds (10, 12) so you can check the answer in your head. A test that needs
a calculator to verify is a test nobody reads.

### Write down the rules you chose

`init` with fewer than 8 speeds gives the rest 10 m/s. That's a decision, not an accident; a test makes it part of
the race's rules, and anyone who changes it finds out:

```zig
test "riders without a speed of their own ride at 10 m/s" {
    const race = Race.init(test_course, &.{12});
    try std.testing.expectEqual(@as(f64, 12), race.riders[0].speed_mps);
    try std.testing.expectEqual(@as(f64, 10), race.riders[7].speed_mps);
}
```

## expectEqual or expectEqualDeep

`expectEqual` compares values directly. For numbers, bools, arrays and plain structs that's what you want. For a
**slice** it compares where the slice points, not what's in it:

```text
expected slice ptr u8@12f49da, found u8@7ffe1fd7fe68
```

Two slices holding the same text in different places are not "equal" to `expectEqual`. `expectEqualDeep` follows
slices and pointers and compares what they hold, item by item, and says where they differ:

```text
expected 9.8, found 9
index 2 incorrect. expected 9.8, found 9
```

| Comparing | Use |
|---|---|
| numbers, bools, enums | `expectEqual` |
| arrays, plain structs | `expectEqual` (or `expectEqualDeep`) |
| text | `expectEqualStrings` |
| slices, or structs holding slices (a `Course` has a name) | `expectEqualDeep` |

## In the game

`Course` and `Race` arrive, and the race's rules move out of `main` into the type. Below `Rider`:

<<< @/code/steps/11-race/src/main.zig#race

`main` becomes "step until done":

<<< @/code/steps/11-race/src/main.zig#main

The tests check the race's rules on a 100 m test course, at the end of the file:

<<< @/code/steps/11-race/src/main.zig#tests

Run it (or copy `code/steps/11-race`). As with the last step, the printed race is exactly the same:

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

<<< @/code/steps/11-race/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/11-race.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/structure/11-a-race-type) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
