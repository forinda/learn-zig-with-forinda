---
title: "Tries"
description: "Check your understanding of tries: shared prefixes, nodes by index, completion, and the alternatives."
group: "Data structures and algorithms"
order: 9
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 30-tries
competency: "I can pick the right data structure for a job and say why"
---

# Tries

**Read first:** [Tries](/guide/data-structures/30-tries) in the Guide. This lesson checks you understood it.

## Recall

::: quiz Why does the game's trie join its nodes by index, not by pointer?
- [ ] Indexes are smaller than pointers
- [x] The nodes live in one ArrayList, which can move when it grows; an index still means the same node, a pointer would go stale
- [ ] Zig doesn't allow pointers in structs
- [ ] To make the trie sorted

Appending a node can move every node to a new block of memory. Pointers into the old block would point at freed
memory; indexes into the list stay right.
:::

::: quiz The terrain words are fixed: flat, climb, descent. What's the simplest way to look one up from text?
- [ ] A trie
- [ ] A sorted list and binary search
- [x] std.StaticStringMap, built while compiling
- [ ] Edit distance

A fixed set of exact words known while compiling: a static map, no allocation. A trie earns its place with
prefixes and words added while running.
:::

## Predict

```zig
var trie: Trie = try .init(gpa);
for ([_][]const u8{ "Gamma", "Garnet", "Generic", "Heap" }, "GRNH") |w, v| try trie.insert(gpa, w, v);
std.debug.print("{d} nodes\n", .{trie.nodes.items.len});
```

::: quiz How many nodes?
- [ ] 23
- [x] 20
- [ ] 22
- [ ] 4

The root, then `gamma` (5), `rnet` (4 more: `ga` is shared), `eneric` (6: only `g` is shared), `heap` (4): 1 + 5 +
4 + 6 + 4 = 20. Without sharing it would be 1 + 22 = 23.
:::

## Fix it

`complete` walks the prefix like this:

```zig
for (prefix) |raw| node = self.child(node, raw) orelse return found[0..0];
```

```text
error: 'main.test.a trie finds the words it holds, ignoring case' failed:
       slices differ. first difference occurs at index 0 (0x0)
       ============ expected this output: =============  len: 1 (0x1)
       ============= instead found this: ==============  len: 0 (0x0)
```

::: quiz What's the fix?
- [x] Look up std.ascii.toLower(raw): the trie stores letters in lower case
- [ ] Store letters as typed in insert
- [ ] Compare with std.ascii.eqlIgnoreCase
- [ ] Return all words when nothing matches

`insert` lower-cases every letter, so a lookup with `H` finds no child. Storing letters as typed would make `heap`
and `Heap` different words; `eqlIgnoreCase` compares slices, not the single letters a node holds.
:::

## Build it

### Exercise

Let a single letter work both ways: today `h` means "rider H" (the letter path) and never reaches the trie. Make
the question try the trie first for any answer, and fall back to the letter only when the trie finds nothing or
more than one. Tests first: `h` picks H, `e` picks E, `ga` (with a roster that has Gamma and Garnet) is ambiguous,
and `z` falls back to A. Then decide: is "trie first" better for players than "letter first"? Write your reason in
a comment.

```sh
zig build test --summary all
```
