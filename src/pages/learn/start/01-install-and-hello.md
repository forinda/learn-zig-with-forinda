---
title: "Install Zig and say hello"
description: "Check your Zig install, make your first project, and print the game's name."
group: "Start"
order: 1
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 01-hello
competency: "I can install Zig 0.17 and check its version"
---

# Install Zig and say hello

## Engage

By the end of this course, your terminal will hold a whole bike race: riders, a breakaway, a chase and a
sprint for the line. Every game like that starts the same way: a program that prints one line.

Today you'll write that line: the game's name, **Terminal Tour**.

<img class="lesson-art" src="/art/agama-hello.svg" alt="Agama, the course's lizard, waving beside a terminal that says Terminal Tour" width="400" height="300" />

## Explore

First, check Zig is ready. Open a terminal and run:

```sh
zig version
```

You should see `0.17.0`. (Something else? Go back to [Set up Zig](/start/set-up).)

Now ask Zig to make a project for you. In an empty folder:

```sh
mkdir hello && cd hello
zig init
zig build run
```

Look at what it made: a `build.zig` (how to build the project), a `build.zig.zon` (the project's name and
version) and a `src` folder with the code. Open `src/main.zig` and find the line that printed the message
you just saw. Change the words in it, run `zig build run` again, and watch your change appear.

## Explain

A **program** is a list of instructions the computer follows, top to bottom. In Zig, it starts at a function
called `main`.

To print text, a program hands it to a **writer**. A writer doesn't send every letter to the screen straight
away: it collects text in a **buffer** (a small block of memory) and sends it all at once when you **flush**
it. That's much faster than one letter at a time, but if you forget to flush, your text never shows up.

```zig
var buffer: [1024]u8 = undefined; // room for 1024 bytes of text
var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
const out = &stdout.interface;    // the writer you print with

try out.print("Hello\n", .{});    // into the buffer
try out.flush();                  // onto the screen
```

`\n` means "new line". `try` means "if this fails, stop and report it": printing can fail, for example when
the screen is gone. You'll meet `try` properly in Part 3.

## Elaborate

Here is the first step of the game. **I do:** read it once, top to bottom, and match each line to the
explanation above.

<<< @/code/steps/01-hello/src/main.zig

**We do:** make your own copy. Either copy the whole folder `code/steps/01-hello` from the course repository, or
make the files yourself: `src/main.zig` above, and this `build.zig`:

<<< @/code/steps/01-hello/build.zig

and this `build.zig.zon`:

<<< @/code/steps/01-hello/build.zig.zon

Then, inside the folder:

```sh
zig build run
```

```text
Terminal Tour
```

That's the game's first line. (`zig init` made a bigger `build.zig` with more options; ours is the smallest one
that builds, runs and tests the game. The next lesson takes it apart.)

## Evaluate

::: quiz You delete the `try out.flush();` line and run the program. What happens?
- [ ] The text prints twice
- [x] Nothing is printed: the text stays in the buffer
- [ ] The program won't compile
- [ ] The text prints, but slowly

A writer keeps text in its buffer until it is flushed. Without the flush, the program ends before the text ever
reaches the screen.
:::

Run the tests:

```sh
zig build test
```

It finishes without complaint: there are no tests yet, so nothing can fail. You'll write the first one in the
next lesson.

### Exercise

Print a second line under the title: `A race in your terminal`. Then try printing your own name, too.

Hint: one `print` per line, each ending in `\n`, all before the `flush`.
