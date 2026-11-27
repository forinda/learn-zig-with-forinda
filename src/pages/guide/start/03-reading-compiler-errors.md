---
title: "Reading compiler errors"
description: "The anatomy of a Zig error, the errors you'll meet most and their fixes, and formatted printing for the race card."
group: "Start"
order: 3
step: 03-race-card
---

# Reading compiler errors

You will write code that doesn't compile. Everyone does, every day. The Zig compiler is strict, and that's a gift:
it catches mistakes before the game ever runs, and it says exactly where they are. The skill isn't avoiding errors,
it's reading them. This page shows how, then uses formatted printing to give the game its first real screen: a
race card.

## The shape of an error

```text
b.zig:5:25: error: fractional component prevents float value '8.5' from coercion to type 'u32'
    const riders: u32 = 8.5;
                        ^~~
```

- **`b.zig:5:25`** is *where*: the file, line 5, column 25. Your editor jumps there.
- After **`error:`** comes *what* is wrong.
- Below, the line itself, with **`^~~`** under the exact spot.

Some errors add lines starting with **`note:`**, more detail (where the other half of the problem is, what was
expected). Some end with **`referenced by:`**, the chain of calls that led to the code; you can usually skip it.

**Fix the first error first.** One mistake can confuse the compiler about what follows, and the errors after it
often disappear when the first is fixed.

## Three to try

Three small programs, each broken on purpose. Make a folder and save each one there under its name (`a.zig`,
`b.zig`, `c.zig`), or find them in the course repository in `code/broken/03-race-card/`.

<<< @/code/broken/03-race-card/a.zig [a.zig]

<<< @/code/broken/03-race-card/b.zig [b.zig]

<<< @/code/broken/03-race-card/c.zig [c.zig]

In that folder, run each one and read the **first line** of what comes back, before reading on:

```sh
zig run a.zig
zig run b.zig
zig run c.zig
```

## The errors you'll meet most

| Error | What it means | The fix |
|---|---|---|
| `unused local constant` | You made a value and never used it. | Use it, or delete it. |
| `local variable is never mutated` | A `var` that never changes. | Make it `const`. |
| `fractional component prevents float value '8.5' from coercion to type 'u32'` | A whole-number type can't hold a fraction. | A whole number, or a float type (`f64`). |
| `error union of type 'error{WriteFailed}!void' is ignored` | Something that can fail wasn't checked. | `try` in front of it. |
| `use of undeclared identifier 'titel'` | A name Zig doesn't know: usually a typo, or it's in another scope. | Spell it as declared. |
| `expected ';' after statement` | A missing `;` at the end of the line above the `^`. | Add the `;`. |
| `expected statement, found 'EOF'` | The file ended inside a `{`: a missing `}`. | Close the brace. |
| `local constant shadows declaration of 'riders'` | A name used twice, inside and outside. | Rename one of them. |

Two are worth a closer look:

- **A missing `;`** is reported at the *end* of the line that lacks it (`semi.zig:3:26`), even though you'll often
  notice it on the next line.
- **A missing `}`** is reported at the end of the file (`expected statement, found 'EOF'`), far from where you
  forgot it. Your editor's bracket matching finds it faster.

Zig is strict about unused things and shadowing on purpose: an unused value is usually a forgotten step, and the
same name meaning two things is a bug waiting to happen.

::: tip Try it
Take any program from this course, misspell one name, and read the error. Then delete one `}` and see how far the
error is from the brace you deleted.
:::

## Formatted printing

The race card needs neat columns, and `print`'s holes can do much more than `{s}` and `{d}`. Inside the braces:
first what kind of value, then after `:` how to lay it out.

```zig
std.debug.print("[{s:<14}] [{s:>14}] [{s:^14}]\n", .{ "Compile Pass", "Compile Pass", "Pass" });
std.debug.print("[{d:.1}] [{d:>6.1}] [{d:0>2}] [{d:5}]\n", .{ 12.5, 12.5, 5, 42 });
std.debug.print("[{c}] [{x}] [{b}] [{any}] [{}]\n", .{ 'A', 255, 5, [_]u8{ 1, 2 }, true });
std.debug.print("[{s:-<10}]\n", .{"km"});
```

```text
[Compile Pass  ] [  Compile Pass] [     Pass     ]
[12.5] [  12.5] [05] [   42]
[A] [ff] [101] [{ 1, 2 }] [true]
[km--------]
```

| Hole | Prints | Example |
|---|---|---|
| `{s}` | text | `Compile Pass` |
| `{d}` | a number in decimal | `12.5` |
| `{d:.1}` | one decimal place | `12.5` |
| `{c}` | a byte as a character | `A` |
| `{x}`, `{b}` | a number in hex, in binary | `ff`, `101` |
| `{any}` | anything, as Zig sees it | `{ 1, 2 }` |
| `{}` | the default for simple values | `true` |
| `{s:<14}`, `{s:>14}`, `{s:^14}` | padded to 14: left, right, centred | |
| `{d:5}` | numbers line up to the right by default | `   42` |
| `{d:0>2}`, `{s:-<10}` | the character before `<`/`>`/`^` fills the space | `05`, `km--------` |
| `{0s}`, `{[name]s}` | an argument by position or by name (see [Talking to the terminal](/guide/memory/16-talking-to-the-terminal)) | |

Padding is how you draw boxes and tables that line up, as long as every value fits in its width.

## In the game

The game gets its first real screen: a **race card** for the first race, in a box. Three facts about the race
become constants at the top, under the `std` import:

<<< @/code/steps/03-race-card/src/main.zig#race

Below `title()`, the race card, padding each value so the box's right edge stays straight:

<<< @/code/steps/03-race-card/src/main.zig#card

In `main`, print the card instead of the title:

<<< @/code/steps/03-race-card/src/main.zig#main

And its test, at the end of the file. It doesn't print to the screen: it prints the card into a fixed buffer and
checks the buffer holds the course, the distance and the field:

<<< @/code/steps/03-race-card/src/main.zig#test

Run it (or copy `code/steps/03-race-card`):

```sh
zig build run
```

```text
+------------------------------+
| Terminal Tour                |
|                              |
| Course:   Compile Pass       |
| Distance:  12.5 km           |
| Field:    8 riders           |
+------------------------------+
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/03-race-card/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/03-race-card.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/start/03-reading-compiler-errors) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
