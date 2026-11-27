---
title: "Tagged unions"
description: "Check your understanding of union(enum), switch with captures and returning a slice of a buffer."
group: "Structure"
order: 4
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 13-tagged-unions
competency: "I can model the game with structs, enums and tagged unions"
---

# Tagged unions

**Read first:** [Tagged unions](/guide/structure/13-tagged-unions) in the Guide. This lesson checks you understood
it.

## Recall

::: quiz How many of an Event's fields hold data at once?
- [ ] All of them, like a struct
- [x] Exactly one: the kind it is
- [ ] Any number, as long as they're the same type
- [ ] None until it's switched on

A union holds one field at a time; the tag says which. Setting two is a compile error.
:::

::: quiz step returns events[0..n]. What happens to that slice on the next step?
- [ ] Nothing: it's a copy
- [ ] It's freed
- [x] The next step writes into the same buffer, so the old events are overwritten
- [ ] It can't be used: the slice belongs to step

The slice is a view of the caller's array. Use the events before stepping again.
:::

## Predict

```zig
const events = [_]Event{ .{ .new_leader = 'H' }, .{ .km = 5 }, .{ .finished = 'H' } };
var count: u32 = 0;
for (events) |event| switch (event) {
    .km => |km| count += km,
    .new_leader, .finished => count += 1,
};
std.debug.print("{d}\n", .{count});
```

::: quiz What does it print?
- [ ] 3
- [ ] 5
- [x] 7
- [ ] 149

The km event adds its data, 5; the other two add 1 each. (149 would be adding the letter 'H', 72, twice plus 5.)
:::

## Fix it

```zig
switch (event) {
    .km => |km| std.debug.print("km {d}\n", .{km}),
    .new_leader => |name| std.debug.print("{c} leads\n", .{name}),
}
```

```text
fix.zig:5:5: error: switch must handle all possibilities
fix.zig:2:54: note: unhandled enumeration value: 'finished'
```

::: quiz What's the fix?
- [x] Add .finished => |name| std.debug.print("{c} finishes\n", .{name}),
- [ ] Add else => {},
- [ ] Remove finished from Event
- [ ] Print event.finished after the switch

`else => {}` builds but silently drops every finisher, and every kind added later. Removing `finished` loses the
finish. Reading `event.finished` when the event is a `km` panics.
:::

## Build it

### Exercise

Add a kind `half_way: u8` to `Event`: the rider who leads at the moment the leader passes half the course's
distance, reported once. Test first, `test "half way is reported once"`, on a 100 m course with one rider at
10 m/s: no `half_way` after 4 steps, one on the 5th, none on the 6th. Then add the kind (the compiler shows you the
`switch` in `main`), a `half_way_done: bool = false` field on `Race`, and the check in `step`.

```sh
zig build test --summary all
```
