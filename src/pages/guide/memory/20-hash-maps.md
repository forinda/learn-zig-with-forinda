---
title: "Hash maps"
description: "Looking values up by key: StringHashMap and AutoHashMap, put, get, getPtr, getOrPut, remove, iterating, owning string keys, and sorting what a map holds."
group: "Memory"
order: 5
step: 20-hashmap
---

# Hash maps

One race, one winner. Race again and the game forgets the first. A season keeps score: how many wins has Heap
got? Buffer? To answer "how many for *this name*", you could keep a list of names and counts and search it every
time. A **hash map** answers it directly: give it a key, it finds the value, however many entries it holds.

## A map from names to wins

```zig
var wins: std.StringHashMapUnmanaged(u32) = .empty;
defer wins.deinit(gpa);
try wins.put(gpa, "Heap", 2);
try wins.put(gpa, "Buffer", 1);
try wins.put(gpa, "Heap", 3); // the same key again: replaces 2
```

`StringHashMapUnmanaged(V)` maps text (`[]const u8`) to values of type `V`. Like `ArrayList`, it starts
`.empty`, takes the allocator on each call that may allocate, and needs a `deinit`.

| Call | Gives | When the key isn't there |
|---|---|---|
| `put(gpa, key, value)` | adds, or replaces the value | adds it |
| `get(key)` | `?V`: the value | `null` |
| `getPtr(key)` | `?*V`: a pointer to change it in place | `null` |
| `contains(key)` | `bool` | `false` |
| `remove(key)` | `bool`: whether it was there | `false` |
| `count()` | how many entries | |

`get` returns an optional because "no such key" is a normal answer: `wins.get("Alloc") orelse 0`.

### Add or update in one step: getOrPut

"Add one to this name's count, starting at zero if it's new" is the most common map operation. `getOrPut` finds
the entry or makes one, and tells you which:

```zig
const entry = try wins.getOrPut(gpa, "Defer");
if (!entry.found_existing) entry.value_ptr.* = 0; // new: its value is undefined until you set it
entry.value_ptr.* += 1;
```

One lookup instead of two (`get` then `put`). If you skip setting a new entry's value, you add to garbage.

### Keys that aren't text

`AutoHashMapUnmanaged(K, V)` works for keys Zig knows how to hash by value: numbers, letters, enums, plain structs.
The game could count wins by rider letter:

```zig
var by_letter: std.AutoHashMapUnmanaged(u8, u32) = .empty;
try by_letter.put(gpa, 'H', 2);
```

Slices aren't allowed there, because "same slice" could mean the same memory or the same contents:

```text
error: std.hash.autoHash does not allow slices here ([]const u8) because the intent is unclear. Consider using std.StringHashMap for hashing the contents of []const u8.
```

Text keys use `StringHashMap`, which compares contents.

## The map keeps your key, not a copy of it

`put` stores the key slice you give it: a pointer and a length, not the bytes. If those bytes change or are freed,
the map's key changes under it:

```zig
var line = "Heap".*;
try wins.put(gpa, &line, 1);
line = "Junk".*; // the buffer the key came from is reused
```

```text
Heap: null  Junk: null
```

Neither lookup finds it: the entry was filed under "Heap", but its key now reads "Junk". In the game the names
come from each race's field, which is freed when the race ends, so the map needs **its own copy** of each name,
and must free those copies itself:

```zig
const key = try gpa.dupe(u8, name);
errdefer gpa.free(key);
try standings.put(gpa, key, 1);
```

and before `deinit`, free every key:

```zig
var keys = standings.keyIterator();
while (keys.next()) |key| gpa.free(key.*);
standings.deinit(gpa);
```

## Going through a map

`iterator()` gives every entry; `keyIterator()` and `valueIterator()` give one side. Each item is a pointer
(`key_ptr`, `value_ptr`), so you can change values as you go:

```zig
var it = wins.iterator();
while (it.next()) |entry| std.debug.print("{s}={d} ", .{ entry.key_ptr.*, entry.value_ptr.* });
```

The order is whatever the map's internal layout happens to be. It isn't the order you added things, it isn't
sorted, and it can change as the map grows. For a table in order, copy the entries into a list and sort it:

```zig
std.mem.sort(Row, rows.items, {}, Row.before);
```

`std.mem.sort` takes the item type, the slice, a context value (`{}`: none needed) and a function
`fn (context, a, b) bool` that says whether `a` goes before `b`.

::: tip Try it
Count the letters of `"compile pass"` in an `AutoHashMapUnmanaged(u8, u32)` with `getOrPut`, then print the
counts. Print them a second time after adding more text. Is the order the same?
:::

## A list or a map

| You need | Use | Because |
|---|---|---|
| items in order, by position | `ArrayList` | index 0, 1, 2… |
| to look things up by a key | a hash map | straight to the entry, no search |
| keys that are text | `StringHashMap` | compares contents |
| keys that are numbers, letters, enums | `AutoHashMap` | hashes the value |
| lookups *and* an order | a map for lookups, a list (sorted) for the order | each does one job |

What goes wrong with the wrong one: searching a list for every lookup gets slower with every entry; a map
printed straight from its iterator comes out in a different order from run to run of the code that fills it.

## In the game

"Race again?" Each new race alternates between two courses (Compile Pass, and the flatter Linker Loop), and the
standings keep wins per rider name across them. The second course, below `compile_pass_text`:

<<< @/code/steps/20-hashmap/src/main.zig#courses

The standings: the map, recording a win, freeing it, and printing it sorted. Below the courses:

<<< @/code/steps/20-hashmap/src/main.zig#map

In `main`, the standings are made before the first race and freed after the last:

<<< @/code/steps/20-hashmap/src/main.zig#standings

and the race becomes a loop. Each round parses its course and loads a fresh field (the `defer`s inside the loop
free them at the end of each round), then records the win and asks again:

<<< @/code/steps/20-hashmap/src/main.zig#loop

The tests, at the end of the file:

<<< @/code/steps/20-hashmap/src/main.zig#tests

Run it (or copy `code/steps/20-hashmap`) and race three times:

```sh
zig build run
```

```text
race 1: Compile Pass
...
winner: H (Heap)
you (H) crossed the line!
standings:
  1  Heap
Race again? (y/n) y

race 2: Linker Loop
...
winner: B (Buffer)
you (H) were 3 m from the line
standings:
  1  Buffer
  1  Heap
Race again? (y/n) y

race 3: Compile Pass
...
standings:
  2  Heap
  1  Buffer
Race again? (y/n) n
```

On the flat Linker Loop, Buffer (the fastest on the flat) beats Heap by 3 m. With no input, the game races once
and stops.

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/20-hashmap/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/20-hashmap.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/memory/20-hash-maps) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
