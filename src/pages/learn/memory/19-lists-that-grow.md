---
title: "Lists that grow"
description: "Check your understanding of ArrayList: append, capacity, removing, toOwnedSlice and stale pointers."
group: "Memory"
order: 4
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 19-arraylist
competency: "I can free what I allocate with defer and errdefer"
---

# Lists that grow

**Read first:** [Lists that grow](/guide/memory/19-lists-that-grow) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz Why does append take the allocator, and need try?
- [ ] The list forgets its allocator after each call
- [x] It may need a bigger block of memory, which can fail
- [ ] Every function in std takes an allocator
- [ ] To free the old item

An append past the capacity asks for more memory. Calls that can allocate take the allocator, and can return
`error.OutOfMemory`.
:::

::: quiz You keep const first = &list.items[0], then append 1000 items. What is first now?
- [ ] Still the first item: pointers follow the list
- [ ] null
- [x] Possibly a pointer into freed memory: the list may have moved
- [ ] A compile error

Growing can move the items to a new block and free the old one. A pointer into a list is good only until it next
changes size.
:::

## Predict

```zig
var laps: std.ArrayList(u32) = .empty;
defer laps.deinit(gpa);
try laps.appendSlice(gpa, &.{ 10, 20, 30, 40 });
_ = laps.swapRemove(0);
_ = laps.orderedRemove(1);
std.debug.print("{any}\n", .{laps.items});
```

::: quiz What does it print?
- [ ] { 20, 30 }
- [ ] { 30, 40 }
- [x] { 40, 30 }
- [ ] { 40, 20 }

`swapRemove(0)` moves the last item (40) into place 0: `{ 40, 20, 30 }`. `orderedRemove(1)` removes 20 and
shifts the rest down: `{ 40, 30 }`.
:::

## Fix it

```zig
fn evens(gpa: std.mem.Allocator, upto: u32) ![]u32 {
    var list: std.ArrayList(u32) = .empty;
    defer list.deinit(gpa);
    var n: u32 = 0;
    while (n <= upto) : (n += 2) try list.append(gpa, n);
    return list.items;
}
```

A test expecting `{ 0, 2, 4, 6 }` from `evens(std.testing.allocator, 6)`:

```text
slices differ. first difference occurs at index 0 (0x0)
...
============= instead found this: ==============  len: 4 (0x4)

[0]: 1431655765
```

::: quiz What's the fix?
- [x] errdefer list.deinit(gpa); and return list.toOwnedSlice(gpa);
- [ ] Keep the defer, return list.items[0..]
- [ ] Remove the defer, return list.items
- [ ] Keep the defer, return &list

`list.items` points into the list's memory, which the `defer` frees on return. `toOwnedSlice` hands that memory
to the caller (who frees it), with an `errdefer` for when an append fails. Returning `items` without the defer
gives the caller a slice whose length doesn't match the allocation, so freeing it panics.
:::

## Build it

### Exercise

Add `fn dropRider(self: *Race, name: u8) bool` to `Race`: remove the rider with that letter from the race (a
rider who abandons), keeping the others in order, and return whether it found one. The field is a slice, not a
list, so shift the riders after it down and shrink `self.riders` by one (`self.riders = self.riders[0 .. len - 1]`).
Tests first: dropping 'B' from four riders leaves A, C, D; dropping 'Z' returns `false` and changes nothing.

Then think about it: why does `Race` hold a slice and not an `ArrayList`? (Who would own the memory?)

```sh
zig build test --summary all
```
