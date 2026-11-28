---
title: "Topological sort"
description: "Check your understanding of topological sort, Kahn's algorithm, ties and circles, then design your own map and season."
group: "Data structures and algorithms"
order: 11
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 32-topological-sort
competency: "I can find a route through a graph"
---

# Topological sort

**Read first:** [Topological sort](/guide/data-structures/32-topological-sort) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz When does a topological order exist?
- [ ] Always
- [ ] Only when every course has a rule
- [x] When the rules never go round in a circle (the graph is a DAG)
- [ ] Only when there are fewer rules than courses

"A after B" and "B after A" can't both hold. Without circles, Kahn's algorithm always finds an order.
:::

::: quiz Why does the game take ready courses from a priority queue instead of a plain queue?
- [ ] A plain queue gives a wrong order
- [x] So the same rules always give the same season, whatever order the rules are written in
- [ ] A priority queue is faster
- [ ] To detect circles

Any ready course may go next; many orders are valid. Taking the lowest index each time picks the same one every run.
:::

## Predict

Four courses, 0 to 3, and two rules: 2 after 0, 1 after 3.

```zig
const order = (try seasonOrder(gpa, 4, &.{
    .{ .course = 2, .after = 0 },
    .{ .course = 1, .after = 3 },
})).?;
```

::: quiz What is order?
- [ ] { 0, 1, 2, 3 }
- [ ] { 0, 3, 1, 2 }
- [x] { 0, 2, 3, 1 }
- [ ] { 3, 0, 2, 1 }

Ready at the start: 0 and 3. The lowest goes first, 0, which makes 2 ready. Now 2 and 3 are ready: 2, then 3, which
makes 1 ready.
:::

## Fix it

`seasonOrder` without its last check:

```zig
    while (ready.pop()) |course| { ... }
    return try order.toOwnedSlice(gpa);
}
```

```text
+- run test 94 pass, 1 fail (95 total); 1 leaks
error: 'main.test.rules that go round in a circle have no season' failed:
```

::: quiz What's the fix?
- [x] If fewer courses made it into the order than there are courses, free the order and return null: the rest are waiting on a circle
- [ ] Push every course into ready at the start
- [ ] Skip rules whose course has already been raced
- [ ] Sort the rules first

Courses in a circle never reach zero waiting, so they never make it into the order. Without the check, the function
returns a season that leaves them out. (The leak is the test not freeing a slice it expected to be `null`.)
:::

## Build it

### Exercise

Report *which* courses are stuck. When there's no season, list the courses that never became ready (Kahn's
leftovers) in a note: `note: these courses wait on each other: Linker Loop, Route Planner`. Change `seasonOrder` to
return the leftovers some way you choose (an error and a slice the caller passes in works). Tests first: the circle
from the Guide's tip leaves exactly the courses in it (and any waiting on them), and a good set of rules leaves none.

```sh
zig build test --summary all
```

## Stretch

**Part 5's challenge: your own map and season.** Draw a course map of at least eight places with a circuit (a loop
you could ride round more than once), and plan at least three courses on it. Give them unlock rules, and let the
player race the season.

- A test that plans a route on your map, by both searches if they differ.
- A test that an unreachable finish is reported to the player (a note on stderr), not a crash.
- A test that your unlock rules give the season you meant, and one with a circle that's refused.

Any map with a circuit and a season that plans, races, and passes the tests counts.
