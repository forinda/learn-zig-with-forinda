---
title: "Ring buffers"
description: "Check your understanding of ring buffers: wrapping, full policies and std.Deque."
group: "Data structures and algorithms"
order: 1
layout: /src/layouts/lesson.tscl
steps: true
minutes: 15
step: 22-ring-buffer
competency: "I can pick the right data structure for a job and say why"
---

# Ring buffers

**Read first:** [Ring buffers](/guide/data-structures/22-ring-buffers) in the Guide. This lesson checks you
understood it.

## Recall

::: quiz The feed must keep the last six moments of a race. Which is the right structure?
- [ ] An ArrayList, removing item 0 when it reaches six
- [x] A ring buffer: a Deque over a six-item array, dropping the oldest when full
- [ ] A growing Deque with no limit
- [ ] A hash map from time to text

The last N, fixed memory, constant-time add and drop: a ring. `orderedRemove(0)` moves every item each time; an
unlimited deque keeps everything.
:::

::: quiz A ring has 4 places, head = 3 and len = 2. Where is the newest item?
- [ ] items[5]
- [ ] items[4]
- [x] items[0]
- [ ] items[3]

Item `i` from the oldest is at `(head + i) % 4`; the newest is `i = len - 1 = 1`: `(3 + 1) % 4 = 0`.
:::

## Predict

The hand-written `Ring` from the Guide with three places instead of four:

```zig
var ring: Ring = .{};
for (1..6) |i| ring.push(@intCast(i));
std.debug.print("{d} {any} {d}\n", .{ ring.at(0), ring.items, ring.head });
```

::: quiz What does it print?
- [ ] 1 { 1, 2, 3 } 0
- [ ] 3 { 3, 4, 5 } 0
- [x] 3 { 4, 5, 3 } 2
- [ ] 5 { 4, 5, 3 } 2

The last three are 3, 4, 5, oldest first, so `at(0)` is 3. In memory, 4 and 5 wrapped round over 1 and 2, and the
oldest, 3, is at index 2.
:::

## Fix it

```zig
fn record(feed: *std.Deque(u32), moment: u32) void {
    feed.pushBackAssumeCapacity(moment);
}
```

Over a 3-item buffer, the fourth `record`:

```text
thread 1025253 panic: reached unreachable code
```

::: quiz What's the fix, for a feed that keeps the latest moments?
- [x] if (feed.len == feed.buffer.len) _ = feed.popFront(); before pushing
- [ ] try feed.pushBackBounded(moment) and ignore the error
- [ ] Make the buffer bigger
- [ ] feed.pushFrontAssumeCapacity(moment)

Drop the oldest to make room. Ignoring `pushBackBounded`'s error keeps the *oldest* three and loses every new
moment; a bigger buffer only moves the crash later; pushing at the front is just as full.
:::

## Build it

### Exercise

Make the feed's size a parameter of `playRace` instead of the `feed_size` constant, and give `Feed.init` a slice
of that many lines (allocated in the race's arena). Test first: a feed of size 1 keeps only the newest line after
three pushes, and a feed of size 0 is refused by `playRace` with `error.EmptyFeed` (a ring with no room can't hold
anything, and `pushBackAssumeCapacity` would crash).

```sh
zig build test --summary all
```
