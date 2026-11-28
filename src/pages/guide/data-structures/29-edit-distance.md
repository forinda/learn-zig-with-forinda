---
title: "Edit distance"
description: "How different two words are, by recursion and then by dynamic programming: the Levenshtein table, two rows instead of all of it, and a threshold for \"did you mean\"."
group: "Data structures and algorithms"
order: 8
step: 29-edit-distance
---

# Edit distance

The game will ask which course to race first. Someone will type `linker lop`. The friendly answer isn't "no such
course", it's *did you mean Linker Loop?* For that the game needs a number for how different two words are: how many
single-letter edits (insert one, delete one, change one) turn one into the other. That's the **edit distance**
(Levenshtein distance), and computing it well is the classic first example of **dynamic programming**.

## Straight from the definition: recursion

Look at the last letters of `a` and `b`. Either delete `a`'s last letter, or insert `b`'s, or keep it (if they're
equal) or change it (if not); whichever leaves the smallest distance for the rest:

```zig
fn distanceSlow(a: []const u8, b: []const u8) usize {
    if (a.len == 0) return b.len; // insert all of b
    if (b.len == 0) return a.len; // delete all of a
    const change: usize = if (a[a.len - 1] == b[b.len - 1]) 0 else 1;
    return @min(
        distanceSlow(a[0 .. a.len - 1], b) + 1, // delete
        distanceSlow(a, b[0 .. b.len - 1]) + 1, // insert
        distanceSlow(a[0 .. a.len - 1], b[0 .. b.len - 1]) + change, // keep or change
    );
}
```

It's right, and it's hopeless. Counting the calls:

```text
clmb / climb: 1 in 1021 calls
kitten / sitting: 3 in 29737 calls
Errdefer / Erdefer!: 2 in 398593 calls
Compile Pas / Compile Pass: 1 in 154911937 calls
```

Three calls per call, all the way down: it grows about three times for every letter. A course name of a dozen
letters takes 155 million calls, and nearly all of them work out the same few answers again and again.

## Dynamic programming: each answer once

The calls only ever ask about a *prefix* of `a` and a *prefix* of `b`. There are `(a.len + 1) × (b.len + 1)` of
those. Work out each once, smallest first, in a table: `t[i][j]` is the distance between the first `i` letters of
`a` and the first `j` of `b`.

```zig
for (0..a.len + 1) |i| t[i][0] = i; // to "": delete them all
for (0..b.len + 1) |j| t[0][j] = j; // from "": insert them all
for (1..a.len + 1) |i| for (1..b.len + 1) |j| {
    const change: usize = if (a[i - 1] == b[j - 1]) 0 else 1;
    t[i][j] = @min(t[i - 1][j] + 1, t[i][j - 1] + 1, t[i - 1][j - 1] + change);
};
```

```text
      s  i  t  t  i  n  g
   0  1  2  3  4  5  6  7
k  1  1  2  3  4  5  6  7
i  2  2  1  2  3  4  5  6
t  3  3  2  1  2  3  4  5
t  4  4  3  2  1  2  3  4
e  5  5  4  3  2  2  3  4
n  6  6  5  4  3  3  2  3
```

The answer is in the bottom-right corner: 3 (k→s, e→i, insert g). Each cell is three lookups: `a.len × b.len`
work, a few hundred steps for course names instead of 155 million.

That's dynamic programming in general: a problem whose answer is built from answers to smaller versions of itself
(**optimal substructure**), where the same smaller versions come up again and again (**overlapping subproblems**).
Solve each small one once, keep its answer, build up.

## Two rows are enough

Each row only needs the row above it. Keep two rows and swap them: `b.len + 1` numbers instead of the whole table.

```zig
for (previous, 0..) |*d, j| d.* = j;
for (a, 1..) |letter_a, i| {
    current[0] = i;
    for (b, 1..) |letter_b, j| { ... } // the same three-way @min, from previous and current
    std.mem.swap([]usize, &previous, &current);
}
return previous[b.len];
```

The game's version (below) also ignores case, so `LINKER loop` is 0 edits from `Linker Loop`.

## Close enough

A distance on its own doesn't say "did you mean": everything is *some* distance from everything. Pick a threshold
(the game uses 3 edits), and pick the closest name within it, or none. Too small a threshold misses real typos; too
big, and `Gravel Grinder` "means" a course it has nothing to do with.

| Distance | Counts | For |
|---|---|---|
| Levenshtein | inserts, deletes, changes | typos in names and commands |
| Hamming | changes only, same length | codes, fixed-width IDs |
| prefix match | "starts with" | completion as you type ([Tries](/guide/data-structures/30-tries)) |

::: tip Try it
Fill the table for `clmb` and `climb` by hand, then with the code. Which cell first shows the missing `i`?
:::

## Which approach when

| Problem | Use | Because |
|---|---|---|
| a definition that recurses, with few repeats | recursion | simplest |
| recursion that keeps asking the same small questions | dynamic programming: a table, smallest first | each answer once |
| a table where each row needs only the last | two rows | memory for one row, not all |
| "is this close to one of a few names?" | edit distance with a threshold | a few hundred steps each |
| "close to one of a million?" | a trie or a special index (beyond this course) | can't compare with every one |

## In the game

The first course is picked by name. Below the summary code, the distance (two rows, ignoring case) and the closest
course within 3 edits:

<<< @/code/steps/29-edit-distance/src/main.zig#distance

In `main`, before the races, the question. A typo races the closest course, with a note on stderr:

<<< @/code/steps/29-edit-distance/src/main.zig#pick-course

The race loop starts from that course: `courses[(first_course + race_no) % courses.len]`. The tests, at the end of the
file:

<<< @/code/steps/29-edit-distance/src/main.zig#tests

Run it (or copy `code/steps/29-edit-distance`) and type `linker lop`:

```sh
zig build run
```

```text
Which course first? (Compile Pass, Linker Loop) linker lop
note: no course "linker lop"; did you mean "Linker Loop"? racing it

race 1: Linker Loop
```

Here's everything, the whole `src/main.zig` after this step:

<<< @/code/steps/29-edit-distance/src/main.zig

<details>
<summary>What changed since the last step, as a diff</summary>

Lines starting with `+` were added, `-` removed. Only for comparing: copy the code above.

<<< @/code/diffs/29-edit-distance.diff

</details>

::: tip Check your understanding
Done reading? [Take the lesson →](/learn/data-structures/29-edit-distance) Quizzes on what you just read, a snippet to predict, a bug to fix, and
this step to build yourself.
:::
