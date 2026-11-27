---
title: "Text on the road"
description: "Text is bytes: characters, strings and their types, comparing and joining them, buffers, @memset and bufPrint, and the race drawn as text."
group: "Basics"
order: 6
step: 09-text-road
---

# Text on the road

`leader is B` says who's winning. It doesn't *show* the race: who's close behind, who's dropped, how far there is to
go. A picture would, and in a terminal pictures are made of text. To draw the road as a line of text with each
rider's letter where they are, you need to know what text is in Zig: bytes.

## Characters are bytes

A single character in single quotes, `'A'`, is a **`u8`**: the number 65. So characters can be added and compared
like numbers:

```zig
const letter: u8 = 'A' + 2; // 'C'
std.debug.print("{c} is {d}\n", .{ letter, letter });
```

```text
C is 67
```

`{c}` prints a byte as its character; `{d}` as its number. That's how `riderName` turns index 2 into `C`.

## Strings are slices of bytes

Text in double quotes is a **string**: bytes in a row. Its exact type is a pointer to a fixed array of bytes ending
in a 0:

```zig
@TypeOf("ABC") // *const [3:0]u8
```

You rarely write that. It turns into the everyday string type, **`[]const u8`** (a slice of bytes you can read),
wherever one is expected. `title()` returns `[]const u8`; so does every function in the game that hands out text.

```zig
const name: []const u8 = "Compile Pass";
name.len  // 12
name[0]   // 'C', the byte 67
```

Because a string is a slice, everything from [Arrays and slices](/guide/basics/08-arrays-and-slices) applies:
`.len`, indexes, `name[0..7]` (`"Compile"`), `for (name) |c| ...` byte by byte.

### Bytes, not letters

`.len` counts **bytes**. Plain English letters are one byte each, but many characters take more:

```zig
"Rene".len // 4
"René".len // 5: é takes two bytes
```

Text in Zig is UTF-8 bytes. The game sticks to plain ASCII, so one byte is one character on screen; when that's not
true, counting bytes isn't counting letters.

## Comparing strings

`==` doesn't compare strings (just as it doesn't compare arrays):

```text
error: operator == not allowed for type '[]const u8'
```

Compare them byte by byte with `std.mem.eql`:

```zig
if (std.mem.eql(u8, word, "flat")) { ... }
```

You'll need this in Part 3, when the game reads its course from text.

## Joining strings

`++` joins two strings, but only ones known while compiling:

```zig
const full = "Terminal Tour: " ++ "Compile Pass"; // fine: both fixed
```

With a string that's only known while running, it won't build:

```text
error: unable to resolve comptime value
note: slice being concatenated must be comptime-known
```

Joining while running needs somewhere to put the result: a buffer.

## Buffers: making text while running

A **buffer** is an array of bytes you write into. Two ways to fill one:

- **By hand**: `@memset` fills it with one byte; then set single bytes by index.

```zig
var road: [10]u8 = undefined;
@memset(&road, '-');
road[0] = 'A';
road[4] = 'B';
std.debug.print("{s}\n", .{&road});
```

```text
A---B-----
```

- **With formatting**: `std.fmt.bufPrint` works like `print`, but into a buffer, and returns the slice it used:

```zig
var buf: [32]u8 = undefined;
const line = try std.fmt.bufPrint(&buf, "km {d} of {d}", .{ 9, 12.5 });
// line is "km 9 of 12.5": 12 of the buffer's 32 bytes
```

It returns an error if the text doesn't fit (`try`). `undefined` means "whatever was in that memory": fine for a
buffer you fill before reading, a bug if you read it first.

| You want | Use |
|---|---|
| a fixed piece of text | a string literal, `"..."` |
| to join fixed text | `++` |
| a line built from values | `std.fmt.bufPrint` into a buffer |
| a line drawn character by character | a buffer, `@memset`, and indexes |
| to compare text | `std.mem.eql(u8, a, b)` |

::: tip Try it
Make a 20-byte road, `@memset` it with `'.'`, put `'A'` at index 0 and `'|'` at the last index, and print it. Then
try putting a rider at index 20.
:::

## A rider's column

To place a rider on a road `n` characters wide, take how far along the course it is (0 at the start, 1 at the line)
times the last column, as a whole number:

```zig
const along = @min(position_m / distance_m, 1.0); // 0 to 1, never past the line
const column: usize = @intFromFloat(along * last);
```

`@intFromFloat` drops the fraction, so halfway along 8 columns (3.5) is column 3. `@min(a, b)` gives the smaller
value, keeping a rider past the line on the last column instead of off the end of the road (which would be out of
bounds).

```text
@memset          '-'  '-'  '-'  '-'  '-'  '-'  '-'  '-'
road[0] = 'A'    'A'  '-'  '-'  '-'  '-'  '-'  '-'  '-'
road[3] = 'B'    'A'  '-'  '-'  'B'  '-'  '-'  '-'  '-'
                  0    1    2    3    4    5    6    7
```

## In the game

`drawRoad` fills a buffer with dashes and puts each rider's letter in its column. Riders close together land in the
same column, and the last letter written there is the one you see. So it writes the rest of the field first, then
you (rider A), then the leader: the leader always shows, and so do you, unless you're in the leader's column. Below
`riderName`:

<<< @/code/steps/09-text-road/src/main.zig#road

In `main`, before the loop, room for the road:

<<< @/code/steps/09-text-road/src/main.zig#road-var

and in the loop, under the leader line, print it:

<<< @/code/steps/09-text-road/src/main.zig#print-road

Its tests, at the end of the file:

<<< @/code/steps/09-text-road/src/main.zig#tests

Run it (or copy `code/steps/09-text-road`):

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

At the start everyone shares the leader's column; by the end you can pick out several riders behind B (riders still
sharing a column hide each other).

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/09-text-road/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/09-text-road.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/basics/09-text-on-the-road) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
