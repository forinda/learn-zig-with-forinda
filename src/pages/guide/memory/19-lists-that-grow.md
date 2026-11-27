---
title: "Lists that grow"
description: "std.ArrayList: append, items, length and capacity, removing, handing the memory out with toOwnedSlice, and why a pointer into a list goes stale when it grows."
group: "Memory"
order: 4
step: 19-arraylist
---

# Lists that grow

The roster loader counts the lines first, then allocates exactly that many riders, then reads the lines again.
And the race still copies the field into eight fixed places, so a ninth rider is an error. The course parser has
the same problem: a fixed buffer of 16 segments and an error for the 17th. Both are lists whose length you only
learn by reading them. A list that grows as you add to it is the most used data structure there is, and in Zig
it's `std.ArrayList`.

## An ArrayList

```zig
var speeds: std.ArrayList(f64) = .empty;
defer speeds.deinit(gpa);
try speeds.append(gpa, 10.0);
try speeds.append(gpa, 10.4);
try speeds.appendSlice(gpa, &.{ 9.8, 10.1, 9.6 });
```

- **`.empty`** is a list with nothing in it and no memory yet.
- **`append`** adds one item at the end; **`appendSlice`** several. Both can need more memory, so they take the
  allocator and can fail (`try`).
- **`items`** is a slice of what's in it, right now: `speeds.items.len`, `speeds.items[0]`, `for (speeds.items)`.
- **`deinit`** gives the memory back. Like any allocation, forget it and the leak report says so.

The allocator goes into every call that might allocate, not into the list. That's the convention across Zig's
standard library: you can always see which calls can allocate (and fail) by whether they take one.

### Length and capacity

A list holds more memory than it uses, so most appends don't need to ask for more:

```text
len 2 cap 17
len 5 cap 17
```

When an append needs more than the **capacity**, the list asks for a bigger block (much bigger, so it won't have
to ask again soon), copies the items over, and frees the old block. If you know how many are coming, ask once:

```zig
try list.ensureTotalCapacity(gpa, 8);  // room for at least 8
list.appendAssumeCapacity(x);          // no allocator, can't fail
```

`appendAssumeCapacity` past the capacity stops the program (`panic: reached unreachable code`).

### Taking things out

| Call | Does | Order |
|---|---|---|
| `pop()` | removes the last item, returns it (`null` if the list is empty) | kept |
| `orderedRemove(i)` | removes item `i`, shifting the rest down | kept, slower for long lists |
| `swapRemove(i)` | removes item `i`, moving the last item into its place | changed, fast |
| `clearRetainingCapacity()` | empties it, keeps the memory for reuse | |

## Pointers into a list go stale

Growing moves the items to a new block. Any pointer or slice into the old block now points at freed memory:

```zig
try speeds.append(gpa, 10.0);
const first = &speeds.items[0];
for (0..1000) |_| try speeds.append(gpa, 1); // the list moves
std.debug.print("{d}\n", .{first.*});         // reads the old, freed block
```

```text
11945305291614955000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

Nothing stops you: it compiles and, often, seems to work (the old memory may not have been reused yet). Rule: a
pointer or slice into a list is good only until the list next changes size. Keep an index instead, or finish
growing before you take pointers.

## Handing the memory out: toOwnedSlice

A function that builds a list and returns it usually returns a plain slice, not the list.
`toOwnedSlice` gives you the items as a slice of exactly the right length, owned by you, and leaves the list
empty:

```zig
var field: std.ArrayList(Rider) = .empty;
errdefer field.deinit(gpa);
// ... append the riders ...
return field.toOwnedSlice(gpa); // the caller frees it with gpa.free
```

The caller doesn't need to know a list was involved: it gets a `[]Rider` and frees it like any slice.

### Building a list that owns things

When the items own memory themselves (each rider's name), the `errdefer` for the list isn't enough: the names in
it must go too, and so must a name made but not yet appended:

```zig
errdefer field.deinit(gpa);
errdefer for (field.items) |rider| gpa.free(rider.full_name); // runs first

const owned_name = try gpa.dupe(u8, full_name);
errdefer gpa.free(owned_name); // the append below can fail, before the name is in the list
try field.append(gpa, .{ ..., .full_name = owned_name });
```

Leave out that last `errdefer` and `checkAllAllocationFailures` finds it: the run where `append` fails leaks the
name.

::: tip Try it
Make a list of `u32`, append 1 to 20, and print `items.len` and `capacity` after each append. When does the
capacity jump? Then remove every even number with `orderedRemove`, going backwards (why backwards?).
:::

## Arrays, slices or a list

| You have | Use | Because |
|---|---|---|
| a number of items fixed while compiling | an array `[N]T` | no allocator, can't grow |
| a view of items someone else owns | a slice `[]T` | no copying, no ownership |
| items whose number you learn while running | `std.ArrayList(T)` | grows as you append |
| a list a function builds and returns | an ArrayList inside, `toOwnedSlice` out | the caller gets a plain slice |

## In the game

The field and the course grow as they're read, and the race takes a field of any size. The race no longer has
eight riders of its own: it holds a slice of the caller's.

<<< @/code/steps/19-arraylist/src/main.zig#race

`fromField` just borrows the field (any size, at least one rider):

<<< @/code/steps/19-arraylist/src/main.zig#from-field

`init`, which the tests use, fills a field the caller provides (each test now declares
`var field: [8]Rider = undefined;` and passes `&field`):

<<< @/code/steps/19-arraylist/src/main.zig#init

`step` can't keep "where everyone was" in an `[8]f64` any more, so each rider remembers its own:

<<< @/code/steps/19-arraylist/src/main.zig#last-m

<<< @/code/steps/19-arraylist/src/main.zig#step

The loader, with no counting pass:

<<< @/code/steps/19-arraylist/src/main.zig#load

The course parser, with no fixed buffer and no `TooManySegments` (its tests lose their buffers and that error's
test; `ParseError` gains `OutOfMemory`):

<<< @/code/steps/19-arraylist/src/main.zig#parse

In `main`, the course's segments are now allocated, so freed:

<<< @/code/steps/19-arraylist/src/main.zig#main

New tests, at the end of the file:

<<< @/code/steps/19-arraylist/src/main.zig#tests

Run it (or copy `code/steps/19-arraylist`). The race is the one you know, with H (Heap) winning:

```sh
zig build run
```

```text
H crosses the line in 21:43
winner: H (Heap)
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/19-arraylist/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/19-arraylist.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/memory/19-lists-that-grow) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
