---
title: "Talking to the terminal"
description: "Check your understanding of stdin, stdout and stderr, reading a line, and positional and named arguments."
group: "Memory"
order: 1
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 16-terminal-io
competency: "I can read what the player types and write to stdout and stderr"
---

# Talking to the terminal

**Read first:** [Talking to the terminal](/guide/memory/16-talking-to-the-terminal) in the Guide. This lesson checks
you understood it.

## Recall

::: quiz The player runs ./tour > race.txt. Where should "note: that answer is too long" go?
- [ ] stdout, so it's saved with the race
- [x] stderr, so it stays on screen and race.txt holds only the race
- [ ] stdin
- [ ] Nowhere: notes aren't needed

`>` redirects stdout only. A note on stderr is still seen, and doesn't get mixed into the race in the file.
:::

::: quiz takeDelimiter('\n') returns null. What happened?
- [ ] The player pressed Enter without typing anything
- [x] The input ended: there's nothing more to read
- [ ] The line was too long for the buffer
- [ ] Reading failed

An empty line is `""`, not `null`. A line too long is `error.StreamTooLong`. `null` means the input has ended:
Ctrl+D, the end of a file, or no input at all.
:::

## Predict

```zig
std.debug.print("{1d}-{0d}-{1d} {{ok}}\n", .{ 4, 7 });
```

::: quiz What does it print?
- [ ] 4-7-4 {ok}
- [x] 7-4-7 {ok}
- [ ] 7-4-7 ok
- [ ] It doesn't compile: argument 1 is used twice

`{1d}` is the second argument, 7, and an argument can be used as often as you like. `{{` and `}}` print braces.
:::

## Fix it

```zig
const winner = "Heap";
const time_s: u32 = 1303;
std.debug.print("{s} wins\n", .{ winner, time_s });
```

```text
error: unused argument in '{s} wins
```

::: quiz What's the fix?
- [x] Give time_s a hole: "{s} wins in {d} s\n"
- [ ] Number the hole: "{0s} wins\n"
- [ ] Use {any} instead of {s}
- [ ] Put time_s first

Every argument must be used. Numbering the hole still leaves `time_s` unused (`unused argument in '{0s} wins`),
and so do the other two.
:::

## Build it

### Exercise

Ask a second question after the rider: `How long a race, in km? (default 12.5) `. Turn the answer into a number
with `std.fmt.parseFloat(f64, answer)`. When there's no answer, or it isn't a number, use 12.5, and when it isn't
a number, also write `note: "far" isn't a number; racing 12.5 km` to stderr.

Write a function `fn pickDistance(answer: ?[]const u8) ?f64` (the number, or `null` for "use the default") and
test it first: `"20"` gives 20, `"far"` and `null` give `null`. Then use it in `main` (the course's distance can't
change yet; print the choice with a named argument, `racing {[km]d:.1} km`).

```sh
zig build test --summary all
```
