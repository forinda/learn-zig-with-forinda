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

**Read first:** [Install Zig and say hello](/guide/start/01-install-and-hello) in the Guide. This lesson checks you understood it.

## Recall

::: quiz You delete the `try out.flush();` line and run the program. What happens?
- [ ] The text prints twice
- [x] Nothing is printed: the text stays in the buffer
- [ ] The program won't compile
- [ ] The text prints, but slowly

A writer keeps text in its buffer until it is flushed. Without the flush, the program ends before the text ever
reaches the screen.
:::

::: quiz Which file describes how to build your project?
- [ ] src/main.zig
- [x] build.zig
- [ ] build.zig.zon
- [ ] zig-out/bin/tour

`build.zig` is a Zig program that describes the build. `build.zig.zon` holds the project's name and version, and
`zig-out/bin/tour` is what the build produces.
:::

## Predict

What does this print?

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;
    try out.print("Terminal ", .{});
    try out.print("Tour\n", .{});
    try out.flush();
}
```

::: quiz What does it print?
- [x] Terminal Tour, on one line
- [ ] Terminal and Tour on two lines
- [ ] Nothing: it flushes too late
- [ ] Tour, then Terminal

Only `\n` starts a new line. Both prints go into the buffer, one after the other, and the flush sends
`Terminal Tour` and a new line to the screen.
:::

## Fix it

This doesn't compile:

```zig
pub fn main(init: std.process.Init) void {
    var buffer: [1024]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    const out = &stdout.interface;
    try out.print("Terminal Tour\n", .{});
    try out.flush();
}
```

```text
error: expected type 'void', found 'error{WriteFailed}'
```

::: quiz What's the fix?
- [ ] Remove the flush
- [x] Make main return !void, so try has somewhere to send an error
- [ ] Change print to write
- [ ] Make the buffer bigger

`try` passes an error up to whoever called the function. A function returning `void` can't pass errors on; one
returning `!void` can.
:::

## Build it

### Exercise

In your project (or a copy of `code/steps/01-hello`), print a second line under the title: `A race in your
terminal`. Then add your own name on a third line.

Hint: one `print` per line, each ending in `\n`, all before the `flush`.

Check it still builds and the (empty) tests pass:

```sh
zig build run
zig build test
```
