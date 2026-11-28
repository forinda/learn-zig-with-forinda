---
title: "Edit distance"
description: "Check your understanding of edit distance, recursion vs dynamic programming, and thresholds."
group: "Data structures and algorithms"
order: 8
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 29-edit-distance
competency: "I can solve a problem with prefix sums, windows or dynamic programming"
---

# Edit distance

**Read first:** [Edit distance](/guide/data-structures/29-edit-distance) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz Why is the recursive edit distance so slow?
- [ ] Recursion is slow in Zig
- [x] It works out the distance between the same prefixes again and again: about three times more calls per letter
- [ ] It compares every letter with every other letter
- [ ] It allocates on every call

The distinct questions are only "prefix i of a versus prefix j of b". Dynamic programming answers each of those
once, in a table.
:::

::: quiz Why can the two-row version throw away all but the last row?
- [ ] Because the answer is always in the first row
- [x] Because each cell only uses the row above it and the cell to its left
- [ ] Because the words are short
- [ ] It can't: it gives a different answer

`t[i][j]` needs `t[i-1][j]`, `t[i][j-1]` and `t[i-1][j-1]`: the previous row and the current one.
:::

## Predict

With the game's `editDistance` (which ignores case):

```zig
std.debug.print("{d} {d} {d}\n", .{
    try editDistance(gpa, "Heap", "Help"),
    try editDistance(gpa, "defer", "deferred"),
    try editDistance(gpa, "abc", "cab"),
});
```

::: quiz What does it print?
- [ ] 1 3 3
- [x] 1 3 2
- [ ] 2 3 2
- [ ] 1 8 3

`a` to `l` is one change. `deferred` is `defer` plus three inserts. `abc` to `cab`: insert `c` at the front and
delete the last `c`, two edits.
:::

## Fix it

The two-row version, with the swap left out:

```zig
for (a, 1..) |letter_a, i| {
    current[0] = i;
    for (b, 1..) |letter_b, j| { ... }
}
return previous[b.len];
```

```text
src/main.zig:585:9: error: local variable is never mutated
    var previous = rows[0 .. b.len + 1];
        ^~~~~~~~
```

::: quiz What's the fix?
- [x] std.mem.swap([]usize, &previous, &current); at the end of each row
- [ ] Make previous a const
- [ ] return current[b.len] instead
- [ ] Copy current into previous with @memcpy, and keep previous a var

Without the swap, every row is computed from the first row, and the answer is wrong. The compiler noticed that
`previous` never changes. Making it `const` silences the compiler and keeps the wrong answer. `@memcpy` of the row
would work, but it copies a whole row where swapping two slices copies nothing.
:::

## Build it

### Exercise

Suggest terrain names in course text, ready for Part 9, when courses come from files: make `parseCourse` take an
optional `*Diagnostic` (`struct { word: []const u8 = "", suggestion: ?[]const u8 = null }`), and on
`error.UnknownTerrain` fill it with the word and the closest of `flat`, `climb` and `descent` within 2 edits. Tests
first: `clmb 2000 6` suggests `climb`, `decsent 2000 -6` suggests `descent`, and `gravel 100` suggests nothing.

```sh
zig build test --summary all
```
