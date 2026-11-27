---
title: "Install Zig and say hello"
description: "Your first Zig program: zig run and zig build, main, std, comments, and printing to the terminal two ways."
group: "Start"
order: 1
step: 01-hello
---

# Install Zig and say hello

By the end of this course, your terminal will hold a whole bike race: riders, a breakaway, a chase and a sprint
for the line. Every program like that starts the same way: with one line of text on the screen. This page gets
Zig running and prints the game's name, **Terminal Tour**, and on the way shows what a Zig program is made of.

<img class="lesson-art" src="/art/agama-hello.svg" alt="Agama, the course's lizard, waving beside a terminal that says Terminal Tour" width="400" height="300" />

## Check Zig is ready

In a terminal:

```sh
zig version
```

```text
0.17.0
```

Something else? Go back to [Set up Zig](/start/set-up): the course's code is tested with exactly 0.17.0.

## A program in one file: zig run

The quickest way to run Zig is one file and `zig run`. Save this as `hello.zig`:

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Terminal Tour\n", .{});
}
```

```sh
zig run hello.zig
```

```text
Terminal Tour
```

`zig run` compiles the file, runs the result, and throws the program away. That's perfect for trying things out,
and you'll use it for the small examples all through the course.

## What a program is made of

- **`const std = @import("std");`** brings in Zig's **standard library**, the toolbox that comes with Zig
  (printing, maths, text, files…), and names it `std`. `@import` is a **builtin**: a function built into the
  language, always written with `@`.
- **`pub fn main() void`** is a **function** called `main`. Every program starts there. `pub` makes it visible
  from outside the file, so Zig can find it; `void` says it gives nothing back.
- Everything between `{` and `}` is the function's body: the instructions, run top to bottom. Each ends with `;`.

### Comments

Text the compiler ignores, for people:

```zig
// A comment: from // to the end of the line.

/// A doc comment: it documents whatever follows it (a function, a constant…),
/// and tools like the editor show it when you hover the name.
pub fn main() void {}
```

### Text in quotes, and special characters

Inside `"..."`, a backslash starts a special character:

| Write | You get |
|---|---|
| `\n` | a new line |
| `\t` | a tab |
| `\"` | a double quote inside the text |
| `\\` | a backslash |

```zig
std.debug.print("rider \"A\" leads\n", .{});
```

```text
rider "A" leads
```

### Holes in the text

`print` fills `{...}` holes in the text with the values in `.{ ... }`, in order: `{s}` for text, `{d}` for a
number:

```zig
std.debug.print("{s} has {d} riders\n", .{ "Compile Pass", 8 });
```

```text
Compile Pass has 8 riders
```

The holes are checked while compiling. One hole and no value won't build:

```text
.../lib/std/Io/Writer.zig:803:13: error: too few arguments
```

Notice where that error points: into Zig's own `Writer.zig`, not your file. The next lines of the message (the
"called from" part) lead back to your `print`. You'll read errors properly in
[Reading compiler errors](/guide/start/03-reading-compiler-errors).

## Printing two ways

`std.debug.print` is the quick way, and it's for **debugging**: it writes to **stderr**, the terminal's channel
for messages and errors. A program's real output goes to **stdout**. You can see the difference by sending
stdout into a file:

```zig
pub fn main(init: std.process.Init) !void {
    std.debug.print("debug: to stderr\n", .{});

    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;
    try out.print("writer: to stdout\n", .{});
    try out.flush();
}
```

```sh
zig run hello.zig > out.txt
```

```text
debug: to stderr
```

The debug line still appears on the screen; `out.txt` holds `writer: to stdout`. The game prints the second way.

That second way needs a few pieces:

- **`main(init: std.process.Init)`**: `main` can take what the program starts with. `init.io` is how a program
  reaches the outside world (files, the terminal), so whatever writes to the screen gets it.
- **A writer with a buffer**: printing collects text in a **buffer** (here 1024 bytes of memory) and sends it to
  the screen in one go when you **flush**. Fewer trips to the screen is much faster, but forget the flush and
  nothing shows up.
- **`try`**: printing can fail (the screen could be gone), so it returns "done, or an error". `try` means "if it's
  an error, stop here and pass it on". That's why `main` now returns `!void`: "nothing, or an error". Part 3 covers
  errors properly.

| | `std.debug.print` | a stdout writer |
|---|---|---|
| goes to | stderr | stdout |
| for | quick checks while you work | the program's real output |
| needs | nothing | `init.io`, a buffer, `try`, a `flush` |
| can fail? | no (it ignores problems) | yes, so `try` |

::: tip Try it
Delete the `try out.flush();` line and run it again. Where did the writer's text go?
:::

## A project: zig build

A single file is fine for experiments; a game needs a **project**: the code in `src/`, plus a `build.zig` saying
how to build it. `zig init` makes one:

```sh
mkdir hello && cd hello
zig init
zig build run
```

It creates `build.zig` (how to build), `build.zig.zon` (the project's name and version) and `src/` with the code.
`zig build run` builds the program and runs it; the built program stays in `zig-out/bin/`. The course's projects
use a smaller `build.zig` than `zig init`'s: the [next page](/guide/start/02-build-run-test) takes it apart.

| | `zig run file.zig` | `zig build run` |
|---|---|---|
| for | one file, trying things | a project with a `build.zig` |
| keeps the program? | no | yes, in `zig-out/bin/` |
| tests, options, several files | no | yes |

## In the game

The game's first step is a project whose `main` prints its name through a stdout writer. Here's all of it:
`src/main.zig`,

<<< @/code/steps/01-hello/src/main.zig

this `build.zig`,

<<< @/code/steps/01-hello/build.zig

and this `build.zig.zon`:

<<< @/code/steps/01-hello/build.zig.zon

Copy the folder `code/steps/01-hello` from the course repository, or make the three files yourself, then inside
the folder:

```sh
zig build run
```

```text
Terminal Tour
```

That's the game's first line.

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/start/01-install-and-hello) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
