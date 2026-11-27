---
title: "The stack and the heap"
description: "Where values live and for how long: locals on the stack, memory from an allocator, alloc and free, create and destroy, dupe, who owns what, and the leak report."
group: "Memory"
order: 2
step: 17-allocators
---

# The stack and the heap

The game reads answers into a 64-byte buffer. That's fine for "e". It isn't fine for a name: nobody can say how
long a name is, and a buffer big enough for any of them is a buffer too big for all of them. Until now every value
in the game had a size Zig knew while compiling. A name of any length needs memory that's asked for *while
running*, as much as it takes. That memory has to be given back, and in Zig you do that yourself.

## The stack: memory that comes and goes with a function

Every local variable lives in its function's **stack frame**: memory set aside when the function is called and
taken back the moment it returns. It's fast and needs no cleaning up, but its size is fixed when you compile, and
it doesn't outlive the call.

Return a pointer to a local, and Zig stops you:

```zig
fn bad() []const u8 {
    var buf: [4]u8 = .{ 'H', 'e', 'a', 'p' };
    return &buf;
}
```

```text
error: returning address of expired local variable 'buf'
```

It can't catch every case. Here the slice comes back through `bufPrint`, and the compiler can't see it points into
`buf`:

```zig
fn greeting(name: []const u8) []const u8 {
    var buf: [32]u8 = undefined;
    return std.fmt.bufPrint(&buf, "Good luck, {s}!", .{name}) catch "Good luck!";
}
```

Printing two greetings gives garbage, not "Good luck, Ada!": by then that stack memory belongs to other calls.

```text
���������������
```

A slice is a view; it never keeps memory alive. Whoever has the memory decides how long the view is good.

## The heap: memory you ask for

Memory that has to outlive a function, or whose size you only learn while running, comes from an **allocator**:
you ask for some, use it as long as you need, and give it back. That pool of memory is the **heap**. In Zig an
allocator is a value of type `std.mem.Allocator`, and you pass it to whatever needs memory.

| Ask with | You get | Give back with |
|---|---|---|
| `gpa.alloc(f64, n)` | a slice of `n` items (contents undefined) | `gpa.free(slice)` |
| `gpa.create(Rider)` | a pointer to one item | `gpa.destroy(ptr)` |
| `gpa.dupe(u8, text)` | a copy of a slice | `gpa.free(copy)` |

```zig
const rider = try gpa.create(Rider);
defer gpa.destroy(rider);
rider.* = .{ .name = 'H', .speed_mps = 10.3 };

const speeds = try gpa.alloc(f64, 3);
defer gpa.free(speeds);
@memset(speeds, 10);
```

Asking can fail (`error.OutOfMemory`), so each ask needs `try`. `defer` right after the ask makes sure it's given
back when the function ends (the [next page](/guide/memory/18-defer-and-errdefer) is all about it).

### Where the allocator comes from

`main` is handed one: `init.gpa`, a **general-purpose allocator**. In a debug build it checks your work: give
back the wrong thing and the program stops,

```text
thread 830263 panic: free of [addr: 7ee6225bd610, len: 4 (0x4) align: 1] mismatches allocation of [addr: 7ee6225bd610, len: 5 (0x5) align: 1]
```

```text
thread 830344 panic: double free of [addr: 7be3c4fd7610, len: 4 (0x4) align: 1]
```

and forget to give something back, and when the program ends it says what, and where it was allocated:

```text
error(SafeAllocator): leaked [addr: 7718c2f0b610, len: 3 (0x3) align: 1] allocated at:
.../std/mem/Allocator.zig:481:40: in dupe
```

Free exactly the slice you were given (the whole of it, once).

### An allocator over a fixed buffer

Allocators are interchangeable: code that takes a `std.mem.Allocator` doesn't care where the memory comes from. A
`FixedBufferAllocator` hands out pieces of an array you give it, and fails when it runs out:

```zig
var memory: [16]u8 = undefined;
var fba: std.heap.FixedBufferAllocator = .init(&memory);
const a = try fba.allocator().dupe(u8, "Compile Pass"); // 12 bytes: fits
const b = fba.allocator().dupe(u8, "Linker Loop");     // 11 more: error.OutOfMemory
```

That's why functions take an allocator as a parameter instead of picking one: the caller decides. Tests pass
`std.testing.allocator`, which fails the test on a leak ([Finding leaks](/guide/memory/21-finding-leaks)).

## Who owns it

Every allocation has an **owner**: the code responsible for freeing it. Zig doesn't track this for you; the
convention is to say it in the function's doc comment and its shape:

- A function that **returns** allocated memory hands ownership to the caller: "the caller frees" (`dupe`,
  `askLineAlloc` below).
- A function that **takes** an allocator and gives nothing back frees what it used before returning.
- A struct that holds allocated memory has a `deinit` (or a `free...` function) that frees it.

Get it wrong one way and memory leaks; the other way, it's freed twice or used after it's gone.

::: tip Try it
Write `fn shout(gpa: std.mem.Allocator, text: []const u8) ![]u8` returning an upper-case copy
(`std.ascii.upperString(copy, text)` writes into a slice you give it). Call it in `main` with `init.gpa`, print
the result, and leave out the free: read the leak report. Then add `defer gpa.free(...)`.
:::

## Which memory when

| You have | Use | Because |
|---|---|---|
| a value of a size known while compiling, needed only in this function | a local (the stack) | free, fast, gone at return |
| a size known while compiling, but the data must be filled while running | a fixed array (a buffer) | no allocator, a hard limit |
| a size only known while running (a name, a file) | an allocator: `alloc`, `dupe` | as big as it needs |
| something that must outlive the function that makes it | an allocator, and the caller frees | the stack frame won't last |
| a known upper limit and no heap wanted | `FixedBufferAllocator` over an array | allocator code, fixed memory |

What goes wrong with the wrong one: a fixed buffer too small rejects real input (`StreamTooLong`); a pointer
into a stack frame that's gone reads garbage; heap memory nobody frees leaks, a little more every time.

## In the game

The game asks for the player's name, any length. `askLineAlloc` collects the line in a
`std.Io.Writer.Allocating`, a writer whose buffer grows from an allocator, and returns a copy the caller owns.
Below `askLine`:

<<< @/code/steps/17-allocators/src/main.zig#ask-alloc

`streamDelimiterEnding` copies everything up to the newline into the growing writer and leaves the newline in the
reader (`toss(1)` drops it). If the reader is empty afterwards, the input ended.

In `main`, after the race card, the question, and the free that goes with it:

<<< @/code/steps/17-allocators/src/main.zig#name

`defer if (typed_name) |n| gpa.free(n);` frees the name only if there is one: `null` allocated nothing. After the
rider question, a greeting with positional arguments:

<<< @/code/steps/17-allocators/src/main.zig#greet

The tests use `std.testing.allocator`, so a test that forgets a free fails. At the end of the file:

<<< @/code/steps/17-allocators/src/main.zig#tests

Run it (or copy `code/steps/17-allocators`):

```sh
zig build run
```

```text
Your name? Ada Lovelace
Which rider are you (A-H)? h
Good luck, Ada Lovelace! Ada Lovelace rides as H today.
...
winner: H
you (H) crossed the line!
```

No leak report at the end: the name was freed. With no input, the name is `Player`:

```text
Good luck, Player! Player rides as A today.
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/17-allocators/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/17-allocators.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/memory/17-the-stack-and-the-heap) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
