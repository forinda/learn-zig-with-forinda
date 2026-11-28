---
title: "Graphs"
description: "Check your understanding of graphs, BFS, Dijkstra and rebuilding routes, then design your own course map."
group: "Data structures and algorithms"
order: 10
layout: /src/layouts/lesson.tscl
steps: true
minutes: 20
step: 31-graphs
competency: "I can find a route through a graph"
---

# Graphs

**Read first:** [Graphs](/guide/data-structures/31-graphs) in the Guide. This lesson checks you understood it.

## Recall

::: quiz Why does breadth-first search find the route with the fewest roads?
- [ ] It tries every route and keeps the best
- [x] Its queue visits every place one road away before any place two roads away, so the first arrival is by the fewest roads
- [ ] It always takes the shortest road first
- [ ] It sorts the places by distance

First in, first out: places come out of the queue in order of how many roads from the start they are.
:::

::: quiz In Dijkstra's algorithm, when is a place's distance final?
- [ ] When it's first put in the queue
- [x] When it comes out of the priority queue (nothing still waiting is nearer)
- [ ] When all its roads have been looked at
- [ ] Only at the end

The priority queue hands out the nearest place still waiting. With no negative road lengths, no later route can
reach it sooner.
:::

## Predict

On the Guide's map (start–bridge 3 km, bridge–valley 4 km, valley–lake 3 km, start–lake 9 km, bridge–pass 2.5 km,
pass–finish 3 km, lake–finish 2.5 km):

```zig
const a = (try shortestRoute(gpa, &map, .start, .valley)).?;
const b = (try fewestRoads(gpa, &map, .pass, .lake)).?;
```

::: quiz What are a and b?
- [x] a: start > bridge > valley; b: pass > finish > lake
- [ ] a: start > lake > valley; b: pass > bridge > valley > lake
- [ ] a: start > bridge > valley; b: pass > bridge > start > lake
- [ ] a: start > lake > valley; b: pass > finish > lake

To the valley: 7 km by the bridge, 12 km by the lake. From the pass to the lake, two roads by the finish; every
other way takes three.
:::

## Fix it

`shortestRoute` without the check before rebuilding the route:

```zig
    }
    return try routeTo(gpa, &previous, from, to);
}
```

```text
error: 'main.test.a place no road reaches has no route' terminated with signal ABRT with stderr:
       thread 1053200 panic: attempt to use null value
```

::: quiz What's the fix?
- [x] If the target's distance is still infinite, return null before rebuilding the route
- [ ] Start previous with .start instead of null
- [ ] Use .? less: change routeTo's previous[...].? to orelse break
- [ ] Add a road to the island

`island` was never reached, so nothing recorded where it was reached from, and `routeTo` unwraps a `null`. "Not
reached" is a real answer: check it and return `null`. Patching `routeTo` would return a route that doesn't start
at the start.
:::

## Build it

### Exercise

Plan by time, not distance: weigh each road by how long a 10 m/s rider takes on it (its length divided by
`speedFor(Terrain.of(gradient))`, the climb ridden one way and the descent the other). Make `shortestRoute` take the
weight function, or write `quickestRoute`. Tests first: on the Guide's map the quickest route from start to finish
avoids the pass (the climb is slow), and from finish to start it's the same roads as the shortest.

```sh
zig build test --summary all
```
