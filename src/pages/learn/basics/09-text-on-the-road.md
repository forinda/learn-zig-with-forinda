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

## Engage

`leader is B` tells you who's winning. It doesn't show you the race: who's close behind, who's dropped, how far
there is to go. A picture would. In a terminal, pictures are made of text.

So the road becomes a line of text, with each rider's letter where they are along it.

## Explore

Save this as `road.zig` and run it:

```zig
const std = @import("std");

pub fn main() void {
    var road: [10]u8 = undefined;
    @memset(&road, '-');
    road[0] = 'A';
    road[4] = 'B';
    std.debug.print("{s}\n", .{&road});
}
```

It prints `A---B-----`. Try putting a rider at index `10`. Then try writing `'BB'` instead of `'B'`.

## Explain

In Zig, **text is bytes**. A single character in single quotes, `'A'`, is a `u8`: the number 65. A string in double
quotes, `"Terminal Tour"`, is a slice of bytes, `[]const u8`. That's why `title()` returns `[]const u8`.

Because characters are numbers, you can do sums with them: `'A' + 1` is `'B'`. That's how `riderName` turns an index
into a letter.

To build a line of text, you need somewhere to put it: a **buffer**, an array of bytes. `@memset` fills it with one
character, then you set single bytes by index and print it with `{s}`:

```text
@memset          '-'  '-'  '-'  '-'  '-'  '-'  '-'  '-'
road[0] = 'A'    'A'  '-'  '-'  '-'  '-'  '-'  '-'  '-'
road[3] = 'B'    'A'  '-'  '-'  'B'  '-'  '-'  '-'  '-'
                  0    1    2    3    4    5    6    7
```

A rider's column is how far along the course it is (0 at the start, 1 at the line) times the last column, as a
whole number: `@intFromFloat(along * last)`. That rounds down, so halfway along 8 columns (3.5) is column 3.

## Elaborate

**I do:** `drawRoad` fills a buffer with dashes and puts each rider's letter in its column. Riders close together land
in the same column, and the last letter written there is the one you see, so it writes the leader last: the race's
leader always shows. Here's the change:

<<< @/code/diffs/09-text-road.diff

**We do:** make the change (or copy `code/steps/09-text-road`) and run it:

```sh
zig build run
```

```text
km 1 at 1:37: leader is B
  ---B----------------------------------------------
km 2 at 3:13: leader is B
  -------B------------------------------------------
...
km 9 at 14:26: leader is B
  --------------------------------EGHB--------------
km 12 at 19:14: leader is B
  -------------------------------------------EGDHB--
B wins in 20:02
```

Watch the field spread out: at the start everyone shares a column, and by the end they're strung out behind B.

## Evaluate

::: quiz What is the character 'C' to Zig?
- [ ] A string of length 1
- [x] A u8, a number (67), so 'A' + 2 is 'C'
- [ ] A special char type
- [ ] An f64

Characters in single quotes are bytes, plain `u8` numbers. Strings in double quotes are slices of them.
:::

```sh
zig build test --summary all
```

### Exercise

**Part 2's challenge: make the road yours.** Pick one (or more) and write a test for what you add:

- Mark the player's rider differently: rider A becomes `@`.
- Show the finish line: a `|` in the last column, unless a rider is there.
- Add a second line under the road with a tick every kilometre: `|----|----|...`.
- Something else that makes the race easier to read.

Any answer that passes its own test and prints a clearer road counts. Hint: a test can draw into a small buffer,
like the `drawRoad` tests, and check single columns with `line[i]`.
