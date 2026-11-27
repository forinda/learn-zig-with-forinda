# Part 3: Structure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Part 3 of the course: six concepts that give the game real types (structs and methods, a race
type and testing it well, enums and `switch`, tagged unions, optionals, errors), each as a Guide page and a
Course lesson, while the game turns its loose arrays into a `Race` of `Rider`s on a `Course` of segments,
reports events, and reads its course from text.

**Architecture:** As Part 2, in the Guide-then-Course shape (spec: "teach in the Guide, check in the
Course"): guide pages `src/pages/guide/structure/10-..15-*.md` (Engage, Explore, Explain, Elaborate),
lessons `src/pages/learn/structure/10-..15-*.md` (Recall, Predict, Fix it, Build it; Stretch in 15), code
steps `code/steps/10-..15-` (each a copy of the previous step, changed only by its lesson), one illustration.

**Tech Stack:** Zig 0.17.0; the course site (clarusjs 0.16, theme-docs 0.5).

**Spec:** docs/superpowers/specs/2026-11-28-course-design.md (Curriculum Part 3; "teach in the Guide,
check in the Course"; Teaching frameworks).

Plan 3 of 13.

## Global Constraints

- Zig 0.17.0; every step builds, tests and runs (`pnpm steps`); `pnpm diffs --check`; `pnpm test`; `pnpm build`.
- Each step starts as a copy of the previous one; its diff is only what its lesson teaches.
- Generic programming names; riders are letters A..H; units in names (`_m`, `_s`, `_mps`, `_pct`).
- Every Explore, Predict and Fix-it snippet is run on 0.17 and the page quotes its real output or error;
  every quiz has exactly one right answer (wrong options checked to really be wrong where they could compile).
- Diagrams: narrow (top-to-bottom, ≤ 5 boxes a row), short labels.
- Drawing order on the road stays: field, then rider A, then the leader.
- No AI attribution in commits or PRs.

## Review Focus

1. A reader who only reads the Guide page can do its Explore and the lesson's Build it without the repository.
2. Each Fix-it quotes the error Zig 0.17 really gives first (as lesson 08 taught us: not always the one you'd expect).
3. The refactor steps (10 parallel arrays → structs; 11 → `Race`) keep the printed race identical, and the guide says so and shows it.
4. Error handling (15): every error path has a test with `expectError`, and the guide shows what an unhandled error looks like at runtime (error return trace).
5. Quizzes about `switch` exhaustiveness and optionals have exactly one right answer.

---

### Task 1: Code steps 10–15

**Files:** code/steps/10-structs … 15-errors; code/diffs (generated). Tests first in each step (RED: "use of
undeclared identifier"/missing field), then implement (GREEN); copy each `zig build run` output for the guide.

- **10-structs** — `const Rider = struct { name: u8, speed_mps: f64, position_m: f64 = 0, fn advance(self: *Rider, dt: f64) void, fn finished(self: Rider, distance_m: f64) bool };` The field becomes `var field: [8]Rider` built from `field_speeds_mps` in a `for`; `advanceAll`/`leader`/`drawRoad` take `[]Rider`/`[]const Rider`. Tests: `test "a rider moves at its own speed"` (method), `test "a new rider starts at the line"` (default field value). Printed race unchanged from step 09.
- **11-race** — `const Course = struct { name: []const u8, distance_m: f64 };` `const Race = struct { course: Course, riders: [8]Rider, clock_s: u32 = 0, fn init(course: Course, speeds_mps: []const f64) Race, fn step(self: *Race) void, fn leader(self: *const Race) usize, fn done(self: *const Race) bool };` main drives `race.step()` until `race.done()`. Tests (the lesson's "testing well"): `test "a new race has everyone at the start"`, `test "after one step everyone has moved by their speed"` (expectEqualDeep on positions), `test "the race is done when the leader crosses the line"` (edge: exactly on the line), `test "riders can't start beyond the field"` (init with fewer speeds than 8 → the rest default to 10 m/s; documents the rule). Printed race unchanged.
- **12-enums** — `const Terrain = enum { flat, climb, descent, fn of(gradient_pct: f64) Terrain };` `speedFor` becomes `fn speedFor(terrain: Terrain) f64` with an exhaustive `switch`; `const Segment = struct { start_m: f64, gradient_pct: f64 };` the course gets `segments: []const Segment` (Compile Pass: flat 0–4 km, climb 4–6 km at 6 %, descent 6–8 km at −6 %, flat to the line) and `fn terrainAt(self: Course, position_m: f64) Terrain`; riders' speed each step is their own base speed scaled by the terrain (`base × speedFor(terrain) / 10`). Tests: `test "gradients map to terrain"` (−5 → descent, 0 → flat, 3 → flat, 5 → climb), `test "the course knows its terrain"` (terrainAt(1000) flat, (5000) climb, (7000) descent). The printed race changes (times shift on the climb): copy the real output.
- **13-tagged-unions** — `const Event = union(enum) { km: u32, new_leader: u8, finished: u8 };` `fn step(self: *Race, events: []Event) []Event` returns the events of that second (at most 8); main prints each with a `switch` on the event (`km 5 at 8:01`, `C takes the lead`, `B finishes in 20:02`). Leader changes now happen (the climb reshuffles the field): copy the real output. Tests: `test "a step that passes a km marker reports it"`, `test "a new leader is reported once"`, `test "a finisher is reported once"`.
- **14-optionals** — `winner: ?u8 = null` on `Race` (set by the first `finished` event); `fn riderNamed(self: *Race, name: u8) ?*Rider`; main prints `winner: B` with `if (race.winner) |w|` and looks up the player with `orelse`. Tests: `test "no winner until someone finishes"`, `test "an unknown rider name gives null"` (riderNamed('Z') == null), `test "a known name finds that rider"`.
- **15-errors** — the course is read from text: `const compile_pass_text = \\` multiline string (`flat 4000`, `climb 2000 6`, `descent 2000 -6`, `flat 4500`); `const ParseError = error{ UnknownTerrain, MissingNumber, BadNumber };` `fn parseCourse(text: []const u8, segments: []Segment) ParseError![]Segment` (`std.mem.tokenizeScalar`, `std.fmt.parseFloat`/`parseInt`, mapping their errors to `BadNumber`); main uses `try`. Tests: `test "Compile Pass parses into four segments"`, `test "an unknown terrain is an error"` (expectError UnknownTerrain), `test "a missing number is an error"`, `test "a number that isn't one is an error"`, `test "too many segments for the buffer is an error"` (add `TooManySegments`). Printed race unchanged from 14.

- [ ] Steps 10–15 in order, each RED then GREEN, real output captured.
- [ ] `node scripts/check-steps.ts` → ok 01–15; `node scripts/diff-steps.ts`; read each diff: only its lesson.
- [ ] Commit `feat(code): Part 3 steps (structs, a race type, enums, tagged unions, optionals, errors)`.

### Task 2: Guide pages 10–15

**Files:** src/pages/guide/structure/10-structs.md, 11-a-race-type.md, 12-enums-and-switch.md,
13-tagged-unions.md, 14-optionals.md, 15-errors.md.

Frontmatter: group "Structure", order 1..6, `step` 10..15. Sections Engage, Explore, Explain, Elaborate
(Explore: a ≤15-line snippet to run, with what to change; Explain: the idea, ≤15-line examples, real
output/errors, a narrow diagram where it helps; Elaborate: I do (`<<< @/code/diffs/NN-*.diff`), we do
(build and run, real output)). Ends with the "Check your understanding" tip linking to its lesson.

- **10 Structs:** fields, default values, `self`, methods (`rider.advance(dt)`), `*Rider` vs `Rider` for
  methods that change vs read, arrays of structs vs parallel arrays; Elaborate shows the output is unchanged.
- **11 A race type:** a struct of structs, `init` functions returning the value, `*const Race`, and testing
  well: one behaviour per test, names that say the rule, edges (exactly on the line), `expectEqualDeep`.
- **12 Enums and switch:** enums, methods on enums, `switch` must cover every case (show the real error when
  one is missing), `else`, ranges in switch on integers; the course of segments (a `text` drawing of the profile).
- **13 Tagged unions:** one value of several kinds, `union(enum)`, `switch` with captures (`.km => |n|`), why
  not a struct with optional fields; returning a slice of a caller's buffer.
- **14 Optionals:** `?T`, `null`, `if (x) |v|`, `orelse`, `.?` (and the panic when it's null: real text),
  optional pointers `?*Rider`.
- **15 Errors:** error sets, `E!T`, `try`, `catch` (with a value, with a block), `expectError`, mapping
  library errors to your own, an unhandled error at runtime (real error return trace), multiline strings `\\`,
  `std.mem.tokenizeScalar`.

- [ ] Write; every snippet run on 0.17; `pnpm test` (guide rules; lesson links fail until Task 3 — write Task 3 before running the pairing test, or run with both).
- [ ] Commit with Task 3.

### Task 3: Lessons 10–15

**Files:** src/pages/learn/structure/10-..15-*.md (same names as the guide pages).

Frontmatter: lesson layout, `steps: true`, minutes 10–20, `step`, competency:
10, 12, 13 "I can model the game with structs, enums and tagged unions";
11 "I can write tests for the code I write";
14, 15 "I can handle missing values with optionals and failures with errors".
"Read first" link, then Recall (2 quizzes), Predict (snippet + quiz), Fix it (snippet + real error + quiz),
Build it (exercise + `zig build test`); 15 adds Stretch.

- Exercises: 10 `Rider.gapTo(other)`; 11 a test for `Race.leader` on a tie (lowest index wins) and making it
  pass; 12 a `.cobbles` terrain at 8 m/s (the compiler lists every switch to update); 13 an `Event.half_way`
  reported once when the leader passes half the distance; 14 `Race.lastFinisher() ?u8`; 15 a `sprint` segment
  kind with its own speed, parsed from text, with an error test.
- Stretch (15, Part 3's create task): design your own course in the text format with at least four segments
  and one new terrain; write a test that parses it and one that rejects a broken version of it.

- [ ] Write; every snippet run on 0.17; `pnpm test` → PASS (guide, lesson, pairing, stretch rules); `pnpm build` → PASS.
- [ ] Commit `feat: Part 3 guide pages and lessons (structs, a race type, enums, tagged unions, optionals, errors)`.

### Task 4: Part 3 art

**Files:** public/art/agama-structure.svg; src/course.ts (`art` for Structure).

- Agama (chibi style as agama-hello/agama-road) holding a clipboard with a "rider card" (`name: 'A'`,
  `speed: 10.4`, `position: 0`) — the struct as a card; 400×300.
- [ ] Draw, render (Playwright), compare with agama-road, fix; set `art`; show it in guide 10's Engage.
- [ ] Commit `art: Agama with a rider card (Part 3)`.

### Task 5: Check, review, PR

- [ ] All checks; screenshot guide 13 (Elaborate) and lesson 15 (Fix it).
- [ ] Whole-branch review (opus) with this Review Focus; fix Important findings (tests first where code).
- [ ] PR with rulings and deferred items; after merge Pages redeploys.
