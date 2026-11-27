// Differences between lesson steps. `diffStep` is a patch (paths like src/main.zig) that `scripts/carry.ts` can apply;
// `displayDiff` is the same without the `// #region` marker lines, for the collapsed "what changed" section at the end
// of a guide page (code/diffs/NN-slug.diff, written by `pnpm diffs`, checked in CI with `--check`).
// `node scripts/diff-steps.ts <from> <to>` prints the patch between two steps.
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { basename, dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { listSteps, STEPS } from './check-steps.ts'

export const DIFFS = fileURLToPath(new URL('../code/diffs/', import.meta.url))

const FILES = ['build.zig', 'build.zig.zon', 'src']

/** The diff from step folder `prev` to its sibling `cur`, with paths as the reader sees them (src/main.zig). */
export function diffStep(prev: string, cur: string): string {
  const parent = dirname(cur)
  const [a, b] = [basename(prev), basename(cur)]
  let out = ''
  for (const f of FILES) {
    if (!existsSync(join(prev, f)) && !existsSync(join(cur, f))) continue
    // exit 1 means "they differ"; anything else is an error
    const r = spawnSync('git', ['diff', '--no-index', '--no-prefix', '--', `${a}/${f}`, `${b}/${f}`], { cwd: parent, encoding: 'utf8' })
    if (r.status !== 0 && r.status !== 1) throw new Error(`git diff ${a}/${f} ${b}/${f}: ${r.stderr}`)
    out += r.stdout
  }
  // plain paths, and no `index <hash>..<hash>` lines: not needed to apply the patch
  return out.replaceAll(`${a}/`, '').replaceAll(`${b}/`, '').replace(/^index [0-9a-f]+\.\.[0-9a-f]+.*\n/gm, '')
}

/** `diffStep` without the region marker lines: what a reader compares. */
export function displayDiff(prev: string, cur: string): string {
  return diffStep(prev, cur).replace(/^[ +-][ \t]*\/\/ #(end)?region\b.*\n/gm, '')
}

/** Writes every step's display diff (each step after the first); returns the file names written. */
export function writeDiffs(steps: string, diffs: string): string[] {
  mkdirSync(diffs, { recursive: true })
  const names = listSteps(steps)
  return names.slice(1).map((name, i) => {
    writeFileSync(join(diffs, `${name}.diff`), displayDiff(join(steps, names[i]!), join(steps, name)))
    return `${name}.diff`
  })
}

/** The display diffs that are missing or differ from what the steps give now. */
export function staleDiffs(steps: string, diffs: string): string[] {
  const names = listSteps(steps)
  return names.slice(1).flatMap((name, i) => {
    const file = join(diffs, `${name}.diff`)
    const want = displayDiff(join(steps, names[i]!), join(steps, name))
    return existsSync(file) && readFileSync(file, 'utf8') === want ? [] : [`${name}.diff`]
  })
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2)
  if (args[0] === '--check') {
    const stale = staleDiffs(STEPS, DIFFS)
    for (const f of stale) console.error(`stale: code/diffs/${f} (run pnpm diffs)`)
    if (stale.length) process.exit(1)
  } else if (args.length === 2) {
    process.stdout.write(diffStep(join(STEPS, args[0]!), join(STEPS, args[1]!)))
  } else if (args.length === 0) {
    for (const f of writeDiffs(STEPS, DIFFS)) console.log(`wrote code/diffs/${f}`)
  } else {
    console.error('usage: node scripts/diff-steps.ts [--check | <fromStep> <toStep>]')
    process.exit(2)
  }
}
