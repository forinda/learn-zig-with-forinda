---
title: "Tagged unions"
description: "One value of several kinds, each with its own data: union(enum), switch with captures, why not a struct of optional fields, and returning a slice of the caller's buffer."
group: "Structure"
order: 4
step: 13-tagged-unions
---

# Tagged unions

The race now has a story (B leads, H takes over on the climb, E crests first, H wins it back), but the loop in
`main` only prints the leader at each kilometre; the moment someone takes the lead goes by unseen. The race should
*tell* `main` what happened: a kilometre passed, a new leader, someone finished. Those are different kinds of thing,
each with its own data (a number; a rider; a rider). One type that is exactly one of several kinds, each with its
data, is a **tagged union**.

## union(enum): one of several kinds

```zig
const Event = union(enum) {
    km: u32,         // the leader passed this kilometre marker
    new_leader: u8,  // this rider took the lead
    finished: u8,    // this rider crossed the line
};
```

It looks like a struct, but a struct has *all* its fields at once, and a union has exactly *one*. The `enum` part
is the **tag**: Zig keeps track of which field is the live one.

```zig
const e: Event = .{ .km = 5 };
const f: Event = .{ .finished = 'H' };
```

Setting two at once won't build:

```text
error: cannot initialize multiple union fields at once; unions can only have one active field
```

A kind can carry no data: `crash,` with no type makes `const c: Event = .crash;`.

## Reading one: switch with captures

You don't read a union's field and hope it's the right one: you `switch` on it, and each prong **captures** the
data of its kind:

```zig
switch (event) {
    .km => |km| std.debug.print("km {d}\n", .{km}),
    .new_leader => |name| std.debug.print("{c} takes the lead\n", .{name}),
    .finished => |name| std.debug.print("{c} crosses the line\n", .{name}),
}
```

Like an enum switch, it must cover every kind: add a kind and the compiler finds every `switch` that needs to know.
Prongs with the same data type can share: `.new_leader, .finished => |name| ...`.

### Reading the wrong field

You *can* write `e.km` directly, when you know which kind it is. Get it wrong and Zig catches it: while compiling
when it can tell,

```text
error: access of union field 'finished' while field 'km' is active
```

and while running when it can't:

```text
thread 681200 panic: access of union field 'finished' while field 'km' is active
```

The `switch` is the safe way: inside `.km => |km|`, it can only be a `km`.

### Asking which kind

Compare with an enum value, `event == .km`, or get its name with `@tagName(event)` (`km`). `{any}` prints the
kind and data: `.{ .km = 5 }`.

## Why not a struct?

You could write an event as a struct with a field for each kind and a "what kind" enum:

```zig
const Event = struct {
    kind: enum { km, new_leader, finished },
    km: u32 = 0,
    rider: u8 = 0,
};
```

Nothing stops `.{ .kind = .km, .rider = 'B' }`: a km event with a rider and no km. Every reader has to know which
fields go with which kind, and nothing checks. The union makes wrong events impossible to build, and makes every
reader handle every kind.

| | A struct with a kind field | A tagged union |
|---|---|---|
| wrong combinations | possible | can't be built |
| reading the data | any field, any time | through `switch`, by kind |
| a new kind | nothing tells you who must handle it | every `switch` stops building |

## Returning a slice of the caller's buffer

A step can produce several events (a new leader *and* a kilometre marker), or none. The function can't make an
array of "however many" (that needs memory, Part 4), so the caller gives it room, and it returns the part it filled:

```zig
fn step(self: *Race, events: []Event) []Event {
    var n: usize = 0;
    // ...each time something happens:
    if (n < events.len) {
        events[n] = .{ .new_leader = name };
        n += 1;
    }
    return events[0..n];
}
```

```zig
var events: [16]Event = undefined;
for (race.step(&events)) |event| { ... }
```

The returned slice points into the caller's array: it's valid as long as that array is, and the next `step`
overwrites it. Check `n < events.len` before writing, so a full buffer drops events instead of writing past its
end.

::: tip Try it
Add a `crash` kind with no data to a copy of `Event`, and build: the compiler points at the `switch` in `main`.
Handle it with `.crash => {},`.
:::

## In the game

`Event` arrives below `Race`'s fields:

<<< @/code/steps/13-tagged-unions/src/main.zig#event

`Race.step` remembers who led and where the next marker is (two new fields, `last_leader` and `next_km_m`), and
reports what happened into the caller's buffer:

<<< @/code/steps/13-tagged-unions/src/main.zig#step

`main` prints each event with a `switch`:

<<< @/code/steps/13-tagged-unions/src/main.zig#main

The tests use a helper that asks "is this event in that list?" (`std.meta.eql` compares two unions: same kind, same
data), at the end of the file:

<<< @/code/steps/13-tagged-unions/src/main.zig#tests

Run it (or copy `code/steps/13-tagged-unions`):

```sh
zig build run
```

```text
  B takes the lead
km 1 at 1:37: leader is B
...
km 4 at 6:25: leader is B
  --------------GB----------------------------------
  H takes the lead
km 5 at 9:18: leader is H
  -------------------H------------------------------
  E takes the lead
km 6 at 11:51: leader is E
...
  H takes the lead
km 9 at 16:03: leader is H
...
H crosses the line in 21:43
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/13-tagged-unions/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/13-tagged-unions.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/structure/13-tagged-unions) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
