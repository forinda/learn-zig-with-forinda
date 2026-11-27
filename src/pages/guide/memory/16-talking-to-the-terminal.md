---
title: "Talking to the terminal"
description: "stdin, stdout and stderr; readers and writers; reading a line and what can go wrong; positional and named arguments, widths from arguments and escaping braces."
group: "Memory"
order: 1
step: 16-terminal-io
---

# Talking to the terminal

The game has only ever talked. The player watches rider A, always, and never says a word. A game needs to listen:
which rider are you? what's your name? race again? This page is about the three channels every terminal program
has, how to read what the player types, and the rest of formatted printing. It also ends somewhere important:
a fixed buffer, and what happens when the player types more than fits. That's what the rest of Part 4 is about.

<img class="lesson-art" src="/art/agama-memory.svg" alt="Agama, the course's lizard, pointing at a terminal that asks Which rider are you, beside a stack of memory blocks" width="400" height="300" />

## Three streams

Every program starts with three **streams** already open:

| Stream | Direction | For | In Zig |
|---|---|---|---|
| **stdin** | in | what the player types (or what's piped in) | `std.Io.File.stdin()` |
| **stdout** | out | the program's real output | `std.Io.File.stdout()` |
| **stderr** | out | notes, warnings, errors | `std.Io.File.stderr()` |

On screen, stdout and stderr look the same. They're separate so the shell can send them to different places:

```sh
./tour > race.txt        # stdout into a file; stderr still on screen
./tour 2> notes.txt      # stderr into a file
echo b | ./tour          # stdin comes from echo instead of the keyboard
./tour < answers.txt     # stdin comes from a file
```

A note like "that answer is too long" on stdout would end up in `race.txt` mixed in with the race. On stderr it
stays on screen, and the file holds only the race.

## Readers and writers

You've used a **writer** since Part 1: a stream plus a buffer, `print` to fill the buffer, `flush` to send it.
Reading works the same way the other way round: a **reader** is a stream plus a buffer that it fills from the
stream as you take bytes out.

```zig
var in_buffer: [64]u8 = undefined;
var stdin: std.Io.File.Reader = .init(.stdin(), init.io, &in_buffer);
const in = &stdin.interface; // a *std.Io.Reader: what reading functions take
```

A stderr writer is a stdout writer pointed at another stream:

```zig
var err_buffer: [256]u8 = undefined;
var stderr: std.Io.File.Writer = .init(.stderr(), init.io, &err_buffer);
const err = &stderr.interface;
```

`std.debug.print` also writes to stderr, with no buffer and no `try`. It's for you, while you work; a stderr
writer is for messages the program means to give its user.

## Reading a line

`takeDelimiter('\n')` reads up to the next newline and gives you the line without it:

```zig
const line = try in.takeDelimiter('\n');
```

It has three answers, and the type says so: `error{ReadFailed, StreamTooLong}!?[]u8`.

| You get | When |
|---|---|
| a line | the player typed something and pressed Enter (or the last line of a file, newline or not) |
| `null` | the input has ended: a file ran out, or the player pressed Ctrl+D (Ctrl+Z on Windows) |
| `error.StreamTooLong` | the line doesn't fit in the reader's buffer |

The line is a slice of the reader's buffer: it's only good until the next read, which reuses that memory. Keep
something from it by copying it (next page).

### Clean up what was typed

People type spaces around answers, and a Windows terminal ends lines with `\r\n`, so the line still has a `\r` on
the end. Trim them before you compare:

```zig
const answer = std.mem.trim(u8, line, " \t\r");
```

Without it, `"b\r"` isn't `"b"`, and only Windows players find the bug.

### Ask, then wait: flush first

The question sits in stdout's buffer until a flush. Read without flushing and the program waits for an answer
to a question that isn't on screen yet:

```zig
try out.print("Which rider are you (A-H)? ", .{});
try out.flush(); // now it's on screen
const line = try in.takeDelimiter('\n');
```

### Every question needs a default

Input can end at any moment, or never start: piped from an empty file, run by a script, run by the course's own
checks (which give the game no input at all). A program that assumes an answer crashes or hangs there. Decide
what "no answer" means, and use it for `null`.

## Formatting, the rest of it

[Reading compiler errors](/guide/start/03-reading-compiler-errors) covered what goes inside a hole. Holes can also
say *which* argument they want.

### Positional: by number

```zig
std.debug.print("Good luck, {0s}! {0s} rides as {1c} today.\n", .{ "Ada", 'H' });
```

```text
Good luck, Ada! Ada rides as H today.
```

`{0s}` is the first argument, used twice. Holes without numbers take the arguments in order.

### Named: by field name

Pass a struct with named fields instead of a list, and name them in the holes:

```zig
std.debug.print("you ({[name]c}) were {[gap]d:.0} m from the line\n", .{ .name = 'H', .gap = 242.4 });
```

The text reads like the sentence it prints, and reordering the sentence doesn't mean reordering the arguments.

### Widths from arguments, and braces

A width or precision can come from an argument too: `[1]` by position, `[w]` by name:

```zig
std.debug.print("[{0d:>[1]}] [{2s:<[1]}|]\n", .{ 42, 6, "km" });
std.debug.print("[{[v]d:>[w].1}]\n", .{ .v = 3.14159, .w = 7 });
std.debug.print("{{ and }}\n", .{});
```

```text
[    42] [km    |]
[    3.1]
{ and }
```

`{{` and `}}` print a brace. Every argument must be used:

```text
error: unused argument in '{d} {d}
```

and a name has to exist:

```text
error: no argument with name 'w'
```

Both are checked while compiling, like every format string.

::: tip Try it
Write a program that asks "What's your name?" and greets you twice in one `print` with `{0s}`. Then run it with
`echo Ada | zig run hello.zig`, and with `zig run hello.zig < /dev/null` (on Windows, `< NUL`).
:::

## Which stream when

| You're writing | Send it to | Because |
|---|---|---|
| the program's results | stdout (a buffered writer) | it's what `>` and `\|` should capture |
| a note, a warning, an error for the user | stderr (a writer) | stays visible when stdout is redirected |
| a debugging print while you work | `std.debug.print` | quick, no setup, stderr |
| a question to the player | stdout, flushed | it must show before you read |

The game prompts on stdout, which keeps it simple. Tools meant to be redirected often prompt on stderr
instead, so their stdout stays clean.

## In the game

The player picks a rider. Problems with the answer go to stderr, and the road draws whichever rider you are.
In `main`, after the stdout writer, the other two streams:

<<< @/code/steps/16-terminal-io/src/main.zig#streams

Below `raceCard`, asking and understanding the answer:

<<< @/code/steps/16-terminal-io/src/main.zig#input

In `main`, after the race card, the question. A too-long answer is a note on stderr, not the end of the game:

<<< @/code/steps/16-terminal-io/src/main.zig#ask

`drawRoad` takes which rider is you, instead of always A (every call to it, including the tests', passes the
extra argument; the tests pass `0`):

<<< @/code/steps/16-terminal-io/src/main.zig#road

The ending uses named arguments, and a player who wins has crossed the line, not finished −6 m from it:

<<< @/code/steps/16-terminal-io/src/main.zig#you

The tests, at the end of the file. `std.Io.Reader.fixed` and `std.Io.Writer.fixed` stand in for the terminal:
a reader over a string, a writer into an array:

<<< @/code/steps/16-terminal-io/src/main.zig#tests

Run it (or copy `code/steps/16-terminal-io`) and answer `e`:

```sh
zig build run
```

```text
Which rider are you (A-H)? e
...
km 6 at 11:51: leader is E
  ----------------------FE--------------------------
...
winner: H
you (E) were 242 m from the line
```

With no input at all, the game picks A and carries on:

```sh
zig build run < /dev/null
```

```text
Which rider are you (A-H)? 
...
you (A) were 125 m from the line
```

And an answer longer than the 64-byte buffer goes to stderr. Send stdout away to see it alone:

```sh
echo "an answer far too long for a sixty-four byte buffer, honestly, it goes on" | ./zig-out/bin/tour > /dev/null
```

```text
note: that answer is too long for 64 bytes; you're rider A
```

That limit is the next page's problem: the game is about to ask for your name, and names don't come in a fixed
size.

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/16-terminal-io/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/16-terminal-io.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/memory/16-talking-to-the-terminal) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
