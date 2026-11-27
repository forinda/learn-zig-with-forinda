# Part 2: Basics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Part 2 of the course: six lessons that teach values and types, decisions, loops, functions,
arrays and slices, and text, while the game grows from a race card into a race: eight riders moving along
a road, drawn in text every kilometre.

**Architecture:** Same as Part 1: lessons in `src/pages/learn/basics/` (5E steps, lesson layout, quiz,
exercise), code steps `code/steps/04-..09-` (complete Zig 0.17 projects, each built on the previous one),
diffs from `pnpm diffs`, page rules from `pnpm test`. One new illustration of Agama for the part.

**Tech Stack:** Zig 0.17.0; the course site (clarusjs 0.16, theme-docs 0.5).

**Spec:** docs/superpowers/specs/2026-11-28-course-design.md (Curriculum Part 2; Lesson page shape;
Teaching frameworks; Calls made after the builder check).

Plan 2 of 13.

## Global Constraints

- Zig 0.17.0. Every step: `build.zig`/`build.zig.zon` as in Part 1 (name `.tour`, fingerprint
  `0x6ad1f969430a8a84`), `zig build run` prints, `zig build test` passes; `pnpm steps` checks all three.
- Each step starts as a copy of the previous step and changes only what its lesson teaches (the diff is the
  lesson's Elaborate). Keep earlier comments and functions (`title`, `raceCard`) unless the lesson replaces them.
- Generic programming names only (course "Compile Pass", teams like "Team Allocator"); riders are letters
  `A`..`H`. No Kenyan names.
- Units in names: `_m` metres, `_s` seconds, `_mps` metres per second, `_pct` percent.
- No AI attribution in commits or PRs.

## Review Focus

1. A beginner who reads only the page can do each Explore and Exercise without the repository (snippets are on the page; folder names are said).
2. Float vs integer mistakes a beginner will hit (`u32` × `f64`, integer division) are shown with the compiler's real message, verified on 0.17.
3. Each step's output in the lesson matches what `zig build run` actually prints (copied from a real run).
4. Each lesson's diff contains only what that lesson teaches.
5. The part's create task (lesson 09's exercise) has more than one valid answer and a way to check it.

---

### Task 1: Code steps 04–09

**Files:** code/steps/04-values … 09-text-road (copy the previous step, then change); code/diffs (generated).

Each bullet: the step's new functions (exact signatures), its tests (names and assertions), and what
`main` prints. Write the tests first, watch them fail (`zig build test`: "use of undeclared identifier"),
implement, pass.

- **04-values** — `const dt_s: f64 = 1.0;` and `fn advance(position_m: f64, speed_mps: f64, dt: f64) f64`
  (position + speed × dt). Tests: `test "a rider at 10 m/s covers 10 m in a second"` (advance(0, 10, 1) == 10);
  `test "advance adds to where the rider already is"` (advance(100, 12.5, 2) == 125). Main: the race card,
  then a rider at 10 m/s (`var position_m: f64 = 0`) advanced three times, printing `after 1 s: 10.0 m` …
  `after 3 s: 30.0 m`.
- **05-decisions** — `fn finished(position_m: f64, distance_m: f64) bool` (>=) and
  `fn speedFor(gradient_pct: f64) f64`: above 3 % → 6.0, below −3 % → 14.0, else 10.0 (`if`/`else if`/`else`).
  Tests: `test "a rider at the line has finished"` (finished(12_500, 12_500) true, finished(12_499.9, 12_500)
  false); `test "climbs are slow, descents fast"` (speedFor(5)=6, speedFor(-5)=14, speedFor(0)=10,
  speedFor(3)=10). Main: prints the speed on a flat road, a 5 % climb and a 5 % descent.
- **06-loops** — `fn secondsToFinish(distance_m: f64, speed_mps: f64) u32` (a `while` that advances by dt
  and counts seconds until `finished`). Tests: `test "12.5 km at 10 m/s takes 1250 s"`;
  `test "a part-second still counts as a second"` (secondsToFinish(100, 30) == 4). Main: simulates one rider
  second by second with `while`, printing a line each time it passes a whole kilometre (`km 1 at 100 s` …),
  then `finished in 1250 s`; a `for (1..4) |lap|` example prints three laps' worth only in the lesson's Explain,
  not in main.
- **07-functions** — `fn printTime(w: *std.Io.Writer, seconds: u32) !void` (`m:ss`, seconds zero-padded:
  `{d}:{d:0>2}`); main's kilometre lines now use it (`km 1 at 1:40`). Tests:
  `test "times print as minutes and seconds"` (100 → "1:40", 65 → "1:05", 3605 → "60:05", via
  `std.Io.Writer.fixed`). The lesson also explains parameters are constants, return values, `!void` and `try`.
- **08-arrays-slices** — `const speeds_mps = [_]f64{ 10.0, 10.4, 9.8, 10.1, 9.6, 10.2, 9.9, 10.3 };`;
  `fn advanceAll(positions_m: []f64, speeds_mps: []const f64, dt: f64) void` (in place, a `for` over both
  slices); `fn leader(positions_m: []const f64) usize` (index of the furthest). Tests:
  `test "everyone moves at their own speed"` (positions {0, 0} speeds {10, 12} → {10, 12});
  `test "the leader is the furthest along"` (leader of {3, 9, 4} == 1). Main: eight riders, a `while` until
  the leader finishes, printing `km N: leader is C` each kilometre (letters: `'A' + @as(u8, @intCast(i))`).
- **09-text-road** — `fn drawRoad(buf: []u8, positions_m: []const f64, distance_m: f64) []const u8`:
  `@memset(buf, '-')`, then each rider's letter at column `@intFromFloat(position / distance × (buf.len − 1))`
  (clamped to the end), returns `buf`. Tests: `test "a rider at the start is at column 0"`;
  `test "a rider at the line is at the last column"`; `test "two riders, two letters"` (8-wide road,
  positions {0, 50} of 100 → "A---B---" with B at column 3 as computed; assert by index, not by the whole
  string, so the rounding rule is explicit). Main: each kilometre prints the road (a 50-character buffer
  `var road: [50]u8 = undefined;`) under the km line.

- [ ] For each step: copy the previous step folder (without .zig-cache/zig-out), tests first (RED), implement (GREEN), `zig build run` and copy its exact output for the lesson.
- [ ] `node scripts/check-steps.ts` → ok for 01–09; `node scripts/diff-steps.ts` writes 04–09 diffs; read each diff: only the lesson's change.
- [ ] Commit `feat(code): Part 2 steps (values, decisions, loops, functions, arrays and slices, a text road)`.

### Task 2: Compiler-error snippets for Part 2

**Files:** code/broken/04-values/{int-times-float.zig, int-division.zig}.

- `int-times-float.zig`: `const riders: u32 = 8; const speed_mps: f64 = 10.0; const total = riders * speed_mps;` printed. `int-division.zig`: `const half = 7 / 2;` printed with `{d}` (shows 3: not an error, a surprise) — the lesson shows `@as(f64, 7) / 2`.
- [ ] `zig run` each; record the first error line of the first (expected: an incompatible-types / coercion error) and the output of the second, exactly, for lesson 04.
- [ ] Commit `feat(code): Part 2 broken programs (int times float, integer division)`.

### Task 3: Part 2 lessons

**Files:** src/pages/learn/basics/04-values-and-types.md, 05-making-decisions.md, 06-loops.md,
07-functions.md, 08-arrays-and-slices.md, 09-text-on-the-road.md; src/course.ts (Part 2 `art`).

Frontmatter: group "Basics", order 1..6, lesson layout, `steps: true`, minutes 15–25, `step` = 04..09
folder, competency:
04 "I can store values in constants and variables of the right type";
05 and 06 "I can make decisions and repeat work with if, while and for";
07 "I can write functions that take and return values";
08 and 09 "I can work with arrays, slices and text".

Each lesson in the 5E steps (Engage: a problem in the game; Explore: run the current step or a snippet and
notice; Explain: the idea, a ≤15-line example, a ```mermaid or ```text picture where it helps; Elaborate:
"I do" the diff (`<<< @/code/diffs/NN-*.diff`), "We do" build it and run it (real output as ```text);
Evaluate: `::: quiz`, `zig build test`, `### Exercise` with a hint).

- **04 Values and types:** const vs var (and the "never mutated" error), integers vs floats, `u32`/`f64`,
  arithmetic, mixing types (the broken snippet's real error), `@as` and `@floatFromInt`. Exercise: a rider
  at 36 km/h — convert to m/s in code and advance it.
- **05 Making decisions:** `bool`, comparisons, `if`/`else if`/`else` as statements and as expressions
  (`const s = if (x) a else b;`). Exercise: a fourth case, steep climbs over 8 % at 4 m/s, with its test.
- **06 Loops:** `while` with a condition and a counter, `for` over a range, `break`/`continue`; the
  kilometre markers. Explain with a ```mermaid flowchart of the loop. Exercise: print every 500 m instead.
- **07 Functions:** parameters (constants), return types, `void`, `!void` and `try`, functions that write
  through a writer vs functions that compute; why small functions are easy to test. Exercise: `printPace`
  printing minutes per km.
- **08 Arrays and slices:** fixed arrays `[8]f64`, `[_]` length inference, `.len`, indexing, `for` with
  index (`for (a, 0..) |x, i|`), slices `[]f64` vs `[]const f64`, passing a slice to change it in place,
  out-of-bounds caught at runtime in Debug (show the panic text from a real run). Exercise: `lastPlace`.
- **09 Text on the road:** strings are `[]const u8`, characters are `u8`, `'A' + i`, buffers, `@memset`,
  building a line of text, printing a slice. Exercise (Part 2's create task, Bloom "create"): make the road
  yours: mark the player's rider differently, show the finish line, or add a second line with km ticks;
  write a test for what you added. Any answer that passes its own test and prints a clear road counts.

- [ ] Write the six lessons; `pnpm test` → PASS (page rules); `pnpm build` → PASS.
- [ ] Commit `feat(learn): Part 2 lessons (values, decisions, loops, functions, arrays and slices, text)`.

### Task 4: Part 2 art

**Files:** public/art/agama-road.svg; src/course.ts (`art` for Basics).

- Agama in the chibi style of public/art/agama-hello.svg (big head, big eyes, open grin, cream banded belly,
  splayed toes, brown outlines, Zig-orange helmet), standing beside a road drawn as a text line
  (`A----B---@---`) on a sign or screen, holding a stopwatch. Front-facing, 400×300 viewBox.
- [ ] Draw, render to PNG (Playwright as before), check proportions against agama-hello, fix; set `art` for Basics; show it on lesson 04's Engage.
- [ ] Commit `art: Agama with a stopwatch beside the text road (Part 2)`.

### Task 5: Check, review, PR

- [ ] `pnpm steps`, `pnpm diffs --check` (node scripts/diff-steps.ts --check), `pnpm test`, `pnpm check`, `pnpm build`.
- [ ] Screenshot lesson 09's Elaborate and Evaluate.
- [ ] Whole-branch review (opus) with this plan's Review Focus; fix Important findings with TDD.
- [ ] PR with rulings and deferred minors; after merge, Pages redeploys.
