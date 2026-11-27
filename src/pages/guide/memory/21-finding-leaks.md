---
title: "Finding leaks"
description: "Leak reports from the test allocator and the general-purpose allocator and how to read them, arenas that free everything at once, and which allocator to use when."
group: "Memory"
order: 6
step: 21-leaks
---

# Finding leaks

The game now allocates a course, a field and eight names for every race, and frees them one by one. Race twenty
times and that's two hundred allocations, each with a `free` somewhere that has to be right. A leak in a game that
races once is a few bytes. In one that runs all season, or in a server that never stops (Part 12), it's memory
that only goes up. This page is about catching leaks before anyone else does, and about an allocator that makes
a whole class of them impossible.

## Tests find leaks for you

`std.testing.allocator` records every allocation and checks, when the test ends, that each was freed. A test
that leaks fails the run, even if all its `expect`s pass:

```text
+- run test 55 pass (55 total); 2 leaks
error: 'main.test.a whole race leaks nothing, and its winner is in the standings' leaked 2 allocations:
       [SafeAllocator] (err): leaked [addr: 7b1c499f8740, len: 1216 (0x4c0) align: 8] allocated at:
       .../std/mem/Allocator.zig:147:26: in rawAlloc (std.zig)
       .../std/mem/Allocator.zig:481:40: in dupe__func_109 (std.zig)
       .../21-leaks/src/main.zig:314:40: in loadField (main.zig)
               const owned_name = try gpa.dupe(u8, full_name);
       .../21-leaks/src/main.zig:358:32: in playRace (main.zig)
           const field = try loadField(race_gpa, roster_text);
```

(Shortened: the real trace lists every frame with its full path.)

### Reading a leak report

- **`leaked 2 allocations`** in **which test**: the test's name.
- **`len: 1216`**: how big the lost block was.
- **`allocated at:`** then the call stack *at the moment it was allocated*, innermost first. Skip the `std` frames
  at the top; the first line in **your** file is where the memory came from (`loadField`), and the lines below it
  are who called it (`playRace`).

The trace says where memory was *allocated*, not where it should have been freed. The fix is wherever its owner
should have let it go: here, the arena's `deinit` was missing in `playRace`, so the block the arena got for
`loadField`'s first name was never given back.

That's why every test that allocates should use `std.testing.allocator`: a leak in the code fails a test, the day
you write it.

### The program's own report

`init.gpa`, `main`'s allocator, does the same at exit in debug builds:

```text
error(SafeAllocator): leaked [addr: 7718c2f0b610, len: 3 (0x3) align: 1] allocated at:
```

Run the game with input that takes the unusual paths (a too-long answer, no answer, several races) and read
stderr at the end. In release builds (`-Doptimize=fast`) the checks are off and leaks go unreported.

## Arenas: free everything at once

Some memory comes in a batch with one lifetime: everything a race needs lives exactly as long as the race. An
**arena** hands out memory from a growing pool and frees it all in one `deinit`:

```zig
var arena: std.heap.ArenaAllocator = .init(gpa); // gets its memory from gpa
defer arena.deinit();                            // frees everything below, at once
const race_gpa = arena.allocator();

const course = try parseCourse(race_gpa, plan.name, plan.text); // no free needed
const field = try loadField(race_gpa, roster_text);             // nor here
```

`parseCourse` and `loadField` don't change: they take a `std.mem.Allocator`, and an arena is one. Their own
`errdefer`s still run and still work (an arena's `free` is allowed; it just may not give memory back until the
`deinit`).

```zig
for (0..1000) |i| {
    const name = try std.fmt.allocPrint(a, "rider {d}", .{i}); // never freed one by one
    _ = name;
}
```

```text
17310 bytes held
```

A thousand allocations, one `deinit`. `arena.reset(.retain_capacity)` empties it but keeps the memory for the next
batch (the next race), so it doesn't have to be asked for again.

What an arena can't do: give back *some* of its memory early. Memory that must outlive the batch (the standings,
across races) can't come from it.

`std.process.Init` has one for the whole program too: `init.arena`, freed when `main` returns. It's handy for things
made once and kept until exit.

::: tip Try it
In step 21, comment out `defer arena.deinit();` in `playRace` and run `zig build test`. Find the first line of the
trace in `main.zig`. Then run the game with two races and read the report at exit.
:::

## Which allocator when

| You're allocating | Use | Because |
|---|---|---|
| anything in a test | `std.testing.allocator` | leaks fail the test |
| long-lived things freed one by one (the standings) | `init.gpa` | general purpose, leak-checked in debug |
| a batch with one lifetime (a race, a request, a frame) | an `ArenaAllocator` over `gpa` | one `deinit`, no per-item frees |
| things kept until the program ends | `init.arena` | freed at exit for you |
| a known maximum, no heap at all | `FixedBufferAllocator` over an array | fails cleanly when it's full |

What goes wrong with the wrong one: an arena for long-lived things grows forever, because nothing in it is freed
until the end; `gpa` for a batch means a `free` for every item, and each one can be forgotten.

## In the game

Each race's memory comes from its own arena, and the race moves into a function, `playRace`, so a test can run a
whole race under the testing allocator. The course to race, below the courses:

<<< @/code/steps/21-leaks/src/main.zig#plan

and `playRace`, everything one race needs, above the standings:

<<< @/code/steps/21-leaks/src/main.zig#play

The loop in `main` calls it; the standings stay on `gpa`, because they outlive every race:

<<< @/code/steps/21-leaks/src/main.zig#loop

The test runs two whole races, one on each course, and fails if a single byte is left over:

<<< @/code/steps/21-leaks/src/main.zig#tests

Run it (or copy `code/steps/21-leaks`). The races are the same as before; what changed is that each race's memory
goes in one go:

```sh
zig build test --summary all
```

```text
Build Summary: 3/3 steps succeeded; 55/55 tests passed
```

```sh
zig build run
```

```text
race 1: Compile Pass
...
winner: H (Heap)
standings:
  1  Heap
Race again? (y/n)
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/21-leaks/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/21-leaks.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/memory/21-finding-leaks) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
