# Part 4: Memory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (Felix: the work is done in-session, no subagents). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Part 4 of the course: the game starts talking to the player (reading what they type, stdout vs stderr,
positional and named formatting), and the player's input is what makes memory matter: a name of any length, a
field of any size, results kept across races. Six concepts, each a Guide page and a Course lesson: terminal input
and output, the stack and the heap (allocators), `defer` and `errdefer`, `ArrayList`, hash maps, finding leaks.

**Architecture:** As Part 3, in the shape Felix approved: guide pages `src/pages/guide/memory/16-..21-*.md`
taught concept-first (headings name the concept, all its variations, a "which X when" table with what goes wrong,
`## In the game` last with region includes, the run output and the whole file, the diff collapsed at the end);
lessons `src/pages/learn/memory/16-..21-*.md` (Recall, Predict, Fix it, Build it; Stretch in 21); code steps
`code/steps/16-..21-`, each a copy of the previous step, changed only by its lesson; one illustration.

**Tech Stack:** Zig 0.17.0; the course site (clarusjs 0.16, theme-docs 0.5).

**Spec:** docs/superpowers/specs/2026-11-28-course-design.md (Curriculum Part 4; the three "Decided" sections).

Plan 4 of 13.

## Global Constraints

- Zig 0.17.0; every step builds, tests and runs (`pnpm steps`); `pnpm diffs --check`; `pnpm test`; `pnpm build`; `pnpm check`.
- `check-steps` runs `zig build run` with **empty stdin**: from step 16 on, end of input must fall back to defaults
  (player "you", rider A, one race) and the race still prints.
- Generic programming names; riders are letters A..H; units in names (`_m`, `_s`, `_mps`, `_pct`).
- Every snippet, error, panic and wrong quiz option is run on 0.17 and quoted verbatim.
- Diagrams narrow (top-to-bottom, ≤ 5 boxes a row), short labels. Zig blocks on guide pages ≤ 15 lines.
- Drawing order on the road stays: field, then you, then the leader.
- No AI attribution in commits or PRs.

## Verified 0.17 facts (from the planning probe)

- stdin: `var r: std.Io.File.Reader = .init(.stdin(), init.io, &buf); r.interface.takeDelimiter('\n')` →
  `error{ReadFailed, StreamTooLong}!?[]u8`: `null` at end of input, `StreamTooLong` when the line outgrows `buf`.
- stderr writer: `std.Io.File.Writer.init(.stderr(), init.io, &buf)`, flushed like stdout.
- Positional `{0s} ... {0s} {1d}` and named `{[who]s} {[speed]d:.1}` with `.{ .who = ..., .speed = ... }` work.
- A line of any length: `std.Io.Writer.Allocating.init(gpa)`, `streamDelimiter(&line.writer, '\n')`, `line.written()`, `defer line.deinit()`.
- `std.process.Init` has `gpa` (leak-checked in debug: `error(SafeAllocator): leaked [...] allocated at:`) and `arena`.
- `std.testing.allocator` leaks fail the test run (`+- run test 1 pass (1 total); 1 leaks`; `zig test` exits 1).
- `std.ArrayList(T)` is unmanaged: `.empty`, `append(gpa, x)`, `items`, `deinit(gpa)`.
  `std.StringHashMapUnmanaged(V)`: `.empty`, `put`, `get` (optional), `getOrPut` → `value_ptr`, `deinit(gpa)`.
- `std.testing.checkAllAllocationFailures` and `std.testing.FailingAllocator` exist.

## Review Focus

1. Empty stdin and EOF mid-question: every prompt has a default, and the step still prints a whole race under `check-steps`.
2. Input with `\r\n` (Windows terminals) and surrounding spaces: names and choices are trimmed; a test covers `"B\r"`.
3. Every allocation in steps 17–21 has its `defer`/`errdefer`, and every test that allocates uses `std.testing.allocator` (a leak fails it).
4. A partially built field (an allocation fails halfway) frees what it made: `checkAllAllocationFailures` test in step 18.
5. Map keys outlive the map's use: names stored as keys are owned copies (not slices of a reused line buffer); a test reads a key after the buffer is overwritten.

---

### Task 1: Code steps 16–21

**Files:** code/steps/16-terminal-io … 21-leaks; code/diffs (generated). Tests first in each step (RED), then
implement (GREEN); copy each `zig build run` output (with and without input) for the guide.

- **16-terminal-io** — read from stdin with a fixed 64-byte buffer. `fn askLine(in: *std.Io.Reader, out: *std.Io.Writer, question: []const u8) !?[]const u8` (prints the question, flushes, `takeDelimiter`, trims `" \r\t"`; `null` at EOF). `fn pickRider(answer: ?[]const u8) u8` ('A'..'H', case-insensitive, anything else → 'A'). Main asks "Which rider are you (A-H)?"; the road draws that rider where it drew A; the ending says `you ({c}) were ...`. Problems (an answer too long: `StreamTooLong`) go to a **stderr** writer as `note: ...` and fall back to the default. The race card uses a named-argument print. Tests: `pickRider` on `"b"`, `"B\r"` trimmed upstream (test `askLine` with a `std.Io.Reader.fixed("  c \r\n")`), `"Z"`, `null`; askLine returns `null` on empty input.
- **17-allocators** — the player's name, any length: `fn askLineAlloc(gpa: std.mem.Allocator, in: *std.Io.Reader, out: *std.Io.Writer, question: []const u8) !?[]u8` with `std.Io.Writer.Allocating` (caller frees); main uses `init.gpa` and `defer gpa.free(name)`; the result line greets the player by name (`{0s} ...{0s}` positional). Tests with `std.testing.allocator`: a 200-byte name comes back whole; `null` at EOF allocates nothing.
- **18-defer-errdefer** — the field from a roster text (`const roster_text = \\ A 10.0 6.2 Ada ...`, eight lines): `fn loadField(gpa, text) ![]Rider` allocates the riders and each rider's owned `full_name` (`Rider` gains `full_name: []const u8 = ""`); `errdefer` frees what was made when a later line fails; `fn freeField(gpa, field)`. `Race.init` takes the field slice (≤ 8 for now, `error.TooManyRiders`). Tests: loads eight; a bad line is an error and leaks nothing; `checkAllAllocationFailures` over `loadField`.
- **19-arraylist** — the field size comes from the roster, any length: riders in `std.ArrayList(Rider)`; `Race` holds `riders: []Rider` (no `[8]Rider`), `parseCourse` appends segments to an `ArrayList(Segment)` (no fixed buffer, no `TooManySegments`). `drawRoad` unchanged. Tests: a 12-rider roster races; parseCourse of 20 segments; `toOwnedSlice` hands ownership out.
- **20-hashmap** — race again: after each race ask "Race again? (y/n)" (EOF → no); wins per rider name kept in `std.StringHashMapUnmanaged(u32)` (`getOrPut`), keys owned (`gpa.dupe`); a standings table printed sorted by wins (sort an `ArrayList` of entries, `std.mem.sort`). Tests: two wins for the same name count 2; a key still reads correctly after the line buffer it came from is reused; unknown name → `null`.
- **21-leaks** — per-race scratch in an `std.heap.ArenaAllocator` (events, the road text), freed in one `deinit` per race; long-lived things (names, standings) on `gpa`. Tests: a whole race run under `std.testing.allocator` leaks nothing; the guide shows a deliberately leaking test's real output.

- [ ] Steps 16–21 in order, each RED then GREEN, real output captured (piped input and empty stdin).
- [ ] `node scripts/check-steps.ts` → ok 01–21; `node scripts/diff-steps.ts`; read each diff: only its lesson.
- [ ] Commit `feat(code): Part 4 steps (terminal io, allocators, defer/errdefer, ArrayList, hash maps, leaks)`.

### Task 2: Guide pages 16–21

**Files:** src/pages/guide/memory/16-talking-to-the-terminal.md, 17-the-stack-and-the-heap.md,
18-defer-and-errdefer.md, 19-lists-that-grow.md, 20-hash-maps.md, 21-finding-leaks.md. Frontmatter group
"Memory", order 1..6, `step` 16..21. Shape as guide/basics/06-loops.md.

- **16 Talking to the terminal:** stdin, stdout, stderr (what each is for; `2>` and `>` and `|` to show them apart); readers and writers with buffers; reading a line (`takeDelimiter`: the line, `null` at end, `StreamTooLong`); trimming `\r`; prompts must flush before reading; when to `std.debug.print` vs the stderr writer; formatting in full: positional `{0}`, named `{[name]}`, width and precision from arguments (`{d:[w]}` if verified), escaping braces `{{ }}`; which stream when.
- **17 The stack and the heap:** lifetimes (a local's memory ends with its function: returning a slice of a local array, shown with the real result), fixed buffers vs allocation, `std.mem.Allocator` (alloc/free, create/destroy, dupe), who owns what (the caller frees), passing the allocator in, `init.gpa` and the leak report at exit; which memory when.
- **18 defer and errdefer:** defer order (last in, first out), defer in loops and blocks, errdefer only on the error path, freeing a partly built list, `checkAllAllocationFailures`; table of cleanup forms.
- **19 Lists that grow:** `ArrayList` (unmanaged: the allocator on each call), append, items, capacity vs length, `ensureTotalCapacity`, `toOwnedSlice`, a pointer into a list going stale after it grows (shown); arrays vs slices vs ArrayList.
- **20 Hash maps:** key → value, `put`/`get`/`getOrPut`/`remove`/iterate, string keys and owning them, `AutoHashMap` vs `StringHashMap`, iteration order isn't sorted; map vs list.
- **21 Finding leaks:** `std.testing.allocator` and the leak report, the gpa at exit, arenas (one free for many allocations), which allocator when (gpa, arena, fixed buffer, testing).
- Also: guide/start/03's formatting table gains one row pointing to positional and named arguments on page 16.

- [ ] Write; every snippet run on 0.17; gcheck ok for 16–21.

### Task 3: Lessons 16–21

**Files:** src/pages/learn/memory/16-..21-*.md (names as the guide pages).

Competencies (course.ts gains the first): 16 "I can read what the player types and write to stdout and stderr";
17, 21 "I can choose between the stack and an allocator"; 18, 19, 20 "I can free what I allocate with defer and
errdefer"; 21 also exercises "I can find a memory leak with a test" (its competency field: that one).

- Exercises: 16 ask "How many km? (default 12.5)" and parse it with `parseFloat`, falling back on bad input with a note on stderr; 17 `askLineAlloc` limited to 1 KiB (`StreamTooLong` past it); 18 a `team` name per rider in the roster, owned and freed; 19 `Race.dropRider(name)` removing a rider with `orderedRemove`; 20 count podium places (top 3) per name, not just wins; 21 find and fix a planted leak in a given function using a failing test.
- Stretch (21, Part 4's create task): a season: the player picks how many races, standings carry across them, everything allocated is freed, and a test proves a three-race season leaks nothing.

- [ ] Write; every snippet run on 0.17; `pnpm test` → PASS (guide, lesson, pairing, stretch rules); `pnpm build` → PASS.
- [ ] Commit `feat: Part 4 guide pages and lessons`.

### Task 4: Part 4 art

**Files:** public/art/agama-memory.svg; src/course.ts (`art` for Memory, summary mentions the terminal, the new competency).

- Agama typing at a terminal that shows a prompt `Which rider are you (A-H)? H_`, beside a stack of boxes (memory); 400×300, chibi style as agama-structure.
- [ ] Draw, render (Playwright), compare with agama-structure, fix; set `art`; show it on guide 16.
- [ ] Commit `art: Agama at the terminal (Part 4)`.

### Task 5: Check and PR

- [ ] All checks; screenshots of guide 16 (In the game) and lesson 21 (Stretch).
- [ ] Self-review against the Review Focus (no review agent unless Felix asks); fix what it finds, tests first.
- [ ] PR with rulings and deferred items; after merge Pages redeploys.
