# Part 5: Data Structures and Algorithms Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (Felix: in-session, no subagents). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Part 5 of the course: the data structures and algorithms the race needs, each where it earns its place:
a ring buffer (the race feed), queues and a priority queue (course marks in distance order), sorting (the field in
race order every second, measured), binary search (which segment a rider is on), bit sets and enum sets (who has
finished, what terrain a course has), and graphs (a course map, BFS and Dijkstra); and the algorithms that go
with them (Felix: "data structures and algorithms go hand in hand"): prefix sums and sliding windows (metres
climbed, the fastest kilometre), searching text and word wrap (the feed), edit distance and dynamic programming
("did you mean climb?"), and tries (rider-name completion). ArrayList and hash maps were Part 4. Ten steps, 22–31.

**Architecture:** As Part 4: guide pages `src/pages/guide/data-structures/22-..31-*.md` concept-first (variations,
a "which X when" table with consequences, `## In the game` last with region includes, run output, the whole file,
the diff collapsed); lessons `src/pages/learn/data-structures/22-..31-*.md` (Recall, Predict, Fix it, Build it;
Stretch in 31); code steps `code/steps/22-..31-`, each a copy of the previous one changed only by its lesson; one
illustration.

**Tech Stack:** Zig 0.17.0; the course site (clarusjs 0.16, theme-docs 0.5).

**Spec:** docs/superpowers/specs/2026-11-28-course-design.md (Curriculum Part 5; the "Decided" sections).

Plan 5 of 13.

## Global Constraints

- Zig 0.17.0; every step builds, tests and runs (`pnpm steps`), with empty stdin (one race, defaults); `pnpm diffs --check`; `pnpm test`; `pnpm build`; `pnpm check`.
- Every snippet, error, panic, timing and wrong quiz option run on 0.17 and quoted verbatim; timings say what machine and build mode and are shown as orders of magnitude, not promises.
- Zig blocks on guide pages ≤ 15 lines; diagrams narrow; generic programming names; units in names.
- Every test that allocates uses `std.testing.allocator`; per-race memory stays in the race's arena.
- No AI attribution in commits or PRs.

## Verified 0.17 facts (planning probe)

- `std.PriorityQueue(T, Context, compareFn)` (compareFn returns `std.math.Order`): `.empty`, `push(gpa, x)`, `pop() ?T`, `peek() ?T`, `count()`, `deinit(gpa)`.
- `std.Deque(T)`: `.initBuffer(&buf)` for a fixed ring, `pushBackAssumeCapacity`, `popFront() ?T`, `len`, `iterator()`; also growable (`pushBack(gpa, x)`).
- `std.StaticBitSet(n)` and `std.EnumSet(E)` start `.empty` (not `initEmpty()`); `set`, `isSet`, `count`; `insert`, `contains`. `std.DynamicBitSetUnmanaged` for a size known at runtime.
- `std.sort.insertion(T, items, ctx, lessThan)`, `std.mem.sort` (stable), `std.mem.sortUnstable`; `std.sort.partitionPoint(T, items, ctx, predicate)`, `lowerBound`, `upperBound`, `binarySearch`.
- Timing: `const t0: std.Io.Timestamp = .now(io, .awake); ... t0.untilNow(io, .awake)` → `Duration{ .nanoseconds = ... }` (no `std.time.Timer` in 0.17).
- No graph type in std: adjacency lists in `ArrayList`s; BFS with `std.Deque`, Dijkstra with `std.PriorityQueue`.

## Review Focus

1. A ring buffer at capacity drops the oldest, never the newest, and iterates oldest-to-newest after wrapping (test with more pushes than slots).
2. Priority queue order with equal distances (two marks at the same metre) is still deterministic in the printed race: ties broken by a second key.
3. Insertion-sorted race order equals a fresh `std.mem.sort` every tick (test over a whole race), and ties keep a stable order (lower letter first).
4. `partitionPoint`-based `terrainAt` agrees with the old linear scan at every boundary (exactly on a segment start, before the first, past the last).
5. Dijkstra with an unreachable finish returns `null` (not a crash or an infinite loop); BFS and Dijkstra can disagree and the test shows a map where they do.

---

### Task 1: Code steps 22–27

**Files:** code/steps/22-ring-buffer … 27-graphs; code/diffs (generated). Tests first in each (RED), then GREEN; capture `zig build run` output.

- **22-ring-buffer** — the race feed: `Feed` = a `std.Deque(FeedLine)` over a fixed `[6]FeedLine` buffer (`FeedLine` = clock and a short text in a `[48]u8` with its length); `push` drops the oldest when full. `playRace` records every event into the feed; after the finish it prints "the finale:" with the last six moments. Tests: under capacity keeps all in order; over capacity keeps the newest six, oldest first; text longer than a line is cut, not overflowed.
- **23-queues** — course marks in distance order: `Mark { at_m, label }` in a `std.PriorityQueue(Mark, void, byDistance)` built from the course (each km, the start and top of each climb, "1 km to go"), ties broken by label; `Race.step` pops every mark the leader has passed and reports `Event.mark` (replacing the bare `.km` event with labelled marks). Tests: marks come out in distance order whatever order they're pushed; two marks at the same metre come out by label; a step past two marks reports both.
- **24-sorting** — the field in race order: `Race.order: []usize` (indexes into `riders`), kept sorted every step with `std.sort.insertion` (nearly sorted already); the km line prints the top three (`leader is H, then E, B`); the finish prints a results table (place, letter, name, time or gap in metres). Tests: after every step of a whole race the order equals a fresh `std.mem.sort`; ties keep the lower letter first; results list everyone once.
- **25-binary-search** — `Course.terrainAt` and the course's `segmentAt(position_m) usize` with `std.sort.partitionPoint` over the segment starts. Tests: agrees with a linear scan at every boundary of Compile Pass and a 1000-segment course (exactly on a start, 0, past the end).
- **26-prefix-sums** — `Course.climbed: []f64` prefix sums of metres climbed at each segment start (built when the course is parsed); `fn climbBetween(from_m, to_m) f64` in O(1) plus the partial segments; each rider's fastest kilometre with a sliding window over its per-second positions (a `std.Deque` of the last seconds, two pointers). Race card prints "climbing: 120 m"; the results print each rider's fastest km. Tests: climbBetween equals summing segment by segment (including partial ends); the fastest km of a rider with a known speed profile.
- **27-bitsets** — `Race.finished: std.DynamicBitSetUnmanaged` (one bit a rider, in the race's arena) replaces `Rider.last_m` for "report each finisher once"; the race card lists the course's terrain kinds from a `std.EnumSet(Terrain)` (`terrain: flat, climb, descent`). Tests: a finisher is reported once (bitset); the set for Compile Pass has three kinds, Linker Loop two.
- **28-text-search** — find a rider or word in the feed: `fn findAll(haystack, needle, out: *ArrayList(usize))` naive, then `std.mem.indexOfPos`, and a Boyer-Moore-Horspool `Horspool` (skip table); the feed's lines are word-wrapped greedily to a width (`fn wrap(text, width, lines)`) instead of cut. Tests: all three searches agree on the feed (overlapping matches, empty needle, needle longer than text); wrap never exceeds the width and never splits a word that fits.
- **29-edit-distance** — "did you mean?": `fn editDistance(gpa, a, b) !usize` (Levenshtein, a DP table of two rows); `parseCourse` on an unknown terrain names the closest kind (`unknown terrain "clmb": did you mean "climb"?` on stderr, through a returned diagnostic). Tests: known distances (kitten/sitting = 3, "" vs "abc" = 3, same = 0); the suggestion for "clmb", "decsent", and none for "gravel" (too far).
- **30-tries** — rider-name completion: a `Trie` (nodes in an `ArrayList`, children by byte in a small sorted array) built from the roster names; the rider question accepts a letter or a name prefix (`He` → Heap; ambiguous `Ga`… lists the matches; none → default). Tests: insert/lookup; prefix with one match, several, none; case-insensitive.
- **31-graphs** — a course map: places (`Start`, `Bridge`, `Pass`, `Valley`, `Lake`, `Finish`) and roads (length and gradient) as adjacency lists; `fewestRoads` (BFS with `std.Deque`) and `shortestRoute` (Dijkstra with `std.PriorityQueue`) return `?[]usize` routes; a route becomes a course's text, so a third course, "Route Planner", is the shortest route from Start to Finish. Tests: BFS and Dijkstra on a map where they disagree; an unreachable place gives `null`; the planned course parses and races.

- [ ] Steps 22–31, each RED then GREEN, output captured.
- [ ] `node scripts/check-steps.ts` → ok 01–31; `node scripts/diff-steps.ts`; read each diff.
- [ ] Commit per step.

### Task 2: Guide pages 22–31

**Files:** src/pages/guide/data-structures/22-ring-buffers.md, 23-queues-and-priority-queues.md, 24-sorting.md,
25-binary-search.md, 26-prefix-sums-and-sliding-windows.md, 27-bit-sets.md, 28-searching-text.md,
29-edit-distance.md, 30-tries.md, 31-graphs.md. Group "Data structures and algorithms", order 1..10, `step` 22..31.

- **22 Ring buffers:** a fixed array with a head and a length, wrapping with `%` (written by hand first), then `std.Deque` (bounded and growing), what "full" should do (drop oldest, refuse, overwrite), where they're used (logs, feeds, audio, network input); which buffer when.
- **23 Queues and priority queues:** stack (ArrayList push/pop: last in, first out) vs queue (Deque: first in, first out) vs priority queue (smallest first, a heap underneath, `std.math.Order`, ties); linked lists (`std.DoublyLinkedList`, intrusive nodes) and why arrays usually win; which when.
- **24 Sorting:** merge sort written by hand (recursion, divide and conquer), `std.mem.sort` (stable) vs `sortUnstable`, comparison functions and context, sorting by several keys, insertion sort on nearly sorted data, measuring with `std.Io.Timestamp` (sort every tick vs keep sorted, real numbers for 8 and 10 000 riders in debug and fast), big-O from the measurements; which sort when.
- **25 Binary search:** halving, sorted input as the precondition, `partitionPoint`, `lowerBound`/`upperBound`, `binarySearch` for an exact match, off-by-one at boundaries; linear vs binary measured; which search when.
- **26 Prefix sums and sliding windows:** running totals and range queries in O(1), the off-by-one of `sums[j] - sums[i]`, a fixed-size window vs a window by distance, two pointers; measured against recomputing; which when.
- **27 Bit sets:** a bit per thing, `StaticBitSet`, `DynamicBitSetUnmanaged`, `EnumSet` (and `EnumArray`/`EnumMap` in a line), set operations (union, intersection), memory compared with `[]bool`; which set when.
- **28 Searching text:** naive search and its worst case, `std.mem.indexOf`/`indexOfPos`/`lastIndexOf`/`count`, Boyer-Moore-Horspool and its skip table, measured on a long feed; greedy word wrap; which search when.
- **29 Edit distance:** what dynamic programming is (overlapping subproblems, a table), Levenshtein filled by hand, two rows instead of the table, a threshold for "close enough", other distances in a line (Hamming, prefix); which when.
- **30 Tries:** a tree of prefixes, nodes in a flat list with indexes (not pointers), insert/lookup/completions, compared with a sorted list + binary search and `std.StaticStringMap` for fixed keywords; which when.
- **31 Graphs:** places and roads, adjacency lists vs a matrix, BFS (fewest roads) with a queue, Dijkstra (shortest distance) with a priority queue, reconstructing the route, unreachable places, a loop for a circuit; which algorithm when.

- [ ] Write; every snippet run; gcheck ok.

### Task 3: Lessons 22–27

Competencies (course.ts gains the fourth): 22, 23, 27, 30 "I can pick the right data structure for a job and say why"; 24, 25, 28 "I can sort and search, and measure what they cost"; 26, 29 "I can solve a problem with prefix sums, windows or dynamic programming"; 31 "I can find a route through a graph".

- Exercises: 22 the feed keeps the last N where N comes from a command-line-style constant, and a test for N=1; 23 a "sprint" mark at a given metre from the course text; 24 the results table sorted by time then by name for riders who didn't finish; 25 `kmAt(position)` via `lowerBound` over km marks; 26 the steepest kilometre of the course (a window over the profile); 27 riders who've led at some point (a bitset), printed at the finish; 28 case-insensitive search; 29 suggestions for misspelled rider names at the prompt; 30 completion that also matches a letter (`h` → H); 31 a route that avoids climbs (edge weights by time, not distance).
- Stretch (31, Part 5's create task): design a course map of at least eight places with a circuit; the player picks a start and finish; plan the route, race it, and test that an unreachable finish is reported, not crashed.

- [ ] Write; every snippet run; `pnpm test` PASS; `pnpm build` PASS.

### Task 4: Part 5 art

- public/art/agama-data.svg: Agama with a route map (places as dots, roads as lines, the shortest route highlighted), chibi style; set `art` in course.ts; show on guide 22.

### Task 5: Check and PR

- [ ] All checks; screenshots (guide 31 In the game, lesson 31 Stretch); self-review against the Review Focus (no review agent unless Felix asks); PR with rulings and deferred items.

## Added (Felix, after Task 1): topological sort

Step 32, `32-topological-sort`: a season. Courses unlock after others (`unlocks_text`: "Linker Loop after Compile
Pass", ...); `parseUnlocks` reads the rules and `seasonOrder` orders them with Kahn's algorithm, ready courses taken
from a priority queue by list index (deterministic), `null` for a circle. The races follow the season from the course
picked. Guide page 32 also teaches the depth-first version with three marks. Part 5's Stretch moves from lesson 31 to
lesson 32 (now "your own map and season"). Competency: "I can find a route through a graph".
