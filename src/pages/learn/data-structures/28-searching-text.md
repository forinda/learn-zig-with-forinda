---
title: "Searching text"
description: "Check your understanding of text search, std.mem's searches, Horspool's skip table and word wrap."
group: "Data structures and algorithms"
order: 7
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 28-text-search
competency: "I can sort and search, and measure what they cost"
---

# Searching text

**Read first:** [Searching text](/guide/data-structures/28-searching-text) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz You need to know whether a line of the feed contains "crosses the line". What do you reach for first?
- [x] std.mem.indexOf (or std.mem.count)
- [ ] A hand-written Horspool search
- [ ] The naive search
- [ ] A trie

The standard library's search is correct, fast, and already uses a skipping algorithm for longer needles. Write your
own when you've measured a reason to.
:::

::: quiz Why can Horspool skip the needle's whole length when the byte under the needle's last position isn't in the needle at all?
- [ ] Because the needle is sorted
- [x] Because any position overlapping that byte would have to match it, and no byte of the needle can
- [ ] Because the haystack is ASCII
- [ ] It can't: it always moves one byte

Every position whose window covers that byte would need it to equal some byte of the needle. None does, so they can
all be skipped.
:::

## Predict

The skip table from the Guide, built for the needle `Heap`:

```zig
var skip: [256]usize = @splat(needle.len);
for (needle[0 .. needle.len - 1], 0..) |b, i| skip[b] = needle.len - 1 - i;
std.debug.print("{d} {d} {d} {d}\n", .{ skip['H'], skip['e'], skip['p'], skip[' '] });
```

::: quiz What does it print?
- [ ] 0 1 3 4
- [x] 3 2 4 4
- [ ] 3 2 0 4
- [ ] 4 3 2 1

`H` is 3 from the end, `e` 2. The last byte, `p`, isn't counted (the loop stops before it), so it keeps the full
length, 4, like a space, which isn't in the needle at all.
:::

## Fix it

```zig
if (column > 0 and column + word.len > width) { // the word won't fit: new line
```

The step's own tests:

```text
error: 'main.test.wrapping never makes a line longer than the width, and keeps every word' failed:
error: 'main.test.a word longer than the width gets a line of its own' failed:
```

::: quiz What's the fix?
- [x] Count the space before the word: column + 1 + word.len > width
- [ ] Use >= instead of >
- [ ] Start column at 1
- [ ] Wrap at width - 1 everywhere

A word after the first on a line also needs a space before it. Without counting it, a line can end up one column
too long. `>=` would break lines that fit exactly; the other two move the problem around.
:::

## Build it

### Exercise

Make the mention count case-insensitive, so "heap" in the commentary counts too: lower-case the needle and build the
skip table from it, and compare bytes with `std.ascii.toLower` (look up the skip with the lower-cased haystack
byte). Tests first: "Heap HEAP heap" contains 3 of "heap", and the result still agrees with a naive search over a
lower-cased copy of the text.

```sh
zig build test --summary all
```
