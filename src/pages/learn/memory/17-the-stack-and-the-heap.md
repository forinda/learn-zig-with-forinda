---
title: "The stack and the heap"
description: "Check your understanding of the stack, allocators, ownership and the leak report."
group: "Memory"
order: 2
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 17-allocators
competency: "I can choose between the stack and an allocator"
---

# The stack and the heap

**Read first:** [The stack and the heap](/guide/memory/17-the-stack-and-the-heap) in the Guide. This lesson checks
you understood it.

## Recall

::: quiz askLineAlloc returns a name allocated from gpa. Who frees it?
- [ ] askLineAlloc, before it returns
- [x] The caller, with gpa.free
- [ ] Nobody: Zig frees it when it's no longer used
- [ ] The allocator, when the program ends

A function that returns allocated memory hands it to its caller. Zig has no garbage collector: if the caller
doesn't free it, the leak report at exit will list it.
:::

::: quiz You need a rider's position for one loop inside one function. Where should it live?
- [x] A local variable (the stack)
- [ ] gpa.create(f64)
- [ ] A FixedBufferAllocator
- [ ] A global variable

Its size is known and it's not needed after the function returns: a local. Asking an allocator for it would be
slower and need a free.
:::

## Predict

```zig
var memory: [8]u8 = undefined;
var fba: std.heap.FixedBufferAllocator = .init(&memory);
const gpa = fba.allocator();
const a = try gpa.dupe(u8, "Heap");
const b = gpa.dupe(u8, "Buffer") catch "none";
std.debug.print("{s} {s}\n", .{ a, b });
```

::: quiz What does it print?
- [ ] Heap Buffer
- [x] Heap none
- [ ] none none
- [ ] It panics: out of memory

"Heap" takes 4 of the 8 bytes; "Buffer" needs 6 and only 4 are left, so `dupe` returns `error.OutOfMemory`, and
`catch` gives `"none"`.
:::

## Fix it

```zig
fn riderLabel(letter: u8) []const u8 {
    var buf: [2]u8 = .{ letter, ':' };
    return &buf;
}
```

```text
error: returning address of expired local variable 'buf'
```

::: quiz What's the fix?
- [x] Take an allocator and return gpa.dupe(u8, &buf); the caller frees
- [ ] Make buf a const
- [ ] Return buf[0..] instead of &buf
- [ ] Add defer before the return

`buf` lives in `riderLabel`'s stack frame, gone when it returns. `buf[0..]` is worse than the error: it compiles,
and still points into the gone frame (the compiler only catches the plain `&buf`). The label must come from
memory that outlives the call: the caller's, or an allocator's.
:::

## Build it

### Exercise

A name of any length is a door left open: someone can paste a megabyte. Limit `askLineAlloc` to 1 KiB: swap
`streamDelimiterEnding` for `in.streamDelimiterLimit(&line.writer, '\n', .limited(1024))`, which returns
`error.StreamTooLong` past the limit. Test first: `test "a name over 1 KiB is too long"`, with an 1100-byte line
built with `@splat` and `expectError`. In `main`, a too-long name becomes `Player`, with a note on stderr.

```sh
zig build test --summary all
```
