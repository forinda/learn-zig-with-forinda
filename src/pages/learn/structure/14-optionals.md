---
title: "Optionals"
description: "Check your understanding of ?T, null, if captures, orelse, .? and optional pointers."
group: "Structure"
order: 5
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 14-optionals
competency: "I can handle missing values with optionals and failures with errors"
---

# Optionals

**Read first:** [Optionals](/guide/structure/14-optionals) in the Guide. This lesson checks you understood it.

## Recall

::: quiz Which of these can be null?
- [ ] u8
- [ ] *Rider
- [x] ?*Rider
- [ ] []const u8

Only types with `?` can be null. A `*Rider` always points at a rider.
:::

::: quiz winner is null and the code says winner.?. What happens?
- [ ] It gives 0
- [ ] It doesn't compile
- [x] The program panics: attempt to use null value
- [ ] It gives '?'

`.?` means "I'm sure there's a value". When there isn't, that's a bug, and the program stops.
:::

## Predict

```zig
const winners = [_]?u8{ null, 'B', null };
for (winners) |w| {
    if (w) |name| std.debug.print("{c}", .{name}) else std.debug.print("-", .{});
}
std.debug.print(" {c}\n", .{winners[0] orelse winners[1].?});
```

::: quiz What does it print?
- [ ] B B
- [x] -B- B
- [ ] -B- -
- [ ] It panics on winners[0]

The loop prints `-` for each `null`. `winners[0]` is null, so `orelse` takes `winners[1].?`, which is `B`.
:::

## Fix it

Total gap to the riders ahead; `null` means "no rider ahead in that slot":

```zig
const gaps_m = [_]?f64{ 12.5, null, 3 };
var total_m: f64 = 0;
for (gaps_m) |gap_m| total_m += gap_m;
```

```text
fix.zig:5:37: error: expected type 'f64', found '?f64'
```

::: quiz What's the fix?
- [x] total_m += gap_m orelse 0;
- [ ] total_m += gap_m.?;
- [ ] Make total_m a ?f64
- [ ] total_m += @as(f64, gap_m);

`null` is an honest "nothing here", which adds nothing: `orelse 0` (total 15.5). `.?` builds but panics on the
`null`; a `?f64` total can't be added to either; `@as` can't unwrap.
:::

## Build it

### Exercise

Add `fn lastFinisher(self: *const Race) ?u8` to `Race`: the letter of the rider furthest *behind* among those
who've finished, or `null` if nobody has. Tests first, on an 18 m course with speeds `&.{ 10, 8 }` (the other six
riders get the default 10 m/s): `null` before any step; `'A'` after two steps (everyone at 10 m/s has finished,
level at 20 m, and the lowest index wins a tie); `'B'` after a third (B, at 24 m, is the furthest behind).

Hint: a `var last: ?usize = null;` for the index, and a loop that keeps a finished rider when `last == null` or it's
behind `self.riders[last.?]`.

```sh
zig build test --summary all
```
