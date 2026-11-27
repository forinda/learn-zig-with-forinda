# The course's code

- `steps/NN-slug/` — one complete Zig 0.17 project per lesson step. Copy a folder (or clone the repo) and
  run `zig build run` and `zig build test` inside it; each step stands on its own.
- `diffs/NN-slug.diff` — what each step changes from the previous one (generated: `pnpm diffs`). Lessons show it.
- `broken/` — programs that don't compile, on purpose, for the lessons on reading errors. CI doesn't build them.

Tooling: `pnpm steps` builds and tests every step; `pnpm diffs` regenerates the diffs (`--check` in CI);
`node scripts/carry.ts <fromStep> <patch>` carries a fix forward through the later steps.
