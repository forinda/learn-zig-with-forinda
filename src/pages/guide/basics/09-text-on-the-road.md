---
title: "Text on the road"
description: "Text is bytes: characters, buffers and @memset, and the race drawn as a line of text."
group: "Basics"
order: 6
step: 09-text-road
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
`@min(a, b)` gives the smaller of two values: `@min(position_m / distance_m, 1.0)` keeps a rider past the line on the
last column instead of off the end of the road.

## Elaborate

**I do:** `drawRoad` fills a buffer with dashes and puts each rider's letter in its column. Riders close together land
in the same column, and the last letter written there is the one you see. So it writes the rest of the field first,
then you (rider A), then the leader: the leader always shows, and so do you, unless you're in the leader's column.
Here's the new code, piece by piece, and where each goes.

Below `riderName`, `drawRoad` and the column it puts a rider in:

<<< @/code/steps/09-text-road/src/main.zig#road

In `main`, before the loop, room for the road:

<<< @/code/steps/09-text-road/src/main.zig#road-var

and in the loop, under the leader line, print it:

<<< @/code/steps/09-text-road/src/main.zig#print-road

Its tests, at the end of the file:

<<< @/code/steps/09-text-road/src/main.zig#tests

**We do:** make the changes (or copy `code/steps/09-text-road`) and run it:

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
  --------------------------------EAHB--------------
km 12 at 19:14: leader is B
  -------------------------------------------EGAHB--
B wins in 20:02
```

Watch the field spread out: at the start everyone shares the leader's column, and by the end you can pick out
several riders behind B (riders still sharing a column hide each other).

<details>
<summary>The whole <code>src/main.zig</code> after this step</summary>

<<< @/code/steps/09-text-road/src/main.zig

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/09-text-on-the-road) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
