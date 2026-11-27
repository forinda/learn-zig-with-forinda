---
title: "Optionals"
description: "?T and null, unwrapping with if, orelse and .?, optional pointers, and why Zig makes you check."
group: "Structure"
order: 5
step: 14-optionals
---

# Optionals

Who won? Until someone crosses the line, nobody. "Find rider Z": there's no rider Z. Lots of questions have "there
isn't one" as an honest answer. Many languages let any value secretly be "nothing" (`null`, `nil`) and crash when
you forget to check. Zig makes "maybe nothing" part of the type, so the compiler knows which values might be
missing, and won't let you use one without checking.

## ?T: a value or null

Put `?` before a type and it can also be `null`:

```zig
var winner: ?u8 = null; // nobody yet
winner = 'H';           // now someone
```

A plain `u8` can't be null:

```text
error: expected type 'u8', found '@TypeOf(null)'
```

So when you see `u8`, it's always a value; when you see `?u8`, you have to check.

## You can't use it without checking

A `?u8` isn't a `u8`. Doing maths with it, or giving it to something that wants a `u8`, won't build:

```text
error: invalid operands to binary expression: 'optional' and 'comptime_int'
```

```text
error: expected type 'u8', found '?u8'
note: cannot convert optional to payload type
note: consider using '.?', 'orelse', or 'if'
```

The compiler even lists the three ways to unwrap one.

## if with a capture: when there is one

```zig
if (winner) |w| {
    std.debug.print("winner: {c}\n", .{w});
} else {
    std.debug.print("nobody yet\n", .{});
}
```

Inside the first block, `w` is a plain `u8`: the check has been done. Capture a pointer, `|*w|`, to change the value
inside the optional: `if (gap) |*g| g.* += 1;`.

`while` unwraps the same way: `while (it.next()) |word|` (from [Loops](/guide/basics/06-loops)) runs until `next`
returns `null`.

## orelse: a value to use instead

```zig
std.debug.print("winner: {c}\n", .{winner orelse '?'});
```

`a orelse b` is `a`'s value if there is one, otherwise `b`. The right side can also leave: `orelse return`,
`orelse continue`, `orelse return error.NotFound` (errors are the [next page](/guide/structure/15-errors)).

## .?: "I know it's there"

`winner.?` unwraps it, and if it's `null` the program stops:

```text
thread 683641 panic: attempt to use null value
```

Use it only when `null` would be a bug: "if this is null, I made a mistake". For anything that can honestly be
missing, `if` or `orelse`.

| You want | Write |
|---|---|
| do something only if there's a value | `if (x) \|v\| { ... }` |
| a value either way | `x orelse default` |
| leave the function when there isn't one | `x orelse return ...` |
| a value you're sure is there | `x.?` (panics if not) |
| to ask | `x == null`, `x != null` |

## Optional pointers: ?*T

"Find the rider called A" might find nobody. When it finds someone, the caller may want to change that rider, so
return a pointer, which might be missing:

```zig
fn riderNamed(self: *Race, name: u8) ?*Rider {
    for (&self.riders) |*rider| {
        if (rider.name == name) return rider;
    }
    return null;
}
```

```zig
if (race.riderNamed('A')) |you| you.position_m += 10; // a nudge for the player
```

A plain `*Rider` always points at a rider; only `?*Rider` can be null. Zig pointers can't be null by accident.

::: tip Try it
Write `fn firstOver(speeds: []const f64, limit: f64) ?usize` returning the index of the first speed over `limit`.
Print `firstOver(&.{ 9.8, 10.4 }, 10) orelse 99` and the same with a limit of 20.
:::

## Optionals or a special value

Before optionals, people used special values: −1 for "no index", 0 for "no rider", an empty string for "no name".

| | A special value (−1, 0, "") | An optional |
|---|---|---|
| does the type say it might be missing? | no | yes, `?T` |
| forget to check | the special value is used as a real one, silently | won't build |
| when every value is a real one | no special value is left | `null` is always separate |

A rider at position 0 is a real rider at the start, so 0 can't mean "no position". `null` never clashes.

## In the game

`Race` gets a winner, `null` until someone finishes, in its fields:

<<< @/code/steps/14-optionals/src/main.zig#winner

In `step`, where a finisher is reported, the first one becomes the winner:

<<< @/code/steps/14-optionals/src/main.zig#step-winner

A way to find a rider by letter, below `done`:

<<< @/code/steps/14-optionals/src/main.zig#named

After the race, `main` prints the winner and how far you (rider A) were from the line:

<<< @/code/steps/14-optionals/src/main.zig#main

The tests, at the end of the file. The last one leaves the test with an error if the rider isn't found
(`orelse return error...`), instead of crashing it with `.?`:

<<< @/code/steps/14-optionals/src/main.zig#tests

Run it (or copy `code/steps/14-optionals`):

```sh
zig build run
```

The race as before, then:

```text
H crosses the line in 21:43
winner: H
you (A) were 125 m from the line
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/14-optionals/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/14-optionals.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/structure/14-optionals) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
