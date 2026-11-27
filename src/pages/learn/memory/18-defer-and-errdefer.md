---
title: "defer and errdefer"
description: "Check your understanding of defer, errdefer, their order, and cleaning up a half-built structure."
group: "Memory"
order: 3
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 18-defer-errdefer
competency: "I can free what I allocate with defer and errdefer"
---

# defer and errdefer

**Read first:** [defer and errdefer](/guide/memory/18-defer-and-errdefer) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz loadField returns the field it allocated. Which cleanup goes after the allocation?
- [ ] defer gpa.free(field);
- [x] errdefer gpa.free(field);
- [ ] Nothing: the caller frees it
- [ ] gpa.free(field); just before the return

On success the caller owns the field, so `defer` would free it under the caller. On failure the caller gets
nothing, so `errdefer` frees it. "Nothing" leaks whenever a later line fails.
:::

::: quiz Two errdefers: first one frees the field, then one frees the names inside it. On an error, which runs first?
- [ ] The field's, because it was written first
- [x] The names', because the last one written runs first
- [ ] Both at once
- [ ] Neither: errdefer only runs on success

Last in, first out: names first, then the field that held them.
:::

## Predict

```zig
fn f() void {
    defer std.debug.print("a", .{});
    for (0..2) |i| {
        defer std.debug.print("{d}", .{i});
    }
    defer std.debug.print("b", .{});
}
```

::: quiz What does calling f() print?
- [ ] ab01
- [x] 01ba
- [ ] 10ba
- [ ] a01b

The loop's defer runs at the end of each round: `0`, `1`. When `f` ends, its two defers run last-first: `b`, then
`a`.
:::

## Fix it

```zig
fn copyName(gpa: std.mem.Allocator, name: []const u8) ![]u8 {
    const copy = try gpa.dupe(u8, name);
    defer gpa.free(copy);
    return copy;
}

test "the copy is the name" {
    const name = try copyName(std.testing.allocator, "Heap");
    defer std.testing.allocator.free(name);
    try std.testing.expectEqualStrings("Heap", name);
}
```

```text
====== expected this output: =========
Heap␃

======== instead found this: =========
UUUU␃
```

::: quiz What should replace defer gpa.free(copy);?
- [x] errdefer gpa.free(copy);
- [ ] gpa.free(copy);
- [ ] defer gpa.free(name);
- [ ] defer std.testing.allocator.free(copy);

`defer` frees the copy as `copyName` returns, so the test reads freed memory (the allocator fills it with `U`s to
make that visible). `errdefer` frees it only if something after it fails. Freeing it just before the return is
the same bug, and `name` isn't `copyName`'s to free.
:::

## Build it

### Exercise

Give each rider a team: the roster line ends `Errdefer / Team Allocator`, and the rider gets a `team: []const u8`
field. Split the rest of the line at `" / "` (`std.mem.indexOf` finds it), `dupe` both parts, and free both in
`freeField` and on the error path. Tests first: a rider's team is loaded; a line with a name but no team is
`error.MissingTeam`; and `checkAllAllocationFailures` still passes (it will catch a missing `errdefer` for the
team).

```sh
zig build test --summary all
```
