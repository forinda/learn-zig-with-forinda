# Foundation and Part 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The course site, its tooling and CI working end to end, with Part 1 (Start) written: three
lessons and their code steps, from installing Zig to reading compiler errors.

**Architecture:** A standalone clarusjs site (modelled on /home/forinda/dev/dwise/documentations) with one
`learn` section whose sidebar groups are the course's 13 parts; lessons use theme-docs' lesson layout
(one `##` step at a time, quizzes, local progress). Lesson code lives in `code/steps/NN-slug/`, each a
complete Zig 0.17 project; pages pull it in with `<<<` snippet includes so it can't drift. Scripts build
and test every step and generate each step's diff from the previous one.

**Tech Stack:** clarusjs 0.16.0, @clarusjs/theme-docs 0.5.0, @clarusjs/content 0.5.0, Tailwind 4.3.5,
Vite, Node (node:test), pnpm; Zig 0.17.0; GitHub Actions.

**Spec:** docs/superpowers/specs/2026-11-28-course-design.md (Repo layout, Lesson page shape, Teaching
frameworks, Curriculum Part 1, Calls made after the builder check).

This is plan 1 of 13 (one per part, one PR each). Later plans add a part each and reuse this foundation.

## Global Constraints

- Zig 0.17.0 exactly; every `build.zig.zon` has `.minimum_zig_version = "0.17.0"`.
- Every step folder is a complete project: `build.zig`, `build.zig.zon`, `src/`; `zig build run` and
  `zig build test` work in it; package name `.tour`, fingerprint `0x6ad1f969430a8a84` (valid for `.tour`).
- Game code on a page comes from its step folder via `<<< @/code/steps/...` (never retyped).
- Every lesson has the five 5E steps as `##` headings, in order: Engage, Explore, Explain, Elaborate,
  Evaluate; Evaluate holds at least one `::: quiz`, the step's test command and an exercise.
- Linux, macOS and Windows: CI builds and tests every step on all three.
- No AI attribution in commits or PRs.

## Review Focus

1. A reader who joins at lesson 3 by copying `code/steps/03-*` gets a project that builds and runs with only Zig 0.17 installed.
2. A step's code changes but the lesson page still shows the old code (must be impossible: snippet includes; the page test fails on fenced game code).
3. Windows: `zig build run` prints correctly in cmd/PowerShell (no ANSI in Part 1; plain text only).
4. The lesson flow works without JavaScript (the lesson layout falls back to a plain page) and with it (one step at a time, quiz Check).
5. A lesson missing a 5E heading, a quiz, a `step` folder or a listed competency fails `pnpm test`, not silently ships.

---

### Task 1: Site scaffold

**Files:** Create package.json, pnpm-workspace.yaml (none needed: single package), vite.config.ts,
tsconfig.json, .gitignore, .prettierrc, src/env.d.ts, src/groups.ts, src/sidebar.ts, src/nav.ts,
src/schemas.ts, src/layouts/docs.tscl, src/layouts/lesson.tscl, src/styles/docs.css,
src/styles/tailwind.css, public/diagrams.js, public/logo.svg, src/pages/index.md,
src/pages/learn/progress.tscl.

**Interfaces:**
- Produces: `groups.ts` exports `sections = { start: 'Start here', learn: 'Course' }` and
  `groups.learn` = the 13 parts in order, each `{ title, icon }` (icons from theme-docs 0.5.0's GroupIcon):
  Start (rocket), Basics (book), Structure (layers), Memory (box), Data structures (grid), A terminal game
  (terminal), Simulation (chart), AI (sparkles), File I/O (file), The build system (wrench), C libraries
  (code), Networking (message), Hero (shield). `groups.start` = `[{ title: 'Welcome', icon: 'rocket' }]`.
- Produces: `nav.ts` `theme: ThemeConfig` with `learn: { section: 'learn', progress: '/learn/progress' }`,
  brand "Zero to Hero" + accent " in Zig", search, viewTransitions.
- Produces: `schemas.ts` — `start/**/*.md` and `index.md`: title, description, group (from groups.start),
  order; `learn/**/*.md`: additionally `layout: /src/layouts/lesson.tscl`, `steps: true`, `minutes`
  (positive integer), `step` (string matching /^\d{2}-[a-z0-9-]+$/), `competency` (non-empty string).

- [ ] **Step 1:** Copy the dwise scaffold files listed above, adapting names (titles, llms summary, site
  url `http://localhost:5173`), pinning the same package versions as /home/forinda/dev/dwise/documentations
  package.json; vite.config.ts as dwise's plus `quiz: { tag: 'quiz', from: '@clarusjs/theme-docs/quiz.tscl' }`
  and `components: ['/src/components']`. `src/layouts/lesson.tscl` as kview's
  packages/docs/src/layouts/lesson.tscl (wraps `@clarusjs/theme-docs/lesson.tscl` with this site's theme).
  `progress.tscl` as kview's packages/docs/src/pages/learn/progress.tscl. `.gitignore` as dwise's except the `docs/superpowers/` line: keep
  `.superpowers/` ignored, but track `docs/superpowers/` (this repo's spec and plans live there).
- [ ] **Step 2:** `pnpm install && pnpm build` → Expected: build succeeds; `dist/client/index.html` exists.
- [ ] **Step 3:** `pnpm check` → Expected: no errors.
- [ ] **Step 4:** Commit `feat: site scaffold (clarusjs, theme-docs, learn section of 13 parts)`.

### Task 2: Step tooling

**Files:** Create scripts/check-steps.ts, scripts/diff-steps.ts, scripts/carry.ts,
scripts/steps.test.ts, code/README.md.

**Interfaces:**
- `check-steps.ts`: `node scripts/check-steps.ts [stepGlob]` — asserts `zig version` prints `0.17.0`,
  then for each `code/steps/*/` (sorted) runs `zig build` and `zig build test` there; prints one line per
  step (`ok 01-hello` / `FAIL 01-hello: <first error line>`); exit 1 on any failure. Exports
  `listSteps(root): string[]` (sorted folder names matching /^\d{2}-[a-z0-9-]+$/).
- `diff-steps.ts`: writes `code/diffs/NN-slug.diff` for every step after the first: `git diff --no-index
  --no-prefix` of `code/steps/<prev>/src` vs `code/steps/<this>/src` plus build.zig (empty file when
  identical); `--check` mode exits 1 if any committed diff is stale. Lessons include it with
  `<<< @/code/diffs/NN-slug.diff`.
- `carry.ts`: `node scripts/carry.ts <fromStep> <patchFile>` — `git apply` the patch inside every step
  after `fromStep`, then run check-steps on those; stops at the first step it doesn't apply to and names it.
- `steps.test.ts` (node:test): listSteps sorts and filters names; diff-steps on a two-step fixture
  (scripts/fixtures/steps/01-a, 02-b) produces a diff containing the changed line; `--check` fails when the
  fixture diff is edited.

- [ ] **Step 1:** Write steps.test.ts with the three tests and the fixture; `node --test scripts/` → Expected: FAIL (modules missing).
- [ ] **Step 2:** Implement the three scripts (Node built-ins only: child_process, fs, path).
- [ ] **Step 3:** `node --test scripts/` → Expected: PASS. Add `"test": "node --test tests/ scripts/"`, `"steps": "node scripts/check-steps.ts"`, `"diffs": "node scripts/diff-steps.ts"` to package.json.
- [ ] **Step 4:** Commit `feat: step tooling (check, diff, carry)`.

### Task 3: Page rules

**Files:** Create tests/pages.test.ts, src/course.ts.

**Interfaces:**
- `src/course.ts`: `export const parts: { slug: string; title: string; summary: string; competencies: string[] }[]`
  — 13 entries, titles equal to `groups.learn` titles in order; slugs `start, basics, structure, memory,
  data-structures, terminal-game, simulation, ai, file-io, build-system, c-libraries, networking, hero`;
  competencies as "I can ..." statements (Part 1's: "I can install Zig 0.17 and check its version", "I can
  create, build, run and test a Zig project", "I can read a compiler error and fix the code it points to";
  later parts: written by their plans, at least one placeholder each now).
- Lessons live in `src/pages/learn/<part slug>/NN-slug.md`.

Tests (`pnpm test`):
- `every lesson's group is a part and its folder matches the part's slug`
- `every lesson has the 5E steps in order` (## Engage, ## Explore, ## Explain, ## Elaborate, ## Evaluate; other `##` headings fail)
- `every lesson's Evaluate has a quiz, a zig build test command and an exercise` (a `::: quiz`, a line containing `zig build test`, a `### Exercise` heading)
- `every lesson's step folder exists` (code/steps/<step>)
- `every lesson's competency is listed for its part in src/course.ts`
- `game code comes from the step folder` (no fenced ```zig block longer than 15 lines in a lesson; longer code must be a `<<<` include)
- `lessons are ordered without gaps within a part` (orders 1..n)

- [ ] **Step 1:** Write the tests plus one deliberately broken lesson fixture under tests/fixtures/ that each rule rejects (the tests run their checks on src/pages and on the fixtures, expecting the fixtures to fail); `pnpm test` → Expected: FAIL (no course.ts yet).
- [ ] **Step 2:** Write src/course.ts; `pnpm test` → Expected: PASS (no lessons yet; fixture checks fail as intended).
- [ ] **Step 3:** Commit `test: page rules (5E steps, quiz, step folder, competency, no retyped game code)`.

### Task 4: Home, how the course works, course map

**Files:** Create src/components/course-map.tscl, src/pages/index.md, src/pages/start/how-it-works.md,
src/pages/start/set-up.md.

**Interfaces:** `<courseMap />` renders `parts` from src/course.ts: per part, its title, summary, its "I
can" list and a link to its first lesson (from `virtual:theme-docs/pages`: the first page in the part's
group by order; "Coming soon" when none).

- [ ] **Step 1:** index.md: what you'll build (Terminal Tour, a screenshot-style ```text block of the finished game), who it's for (zero programming), `<courseMap />`, start link.
- [ ] **Step 2:** how-it-works.md: the 5E steps and what each asks of you; I do / we do / you do; steps folders (copy `code/steps/NN-*` or clone the repo; each runs on its own); quizzes, XP and progress stay in your browser; a ```mermaid flowchart of a lesson.
- [ ] **Step 3:** set-up.md: install Zig 0.17.0 per OS (Linux tarball, macOS tarball/Homebrew if 0.17, Windows zip + PATH), `zig version`, an editor with ZLS (optional); a ::: tip about pinning 0.17.
- [ ] **Step 4:** `pnpm build && pnpm test` → Expected: PASS. Commit `feat: home, how the course works, set-up, course map`.

### Task 5: Part 1 code steps

**Files:** Create code/steps/01-hello/, code/steps/02-first-test/, code/steps/03-race-card/ (each
build.zig, build.zig.zon, src/main.zig), code/broken/03-race-card/{a,b,c}.zig.

Shared `build.zig` (all three steps; verified on 0.17.0):

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize });
    const exe = b.addExecutable(.{ .name = "tour", .root_module = mod });
    b.installArtifact(exe);
    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    b.step("run", "Run the game").dependOn(&run.step);
    const tests = b.addTest(.{ .root_module = mod });
    b.step("test", "Run the tests").dependOn(&b.addRunArtifact(tests).step);
}
```

`build.zig.zon`: `.name = .tour`, `.version = "0.1.0"`, `.minimum_zig_version = "0.17.0"`,
`.paths = .{ "build.zig", "build.zig.zon", "src" }`, `.fingerprint = 0x6ad1f969430a8a84`.

- **01-hello:** `main(init: std.process.Init)` prints `Terminal Tour` through `std.Io.File.Writer.init(.stdout(), init.io, &buf)` and flushes. No tests yet (`zig build test` runs zero tests and passes).
- **02-first-test:** `fn title() []const u8` returns "Terminal Tour"; main prints it; `test "the game has a title"` with `expectEqualStrings`.
- **03-race-card:** constants for the first race (`course_name = "Compile Pass"`, `distance_km: f64 = 12.5`, `riders: u32 = 8`); `fn raceCard(w: *std.Io.Writer) !void` prints a bordered card (title, course, distance with one decimal, riders); tests: `test "race card lists the course, distance and riders"` writing into `std.Io.Writer.fixed(&buf)` and checking `buf` contains "Compile Pass", "12.5 km", "8 riders".
- **code/broken/03-race-card/a.zig, b.zig, c.zig:** three single-file programs, each with one classic error for lesson 3's Explore: (a) an unused local constant, (b) a type mismatch (`const riders: u32 = 8.5`), (c) a missing `try` on an error union. Each has a comment at the top saying how to run it (`zig run a.zig`) — CI does NOT build code/broken.

- [ ] **Step 1:** For 02 and 03, write the test first, run `zig build test` → Expected: FAIL (function missing); implement; → PASS.
- [ ] **Step 2:** `node scripts/check-steps.ts` → Expected: `ok` for 01, 02, 03. `node scripts/diff-steps.ts` writes code/diffs/02-first-test.diff and 03-race-card.diff.
- [ ] **Step 3:** For each broken file, `zig run code/broken/03-race-card/<x>.zig` → Expected: a compile error (a: "unused local constant", b: "fractional component", c: "error union is ignored"); record the exact first error line in the lesson.
- [ ] **Step 4:** Commit `feat(code): Part 1 steps (hello, first test, race card) and broken programs`.

### Task 6: Part 1 lessons

**Files:** Create src/pages/learn/start/01-install-and-hello.md, 02-build-run-test.md,
03-reading-compiler-errors.md.

Frontmatter (each): title, description, group "Start", order 1..3, layout /src/layouts/lesson.tscl,
steps: true, minutes (10–20), step (01-hello / 02-first-test / 03-race-card), competency (Part 1's three,
in order).

Content per lesson, in the 5E steps (each concept also shown as output text and, where it helps, a
```mermaid diagram; small Zig examples ≤ 15 lines may be fenced, game code via `<<<`):
- **01 Install Zig and say hello:** Engage: the game you'll build, and that it starts as one line of text.
  Explore: `zig version`, `zig init` in an empty folder, look at what it made. Explain: what a program,
  `main` and `std` are; printing through a writer and why it flushes. Elaborate: replace main with
  `<<< @/code/steps/01-hello/src/main.zig`, `zig build run` → "Terminal Tour". Evaluate: quiz (what flush
  does), `zig build test` (no tests yet: what that means), exercise: print your own name under the title.
- **02 Build, run and test:** Engage: how do you know the title is still right after you change
  something? Explore: run `zig build --help`, find run and test. Explain: build.zig in one picture
  (mermaid: build graph: exe, run, test), what a test block is. Elaborate: `<<< @/code/diffs/02-first-test.diff`
  then the full main.zig; `zig build test` passes; break the title and watch it fail. Evaluate: quiz (which
  command runs tests), exercise: add a test for a second function `subtitle()`.
- **03 Reading compiler errors:** Engage: the compiler as a coach, not a judge. Explore: run the three
  broken programs (code/broken), read each first line. Explain: anatomy of an error (file:line:col, the
  message, the note), the three errors you'll meet most. Elaborate: build the race card
  (`<<< @/code/diffs/03-race-card.diff`), `zig build run` output shown as ```text. Evaluate: quiz (what
  "error union is ignored" asks of you), `zig build test`, exercise (Bloom create, Part 1's end task):
  design your own race card for a race you know, with its own test.

- [ ] **Step 1:** Write the three lessons; `pnpm test` → Expected: PASS (all page rules). `pnpm build` → Expected: PASS; open `pnpm preview` and check one lesson shows one step at a time and a quiz checks.
- [ ] **Step 2:** Commit `feat(learn): Part 1 lessons (install and hello, build run test, compiler errors)`.

### Task 7: CI

**Files:** Create .github/workflows/ci.yml.

- `steps` job: matrix `ubuntu-latest, macos-latest, windows-latest`; `mlugg/setup-zig@v2` with
  `version: 0.17.0`; `actions/setup-node` (Node 24); `node scripts/check-steps.ts` and
  `node scripts/diff-steps.ts --check`.
- `site` job: ubuntu; pnpm (version from package.json `packageManager`); `pnpm install --frozen-lockfile`,
  `pnpm test`, `pnpm check`, `pnpm build`.

- [ ] **Step 1:** Write the workflow; validate locally with `node scripts/check-steps.ts && node scripts/diff-steps.ts --check && pnpm test && pnpm check && pnpm build` → Expected: all pass.
- [ ] **Step 2:** Commit `ci: build and test every step on Linux, macOS and Windows; build the site`.

### Task 8: Check, review, PR

- [ ] Screenshots of the home page, a lesson step, and a quiz (pnpm preview; browser automation or Playwright).
- [ ] Whole-branch review (opus); fix Important findings with TDD.
- [ ] The repo has no remote yet: ask Felix to create it (or approve creating `forinda/forinda-zig-learn`) before pushing; then PR with rulings and deferred minors.

## Syntax highlighting

`@clarusjs/content` 0.5.0 doesn't highlight Zig or C. Felix is adding Zig upstream (kview packages/content);
until that release, Zig code renders as plain text. When it ships: bump `@clarusjs/content` here and
check one lesson's Zig block is highlighted (C too, if it lands, for Part 11).
