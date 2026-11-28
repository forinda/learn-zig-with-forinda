# Zero to Hero in Zig: build a racing game — course design

## Intent

A curated course that takes a reader from zero programming to confident Zig ("hero") by building one
game: a terminal cycling race. Every concept is taught where the game needs it, from values and loops to
memory, simulation, AI, file I/O, C libraries and networking. The concepts come from Fornai (Felix's Zig +
raylib game, /home/forinda/dev/pers/forinda-fun-club): the course is its ideas, re-taught from scratch in a
smaller game, not a tour of Fornai's code.

**Why:** Felix wants a structured course from simplest to advanced that ends with a complete CLI game.

## Goals

- Zero to hero: lesson 1 assumes no programming; the last parts reach comptime, profiling, data-oriented
  design and releases.
- One game that grows: every lesson adds a step to the same terminal game.
- Covers, explicitly: file I/O, working with C libraries, networking.
- Every step of the game builds and passes its tests on Zig 0.17, and readers can join at any lesson.

## Non-goals

- Running Zig in the browser (no playground, no WASM runner). Readers copy or clone and run locally.
- A tour of Fornai's codebase, or reusing its code wholesale (ideas, not files).
- 3D graphics as part of the core path (raylib is an optional bonus at the end).

## Anti-goals

- Lessons that only work if you followed every earlier one exactly (each step folder stands alone).
- Code on a page that differs from the code in the step folder.
- Concepts taught in a vacuum: each one changes the game.

## Constraints

- Zig 0.17 (the version Fornai uses); every code step pinned to it.
- Site: a standalone clarusjs repo modelled on /home/forinda/dev/dwise/documentations (published packages
  `clarusjs` 0.16, `@clarusjs/theme-docs` 0.5, `@clarusjs/content` 0.5, Tailwind 4; `groups.ts` sections and
  sidebar groups in order, `schemas.ts` frontmatter checked at build time, ```mermaid diagrams, callouts,
  `node --test` page rules).
- Linux, macOS and Windows terminals (ANSI escapes; Windows: enable virtual terminal processing).
- Code works without system packages: C sources are vendored and compiled by `build.zig`.

## Approaches considered

- A. Code on the pages only — cheapest, but drifts and strands readers who fall behind.
- **B. Companion code: one complete project per lesson step (chosen by Felix).** The site shows each
  step's code and what changed from the previous step; readers copy or clone and run locally.
- C. Separate exercises per lesson plus a separate capstone — cleaner concepts, but no growing game and
  twice the code.

## Design

### Repo layout (my call)

```
forinda-zig-learn/
  package.json, vite.config.ts, ...    the site (as dwise/documentations)
  src/pages/<part>/*.md                lessons
  src/groups.ts, src/schemas.ts        parts and groups; frontmatter rules (incl. `step`)
  code/steps/NN-slug/                  one complete Zig project per step: build.zig, src/, tests
  code/solutions/NN-slug/              exercise solutions (where an exercise isn't the next step)
  scripts/check-steps.ts               builds and tests every step with Zig 0.17 (CI)
  tests/                               page rules: every lesson's `step` exists; snippets match files
```

### Lesson page shape

Lessons use theme-docs' lesson components (in the published `@clarusjs/theme-docs` 0.5.0, as on
clarusjs.com's Learn pages, kview packages/docs/src/pages/learn): the lesson layout (`lesson.tscl`: one
step at a time, "Lesson n of N", an action bar), `::: quiz` blocks (`quiz.tscl`/`quiz-choices.tscl`, the
bar's Check), and local progress (`progress.ts`: steps seen, lessons done, first quiz answers; XP and
badges computed, nothing leaves the browser) with `learn-path`/`progress-board` on the part pages.

Frontmatter: `title`, `description`, `group`, `order`, `layout` (the lesson layout), `steps: true`,
`minutes`, `step` (the code/steps folder it pairs with) and `competency` (the "I can ..." it builds).
Code on the page is included from the step folder (or checked against it by a page test) so it can't drift.

### Teaching frameworks (Felix: "use the learning framework")

- **Backward Design** plans every part and lesson: the competency first (an "I can ..." statement), then
  the evidence that shows it (the step's tests and the exercise), then the activities.
- **5E** is the shape of every lesson, one `##` step each in the lesson layout:
  **Engage** (a problem in the game: "the race forgets your results when you quit"),
  **Explore** (run the current step, poke at it, see the gap or the failure),
  **Explain** (the concept: prose, a small example, a diagram),
  **Elaborate** (apply it to the game: the step's change, with the diff from the previous step),
  **Evaluate** (a `::: quiz`, the step's tests, the exercise).
- **Gradual release (I do, we do, you do)** inside Explain and Elaborate: a worked example (I do), building
  the game step together with the code shown (we do), the exercise done alone with a hint and a solution
  (you do).
- **Bloom's taxonomy** orders the checks: quizzes for remember/understand; exercises for apply/analyse
  (read a compiler error, explain why a test fails); each part ends with an evaluate/create task (compare
  two approaches; add your own AI tactic, save format, or protocol message).
- **UDL**: each concept in several forms (prose, a ```mermaid diagram, code, the terminal output you should
  see); exercises accept more than one solution ("your own variant"); `minutes` and local progress let
  readers go at their own pace.
- **Competencies (CBC style)**: each part page opens with its "I can ..." list (from the lessons'
  `competency`), shown on the part page with the learn path and progress board.

### The game

"Terminal Tour": a text cycling race. You ride with keys (power up/down, sprint, sit in), AI rivals race,
a break goes, the bunch chases, sprint for the line; results and a feed of what happened; a career saved
to disk; personal bests in SQLite; race friends over the network. Optional bonus: the same game in a raylib
window (the renderer swapped, the game code unchanged).

### Curriculum (parts → lessons; each lesson adds a step)

1. **Start** — install Zig 0.17, `zig init`, `zig build run`, reading compiler errors.
2. **Basics** — values and types, control flow, functions, arrays and slices, strings as `[]const u8`,
   printing; the game: a rider that moves along a line, printed each second.
3. **Structure** — structs and methods, enums, tagged unions, optionals, errors and `try`, tests;
   the game: Rider, Course, Race types; a course of segments with gradients.
4. **Memory** — stack vs heap, allocators, `defer`/`errdefer`, ArrayList, HashMap, leak-checking tests;
   the game: a field of riders, read course lengths at runtime.
5. **Data structures and algorithms** — arrays/slices and ArrayList (a fixed-capacity field vs a growable
   one), HashMap/StringHashMap (names to ids, personal bests), a ring buffer (the race feed), stack and
   queue (menu undo, queued network inputs), `std.PriorityQueue` (race events in distance order), sorting
   (stable vs not; insertion sort on nearly sorted data: ordering the field each tick), binary search (which
   course segment you're on), bitsets/`EnumSet`, intrusive linked lists (when they pay off, why the game
   mostly uses arrays), graphs with BFS and Dijkstra (the course map: junctions, shortest route, a loop for
   a circuit), big-O by measuring (sort every tick vs keep it sorted); the game: the field, results,
   feed and course map on the right structures.
6. **A terminal game** — reading keys (raw mode), drawing frames with ANSI escapes, a fixed-timestep loop;
   the game: playable — your rider, keys for power, a live HUD.
7. **Simulation** — forces (aero, rolling, gravity), speed from power, drafting, W' energy, seeded
   randomness, determinism tests; the game: real riding physics and fatigue.
8. **AI** — intents, wheel following, groups by time gaps, a race director (break, chase, finale), an
   event feed; the game: races that unfold.
9. **File I/O** — files and directories, readers/writers, JSON with std.json, save versions and
   migrations, atomic writes, loading course files; the game: a career that persists.
10. **The build system** — how `build.zig` works (the build graph, steps, artifacts; `run`, `test`,
    `install`), options (`-D`, optimize modes, game flags like `-Dseed`/`-Dlog`), several executables from
    one project (the game, a race-stats tool, later the network server), modules and imports (split the
    game into `sim`, `game`, `term`), embedding and generating files at build time (`@embedFile`, a
    generated lookup table), dependencies in `build.zig.zon` (pinned hashes, `zig fetch`, the cache),
    cross-compiling (`-Dtarget`), custom steps (`zig build check`, `zig build release`); the game: a stats
    tool beside the game, embedded course files, release builds for three OSes, ready for C in Part 11.
11. **C libraries** — `@cImport`/translate-c, C types in Zig, linking system libraries, vendoring and
   compiling C sources in build.zig, ownership across the boundary, wrapping a C API in idiomatic Zig;
   the game: SQLite (vendored amalgamation) for results, personal bests and a leaderboard.
12. **Networking** — TCP sockets, a server and clients, framing a message protocol, lockstep simulation
    over the network, timeouts and disconnects; the game: race friends on your LAN.
13. **Hero** — comptime and generics, profiling, data-oriented design, shipping a release;
    optional bonus: swap the terminal renderer for raylib.

Roughly 4–6 lessons per part (about 65 lessons); exact lesson split is the builder's.

### Fornai concepts mapped (what the course re-teaches)

Fixed timestep (DT 0.1 s) and determinism tests; the force model and draft; W' and pacing; input
response (deadzones, curves, ramps); seeded generation of courses; AI intents and team tactics;
groups by gaps; the director (break window, allowed gap, rotation, lead-out); points and the event feed;
fast-forward; saves with migrations; keeping the renderer behind one module.

## Left to the builder

Lesson split within parts, exact step names, exercise wording, the site's landing page and theme,
diagram choices, how snippets are included (include directive vs checked copies) as long as drift fails a
test.

## Calls made after the builder check (Felix can override)

- **CI platforms:** every step builds and runs its tests on Linux, macOS and Windows (GitHub Actions
  matrix). Lessons teach the Windows path where it differs (raw-mode keys and virtual terminal processing in
  Part 6, sockets in Part 12) as a short side section, not a separate track.
- **Keeping steps in sync:** step folders are complete copies edited by hand; `scripts/check-steps.ts`
  builds and tests all of them, page tests check every snippet against its step file, and
  `scripts/diff-steps.ts` generates each lesson's "what changed" from step N-1 to N. A fix that must flow
  forward is applied with `scripts/carry.ts <step> <patch>` (applies the same patch to every later step and
  re-runs their tests).
- **SQLite:** a pinned `build.zig.zon` dependency (the official amalgamation tarball, hash-pinned), fetched
  once into Zig's cache, the way Fornai fetches raylib. Nothing in the repo per step; no system packages.
  Part 11 teaches both: compiling vendored C sources (a tiny C library in the step folder) and depending on
  a pinned C package.
- **Network play:** two or more humans, each in their own terminal, with the AI field simulated identically
  on every machine (lockstep: peers exchange only inputs). Peers may run different operating systems and
  CPUs, so from Part 7 the simulation is deterministic across targets: fixed timestep, seeded `std.Random`,
  no `@mulAdd`/fast-math, math from Zig's std (not libc). Part 7's determinism test runs the same race on
  each CI platform and compares a fingerprint against one checked-in value.
- **Scope (Felix: "no priority, just nailing the course head-on"):** the whole course is the deliverable,
  all 13 parts, built properly rather than a thin first slice. Built in part order (each part depends on
  the game from the parts before it), one PR per part so each gets a review; the site and tooling land with
  Part 1.

## Decided (Felix, 2026-11-28): teach in the Guide, check in the Course

The teaching moves to a **Guide** section of ordinary docs pages (code inline in the text column, more room):
one page per concept, grouped by the 13 parts, with Engage, Explore, Explain and Elaborate as its `##`
sections, its `step`, and a "Check your understanding →" link to its lesson. The **Course** lessons (lesson
layout, one step at a time, XP) test understanding instead of re-teaching: "Read first" links to the guide
page, then `##` steps up Bloom's levels: **Recall** (quick quizzes), **Predict** (what a short snippet prints
or which error it gives), **Fix it** (choose the fix for a broken snippet), **Build it** (the step's
exercise, `zig build test`), and **Stretch** (the part's create task, in a part's last lesson). Page rules
enforce both shapes. Parts 1 and 2 are reworked to it; later parts follow it.

## Decided (Felix, 2026-11-28): copyable code, not diffs

Diffs confuse readers and can't be pasted into a file. A guide page's Elaborate shows each new piece as plain,
copyable code from a named region of its step's source (`<<< @/code/steps/NN-*/src/main.zig#name`, regions
marked `// #region name` … `// #endregion name`), with where it goes, and ends with the whole file after the
step in a collapsed section. `code/diffs/` and its CI check are removed; `scripts/carry.ts` stays.

## Decided (Felix, 2026-11-28): guide pages teach the concept, headings name it

Guide pages don't label the teaching steps. Headings name the Zig concept and its forms (a page on loops covers
`while`, the continue expression, `for` with index/pointers/several lists/ranges, `break`/`continue`/labels, loops
as values, iterators, and "which loop when" with the consequences of the wrong choice), each with a short,
verified example tied to the game, "Try it" tips, and the real errors. Then **In the game**: the step's new code
from its regions with where it goes, and the whole file, visible. A collapsed diff at the very bottom is only for
comparing (generated, region markers stripped). Model: src/pages/guide/basics/06-loops.md.

## Decided (Felix, 2026-11-28): data structures and algorithms together

Part 5 is "Data structures and algorithms": the planned structures plus prefix sums and sliding windows, searching
text (with word wrap), edit distance (dynamic programming) and tries, ten steps (22–31). Merge sort by hand goes in
the sorting page. UTF-8 and a hand-written lexer go to Part 9 (File I/O), bunching riders to Part 8, shuffling to
Part 7. Topological sort was first sent to Part 10, then added to Part 5 as step 32 (Felix): a season of
courses that unlock after others; Part 10 can point back to it for the build graph.
