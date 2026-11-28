---
title: "Searching text"
description: "Finding words in text: the naive search, std.mem's searches, Boyer-Moore-Horspool and its skip table, measured; and greedy word wrap."
group: "Data structures and algorithms"
order: 7
step: 28-text-search
---

# Searching text

A race produces a commentary: hundreds of lines of who leads, who attacks, who crosses the line. Somebody will ask
the obvious question: how often was *my* rider mentioned? That's searching text, the most common thing programs do
with text after printing it. And once there's a summary to print, it has to fit the screen: lines broken between
words, not in the middle of them.

## The naive search

Try the needle at every position of the haystack:

```zig
fn countNaive(haystack: []const u8, needle: []const u8) usize {
    var found: usize = 0;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) {
        if (std.mem.eql(u8, haystack[i..][0..needle.len], needle)) {
            found += 1;
            i += needle.len; // matches don't overlap
        } else i += 1;
    }
    return found;
}
```

For a haystack of `n` bytes and a needle of `m`, that's up to `n × m` comparisons. In ordinary text, most tries fail
on the first byte, so it's closer to `n`.

## std.mem's searches

| Function | Gives |
|---|---|
| `std.mem.indexOf(u8, text, needle)` | `?usize`: the first match |
| `std.mem.indexOfPos(u8, text, start, needle)` | the first match at or after `start` |
| `std.mem.lastIndexOf(u8, text, needle)` | the last match |
| `std.mem.count(u8, text, needle)` | how many, without overlaps |
| `std.mem.indexOfScalar(u8, text, byte)` | the first of one byte |
| `std.mem.startsWith`, `endsWith` | `bool` |

```zig
const feed = "Heap takes the lead. Buffer attacks. Heap leads.";
```

In that feed, `indexOf` finds `"Heap"` at 0; `indexOfPos` from 1 finds the next at 37, which is also the
`lastIndexOf`; `"Errdefer"` gives `null`; `count` gives 2.

Use these first. They're tested, and for longer needles `indexOf` switches to a smarter algorithm by itself.

## Boyer-Moore-Horspool: skipping ahead

The naive search moves one byte at a time. Horspool's idea: compare the needle at a position, and if it doesn't
match, look at the haystack byte under the needle's *last* position. If that byte appears nowhere in the needle,
no position overlapping it can match: jump the needle's whole length. If it does appear, jump just far enough to
line them up.

The jumps come from a **skip table**, built once from the needle: for every possible byte, how far to jump.

```zig
var skip: [256]usize = @splat(needle.len); // bytes not in the needle: the whole length
for (needle[0 .. needle.len - 1], 0..) |b, i| skip[b] = needle.len - 1 - i;
```

For the needle `lead`:

```text
l:3 e:2 a:1 d:4 x:4
```

`x` isn't in the needle, so it skips 4. `a` is one from the end, so it skips 1 and lines the needle's `a` up with it.
The needle's own last byte (`d`) isn't counted from the end, so a `d` that didn't match still skips the full
length. With a long needle in ordinary text, most jumps are the full length: the search reads only a fraction of the
haystack.

### Measured

Counting a name that never appears ("Errdefer crosses the line") in a 4 MB commentary, `fast` build:

```text
4 MB: naive 2.93 ms, std.mem.count 0.91 ms, Horspool 0.65 ms
```

Horspool and `std.mem.count` read a fraction of the text; the naive search reads all of it. On very repetitive text
(megabytes of `a` and a needle of `a`s ending in `b`) every algorithm here has to compare nearly everything, and
`std.mem.eql`'s byte-comparing speed decides it: measure your own data.

::: tip Try it
Build the skip table for the needle `Heap`, print the skips for `H`, `e`, `a`, `p` and `x`, and work out by hand how
the search moves through `"The Heap leads"`.
:::

## Word wrap

The summary sentence has to fit 40 columns. **Greedy** wrapping puts as many words as fit on each line, then starts
the next:

```zig
fn wrap(w: *std.Io.Writer, text: []const u8, width: usize) !void {
    var column: usize = 0;
    var words = std.mem.tokenizeScalar(u8, text, ' ');
    while (words.next()) |word| {
        if (column > 0 and column + 1 + word.len > width) { // the word won't fit: new line
            try w.writeByte('\n');
            column = 0;
        }
        if (column > 0) column += try w.write(" ");
        column += try w.write(word);
    }
    if (column > 0) try w.writeByte('\n');
}
```

A word longer than the width gets a line of its own (cutting words is worse than an overlong line). Greedy isn't
always the *prettiest*: it can leave one line very short. Balancing every line's length is a dynamic programming
problem (the [next page](/guide/data-structures/29-edit-distance) is about dynamic programming); for a terminal,
greedy is what everyone uses.

`column` counts bytes, which is right for the game's ASCII names. Text with characters of more than one byte (é, ✓)
needs counting characters instead (Part 9).

## Which search when

| You need | Use | Because |
|---|---|---|
| one search, any text | `std.mem.indexOf` / `count` | correct, fast, done |
| one byte | `std.mem.indexOfScalar` | vectorised |
| the same needle over lots of text | Horspool (or `indexOf`, which uses it for long needles) | the skip table is built once |
| many different needles at once | a trie or Aho-Corasick | one pass for all of them |
| "is this word one of these?" | a hash set or `std.StaticStringMap` | no scanning at all |

## In the game

The race keeps its whole commentary as text, and at the finish writes a summary, counting your rider's mentions
with Horspool. Below the marks:

<<< @/code/steps/28-text-search/src/main.zig#text

In `playRace`, next to the feed, the commentary log, and each event appends a line to it
(`try log.writer.print("{s} takes the lead.\n", ...)`, and so on):

<<< @/code/steps/28-text-search/src/main.zig#log

After "led the race", the summary, wrapped to 40 columns:

<<< @/code/steps/28-text-search/src/main.zig#summary

The tests check Horspool against the naive search and `std.mem.count`, and wrap's two promises:

<<< @/code/steps/28-text-search/src/main.zig#tests

Run it (or copy `code/steps/28-text-search`) as Heap:

```sh
zig build run
```

```text
led the race: Buffer Errdefer Heap
Heap wins Compile Pass in 21:43, 88 m
ahead of Buffer, with Alloc third. Heap,
your rider, was mentioned 9 times in the
commentary.
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/28-text-search/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/28-text-search.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/data-structures/28-searching-text) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
