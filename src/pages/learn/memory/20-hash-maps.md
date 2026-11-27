---
title: "Hash maps"
description: "Check your understanding of hash maps: put, get, getOrPut, owned keys and iteration order."
group: "Memory"
order: 5
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 20-hashmap
competency: "I can free what I allocate with defer and errdefer"
---

# Hash maps

**Read first:** [Hash maps](/guide/memory/20-hash-maps) in the Guide. This lesson checks you understood it.

## Recall

::: quiz The standings map's keys are names from each race's field, and the field is freed after the race. What must recordWin do?
- [ ] Nothing: the map copies keys itself
- [x] Store its own copy of the name (gpa.dupe), and free the copies before deinit
- [ ] Never free the field
- [ ] Use AutoHashMap instead

A `StringHashMap` stores the key slice you give it, not the bytes. When those bytes are freed or reused, the
entry can't be found any more.
:::

::: quiz You print the standings by iterating the map. In what order do they come out?
- [ ] The order they were added
- [ ] Sorted by key
- [ ] Sorted by value
- [x] Whatever the map's layout gives, which can change as it grows

A map has no order of its own. To print a table in order, copy the entries into a list and sort it.
:::

## Predict

```zig
try wins.put(gpa, "Heap", 1);
try wins.put(gpa, "Heap", 5);
_ = wins.remove("Buffer");
std.debug.print("{d} {d} {d}\n", .{ wins.count(), wins.get("Heap") orelse 0, wins.get("Buffer") orelse 0 });
```

::: quiz What does it print (the map starts empty)?
- [ ] 2 6 0
- [ ] 2 5 0
- [x] 1 5 0
- [ ] It panics: Buffer isn't in the map

A second `put` with the same key replaces the value. Removing a key that isn't there returns `false`, no panic.
`get` on a missing key is `null`, so `orelse 0`.
:::

## Fix it

```zig
fn addWin(gpa: std.mem.Allocator, wins: *std.StringHashMapUnmanaged(u32), name: []const u8) !void {
    const entry = try wins.getOrPut(gpa, name);
    entry.value_ptr.* += 1;
}
```

A test that adds one win for "Heap":

```text
expected 1, found 2863311531
```

::: quiz What's the fix?
- [x] if (!entry.found_existing) entry.value_ptr.* = 0; before adding one
- [ ] Use put(gpa, name, 1) every time
- [ ] Use get(name).? + 1
- [ ] Initialize the map with .{} instead of .empty

A new entry's value is undefined until you set it (the debug build fills it with a pattern, `0xAAAAAAAA`, plus
one). `put(..., 1)` would reset every name to one win, and `get(name).?` panics on a new name.
:::

## Build it

### Exercise

Count podiums, not just wins: after each race, the first three riders across the line each get one in a second map,
`podiums`. Collect the finishers in the order they cross (the `finished` events, but a race ends when the leader
crosses, so keep stepping the race until three have finished). Tests first: after one race on Compile Pass,
`podiums` has exactly three names, each with 1, and `Heap` is among them; and the map owns its keys (the same test
as the standings').

```sh
zig build test --summary all
```
