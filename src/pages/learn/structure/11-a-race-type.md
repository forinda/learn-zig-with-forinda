---
title: "A race type"
description: "Check your understanding of structs of structs, init, *const self and testing well."
group: "Structure"
order: 2
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 11-race
competency: "I can write tests for the code I write"
---

# A race type

**Read first:** [A race type](/guide/structure/11-a-race-type) in the Guide. This lesson checks you understood it.

## Recall

::: quiz Why is it Race.init(...) and not race.init(...)?
- [ ] init is private
- [x] init makes a race, so there's no race yet to call it on: it has no self
- [ ] Every function in a struct is called on the type
- [ ] init is a builtin

`init` takes no `self`; it returns a new `Race`. Methods that work on an existing race (`step`, `leader`) are
called on a value.
:::

::: quiz Two slices hold the same text in different places. What does expectEqual say?
- [ ] They're equal
- [x] They're not equal: it compares where the slices point
- [ ] It doesn't compile
- [ ] It depends on the build mode

`expectEqual` on a slice compares its address and length. To compare what's in it, use `expectEqualDeep` (or
`expectEqualStrings` for text).
:::

## Predict

```zig
var a = Race.init(test_course, &.{ 10, 12 });
var b = a;
b.step();
b.step();
a.step();
std.debug.print("{d} {d} {d}\n", .{ a.clock_s, b.clock_s, b.riders[1].position_m });
```

::: quiz What does it print?
- [ ] 3 3 36
- [x] 1 2 24
- [ ] 2 2 24
- [ ] 1 2 12

`var b = a;` copies the whole race: course, eight riders, clock. `a` takes one step, `b` two; B in `b` rides at
12 m/s for 2 s.
:::

## Fix it

```zig
test "the clock starts at zero and ticks" {
    const race = Race.init(test_course, &.{10});
    try std.testing.expectEqual(@as(u32, 0), race.clock_s);
    race.step();
    try std.testing.expectEqual(@as(u32, 1), race.clock_s);
}
```

```text
error: expected type '*race.Race', found '*const race.Race'
```

::: quiz What's the fix?
- [x] var race = Race.init(...); the test steps the race, so it must be a variable
- [ ] Make step take self: *const Race
- [ ] Make step take self: Race
- [ ] Call Race.step(race)

`step` changes the race, so it needs a `*Race`, which only a `var` can give. A `*const` step couldn't add to the
clock, and `self: Race` would tick a copy.
:::

## Build it

### Exercise

Two riders at the same position: who leads? The rule in the game is "the lowest index wins a tie" (A before B).
Write a test that says so: a race with speeds `&.{ 10, 10 }`, one step, and `race.leader()` is `0`.

It passes at once, because `leaderOf` already uses `>`. Prove the test can catch a change: switch `>` to `>=` in
`leaderOf`, watch the test fail, and switch it back. A test you've never seen fail might not test anything.

```sh
zig build test --summary all
```
