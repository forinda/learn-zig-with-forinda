---
title: "Text on the road"
description: "Text is bytes: characters, buffers and @memset, and the race drawn as a line of text."
group: "Basics"
order: 6
layout: /src/layouts/lesson.tscl
steps: true
minutes: 25
step: 09-text-road
competency: "I can work with arrays, slices and text"
---

# Text on the road

**Read first:** [Text on the road](/guide/basics/09-text-on-the-road) in the Guide. This lesson checks you understood it.

## Recall

::: quiz What is the character 'C' to Zig?
- [ ] A string of length 1
- [x] A u8, a number (67), so 'A' + 2 is 'C'
- [ ] A special char type
- [ ] An f64

Characters in single quotes are bytes, plain `u8` numbers. Strings in double quotes are slices of them.
:::

::: quiz What does @memset(&road, '-') do?
- [ ] Prints the road
- [x] Fills every byte of road with '-'
- [ ] Clears the road to zeros
- [ ] Makes the road longer

`@memset` sets every element of an array or slice to one value.
:::

## Predict

```zig
const letter: u8 = 'A' + 3;
std.debug.print("{c}\n", .{letter});
```

::: quiz What does it print?
- [ ] A3
- [ ] 68
- [x] D
- [ ] It doesn't compile

`'A'` is 65, plus 3 is 68, and `{c}` prints a byte as its character: `D`.
:::

## Fix it

```zig
var road: [5]u8 = undefined;
@memset(&road, '-');
road[0] = "A";
```

```text
error: expected type 'u8', found '*const [1:0]u8'
```

::: quiz What's the fix?
- [x] road[0] = 'A';
- [ ] road[0] = @as(u8, "A");
- [ ] road = "A----";
- [ ] Make road a []const u8

`"A"` is a string (a pointer to bytes), `'A'` is one byte. One element of the road is one byte.
:::

## Build it

### Exercise

Mark the player: rider A is drawn as `@` instead of `A`. Write a test first that draws rider A at the start and checks
column 0 holds `@`.

Hint: `riderName` is used for the letter. Where would you choose `@` for index 0 without changing the other riders?
When you run it, `@` shows from about km 5: before that you're in the leader's column, and the leader is drawn last.

```sh
zig build run
zig build test --summary all
```

## Stretch

**Part 2's challenge: make the road yours.** Pick one or more, and write a test for what you add:

- Show the finish line: a `|` in the last column, unless a rider is there.
- Add a second line under the road with a tick every kilometre: `|----|----|...`.
- Show the gap from the leader to last place in metres on each line.
- Something else that makes the race easier to read.

Any answer that passes its own test and prints a clearer road counts. Mind the drawing order: whatever is written
last in a column is what shows, so write a finish line before the riders, not after.
