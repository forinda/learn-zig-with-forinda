# The course's code

- `steps/NN-slug/` — one complete Zig 0.17 project per lesson step. Copy a folder (or clone the repo) and
  run `zig build run` and `zig build test` inside it; each step stands on its own.
- `diffs/NN-slug.diff` — what each step changed, for comparing (generated: `pnpm diffs`; the end of each guide page).
- `broken/` — programs that don't compile, on purpose, for the lessons on reading errors. CI doesn't build them.

Guide pages show each step's new code from named regions in its source (`// #region name` … `// #endregion name`),
and the whole file.

Tooling: `pnpm steps` builds, tests and runs every step; `node scripts/diff-steps.ts <from> <to>` prints the patch
between two steps, and `node scripts/carry.ts <fromStep> <patch>` carries a fix forward through the later steps.
