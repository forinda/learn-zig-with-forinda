---
title: "Errors"
description: "Error sets and E!T, try, catch with a value or a block, if/else with an error capture, mapping library errors to your own, expectError, an unhandled error at runtime, multiline strings and tokenizing text."
group: "Structure"
order: 6
step: 15-errors
---

# Errors

The course is written into the code as numbers. Courses are a game's content; they should be text that anyone can
write, and later load from a file. But text can be wrong: `gravel 100` (no such terrain), `flat` (no length),
`flat far` (not a number). Reading it can **fail**, and the game has to say how. Optionals say "maybe nothing";
**errors** say "this went wrong, and here's what".

## Error sets: the ways it can go wrong

An **error set** names everything that can go wrong:

```zig
const ParseError = error{ UnknownTerrain, MissingNumber, BadNumber, TooManySegments };
```

Each is a value: `error.UnknownTerrain`. They carry no data, only their name, and `@errorName(err)` gives it as
text.

## E!T: a value or an error

A function that can fail returns an **error union**, `E!T`: a `T`, or one of the errors in `E`:

```zig
fn number(word: ?[]const u8) ParseError!f64 {
    const w = word orelse return error.MissingNumber;
    return std.fmt.parseFloat(f64, w) catch error.BadNumber;
}
```

`return error.MissingNumber` fails; `return 4000` succeeds. Returning an error that isn't in the set won't build:

```text
error: expected type 'error{BadNumber,MissingNumber}!u32', found 'error{UnknownTerrain}'
note: 'error.UnknownTerrain' not a member of destination error set
```

`!T` without a set (`pub fn main() !void`) lets Zig work out the set from what the function can return.

## You must handle it

An error union can't be dropped:

```text
error: error union of type 'error{Bad}!u32' is ignored
note: consider using 'try', 'catch', or 'if'
```

Those are the three ways.

### try: pass it on

```zig
const length_m = try number(words.next());
```

If `number` returns an error, `try` returns that same error from *this* function at once; otherwise it gives the
value. The function using `try` must be able to return errors: in `pub fn main() void`, `try` won't build
(`note: function cannot return an error`).

### catch: handle it here

With a value to use instead:

```zig
const length_m = segmentLength(line) catch 0;
```

With a block, capturing the error:

```zig
const length_m = segmentLength(line) catch |err| blk: {
    std.debug.print("bad line: {s}\n", .{@errorName(err)});
    break :blk 0;
};
```

```text
bad line: BadNumber
```

### if with else |err|: both cases, side by side

```zig
if (segmentLength(line)) |length_m| {
    std.debug.print("{d}\n", .{length_m});
} else |err| switch (err) {
    error.MissingNumber => std.debug.print("missing\n", .{}),
    error.BadNumber => std.debug.print("not a number\n", .{}),
}
```

A `switch` on an error must handle every error in the set, like an enum: `note: unhandled error value:
'error.TooManySegments'`.

| You want | Write |
|---|---|
| the caller to deal with it | `try f()` |
| a fallback value | `f() catch default` |
| to report it and carry on | `f() catch \|err\| { ... }` |
| different handling per error | `if (f()) \|v\| ... else \|err\| switch (err) { ... }` |
| to turn it into your own error | `f() catch error.Mine` |

## Your errors, not the library's

`std.fmt.parseFloat` fails with its own error (`InvalidCharacter` for `"far"`). The course reader turns it into
its own, `BadNumber`: `catch error.BadNumber`. Callers of `parseCourse` then see one error set that speaks the
language of courses, not of number parsing, and its tests can check exactly which one.

## When nobody handles it

If `main` returns an error, the program stops and prints it, with an **error return trace**: every `try` the error
came through, from where it started to `main`:

```text
error: MissingNumber
trace.zig:6:27: in number (trace.zig)
    const w = word orelse return error.MissingNumber;
                          ^
trace.zig:13:12: in segmentLength (trace.zig)
    return try number(words.next());
           ^
trace.zig:31:9: in main (trace.zig)
    _ = try segmentLength("flat");
        ^
```

(Shortened: the real one starts each line with the full path and an address.) Read it top-down: where the error
was made, then each `try` that passed it on.

## Testing errors: expectError

Each way the text can be wrong deserves a test that it's caught, with the right error:

```zig
test "an unknown terrain is an error" {
    var buf: [8]Segment = undefined;
    try std.testing.expectError(error.UnknownTerrain, parseCourse("x", "gravel 100", &buf));
}
```

`expectError` fails if the call succeeds, or fails with a different error.

## Errors or optionals

| | An optional `?T` | An error union `E!T` |
|---|---|---|
| means | there may be no value, and that's normal | something went wrong |
| says why | no | yes, which error |
| ignoring it | won't build | won't build |
| passing it on | `orelse return null` | `try` |

"No rider called Z" is an optional; "this course text is broken" is an error.

## Reading text: multiline strings and tokenizing

A **multiline string** starts each line with `\\`; the lines are joined with newlines (no newline after the last):

```zig
const compile_pass_text =
    \\flat 4000
    \\climb 2000 6
;
```

`std.mem.tokenizeScalar(u8, text, '\n')` hands out the lines one at a time (skipping empty ones), and the same with
`' '` splits a line into words. `next()` returns `null` when there are no more: an optional, unwrapped by `while`,
`orelse` or `if`.

::: tip Try it
Change `main` in step 15 to parse `"flat 4000\nclimb 2000"` and run it: read the error return trace. Then catch the
error in `main` instead and print a friendly message.
:::

## In the game

Compile Pass becomes text, below the race constants:

<<< @/code/steps/15-errors/src/main.zig#text

The reader: an error set, `parseCourse` and its helper `number`, below `Course`:

<<< @/code/steps/15-errors/src/main.zig#parse

In `main`, the course comes from the text, with `try`:

<<< @/code/steps/15-errors/src/main.zig#main

One test for the course that works and one for each way it can be wrong, at the end of the file:

<<< @/code/steps/15-errors/src/main.zig#tests

Run it (or copy `code/steps/15-errors`). The race is the same as before; only where the course comes from changed:

```sh
zig build run
```

```text
H crosses the line in 21:43
winner: H
you (A) were 125 m from the line
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/15-errors/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/15-errors.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/structure/15-errors) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
