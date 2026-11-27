---
title: "Build, run and test"
description: "What build.zig describes, the run and test steps, and your first test."
group: "Start"
order: 2
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 02-first-test
competency: "I can create, build, run and test a Zig project"
---

# Build, run and test

**Read first:** [Build, run and test](/guide/start/02-build-run-test) in the Guide. This lesson checks you understood it.

## Recall

::: quiz Which command runs the `test` blocks in your project?
- [ ] zig build run
- [x] zig build test
- [ ] zig test build.zig
- [ ] zig run test

`zig build test` runs the `test` step your `build.zig` describes: it builds the tests from your module and runs
them.
:::

::: quiz After zig build, where is the game?
- [ ] src/tour
- [x] zig-out/bin/tour (tour.exe on Windows)
- [ ] .zig-cache/tour
- [ ] build/tour

The install step copies the built program to `zig-out/bin`. `.zig-cache` holds Zig's working files.
:::

## Predict

```zig
const std = @import("std");

test "the game has a title" {
    try std.testing.expectEqualStrings("Terminal Tour", "Terminal Tor");
}
```

::: quiz What does zig build test say about this test?
- [ ] It passes: the strings are close enough
- [x] It fails, showing the expected text and the text it found instead
- [ ] It doesn't compile
- [ ] It's skipped

`expectEqualStrings` compares every character. It fails and prints `expected this output: Terminal Tour` and
`instead found this: Terminal Tor`, so you can see exactly where they differ.
:::

## Fix it

```zig
test "four riders" {
    std.testing.expectEqual(4, 2 + 2);
}
```

```text
error: error union of type 'error{}!void' is ignored
```

::: quiz What's the fix?
- [x] try std.testing.expectEqual(4, 2 + 2);
- [ ] Change 4 to 5
- [ ] Remove the test name
- [ ] return std.testing.expectEqual(4, 2 + 2);

A check that fails returns an error. `try` hands it to the test runner, which reports the test as failed. Without
`try`, Zig won't let you ignore it.
:::

## Build it

### Exercise

Add a function `subtitle()` that returns `"A race in your terminal"`, print it under the title, and write a test
for it. Write the test first and watch it fail.

Hint: copy the shape of `title()` and its test. Any test that fails when the subtitle is wrong is a good test.

```sh
zig build test --summary all
```
