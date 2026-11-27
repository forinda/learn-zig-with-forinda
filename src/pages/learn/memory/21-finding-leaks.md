---
title: "Finding leaks"
description: "Check your understanding of leak reports, arenas and choosing an allocator, then build a season that leaks nothing."
group: "Memory"
order: 6
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 21-leaks
competency: "I can find a memory leak with a test"
---

# Finding leaks

**Read first:** [Finding leaks](/guide/memory/21-finding-leaks) in the Guide. This lesson checks you understood it.

## Recall

::: quiz A leak report's trace says "allocated at" ... loadField ... playRace. Where's the bug?
- [ ] On the first line of the trace, inside std
- [ ] Always in loadField, where the memory was allocated
- [x] Wherever the memory's owner should have freed it: the trace shows where it was allocated, not where the free is missing
- [ ] In the test

The trace is the call stack at the allocation. Start at the first frame in your code, then ask who owns that
memory and why they didn't free it (in step 21 without `arena.deinit`, that's `playRace`).
:::

::: quiz The standings must last all season; a race's course and field only last the race. Which allocators?
- [ ] An arena for both
- [ ] gpa for both, freeing everything one by one
- [x] gpa for the standings, an arena per race for the course and field
- [ ] init.arena for both

An arena frees its whole batch at once, which suits a race. The standings outlive every race, so they can't
come from a race's arena; an arena for the whole season would never free each race's memory.
:::

## Predict

```zig
var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
defer arena.deinit();
const a = arena.allocator();
const one = try a.dupe(u8, "Heap");
const two = try a.dupe(u8, "Buffer");
std.debug.print("{s} {s}\n", .{ one, two });
```

::: quiz Run as a test: what happens?
- [ ] It prints, then the test fails: one and two leaked
- [x] It prints "Heap Buffer" and passes: arena.deinit frees both
- [ ] It doesn't compile: an arena isn't a std.mem.Allocator
- [ ] It panics: the testing allocator can't back an arena

`arena.allocator()` is a `std.mem.Allocator` like any other. The arena got its memory from the testing allocator
and gives it all back in `deinit`, so nothing leaks.
:::

## Fix it

```zig
fn fastest(gpa: std.mem.Allocator, roster: []const []const u8, speeds: []const f64) ![]const u8 {
    var best: usize = 0;
    for (speeds, 0..) |s, i| if (s > speeds[best]) {
        best = i;
    };
    const label = try std.fmt.allocPrint(gpa, "{s} ({d} m/s)", .{ roster[best], speeds[best] });
    if (speeds[best] < 10) return "nobody fast";
    return label;
}
```

Two tests, one fast field and one slow:

```text
1/2 lk.test.the fastest rider is labelled...OK
2/2 lk.test.nobody fast...OK
[SafeAllocator] (err): leaked [addr: 7fab5479c0a0, len: 16 (0x10) align: 1] allocated at:
lk.zig:8:41: in fastest (lk.zig)
All 2 tests passed.
1 tests leaked memory.
```

::: quiz What's the fix?
- [x] Check for "nobody fast" before allocPrint, and return try gpa.dupe(u8, "nobody fast") so the caller can always free what it gets
- [ ] Add errdefer gpa.free(label); after allocPrint
- [ ] Add defer gpa.free(label); after allocPrint
- [ ] Free the label in the "nobody fast" test

The early return drops `label` without freeing it. `errdefer` doesn't run (no error is returned); `defer` frees
the label the fast case returns; and the slow test gets a string literal, which can't be freed. Returning
allocated memory every time gives the caller one rule: free it.
:::

## Build it

### Exercise

Run the planted leak above yourself: save it as `lk.zig`, run `zig test lk.zig`, and find the line of `lk.zig` the
trace points at. Fix it as the quiz says, add `defer gpa.free(label);` to the slow test, and run again until the
last line is `All 2 tests passed.` with nothing leaked.

Then in the game: delete `defer arena.deinit();` from `playRace`, run `zig build test`, read the report, and put
it back.

```sh
zig build test --summary all
```

## Stretch

**Part 4's challenge: a season.** Before the first race, ask "How many races in the season? (default 3)" and race
that many, alternating courses. Keep the standings across them, and print the final table with the player's
position in it called out.

- A test that runs a three-race season under `std.testing.allocator` and checks the final standings (it fails on
  any leak).
- A test for what an answer of `0`, `-2` or `many` does (your rule: maybe one race, maybe a note on stderr).
- Everything a race allocates comes from its arena; everything that lasts the season, from `gpa`.

Any season that races, prints a final table, and passes both tests with nothing leaked counts.
