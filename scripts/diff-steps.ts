// What each lesson step changes: code/diffs/NN-slug.diff is the diff from the previous step (build.zig,
// build.zig.zon, src/). Lessons include it with `<<< @/code/diffs/NN-slug.diff`.
// `node scripts/diff-steps.ts` writes them; `--check` exits 1 when a committed diff is stale (CI).
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
  // plain paths, and no `index <hash>..<hash>` lines: noise for a reader, not needed to apply the patch
  return out.replaceAll(`${a}/`, '').replaceAll(`${b}/`, '').replace(/^index [0-9a-f]+\.\.[0-9a-f]+.*\n/gm, '')
}

/** Writes every step's diff (each step after the first); returns the file names written. */
export function writeDiffs(steps: string, diffs: string): string[] {
  mkdirSync(diffs, { recursive: true })
  const names = listSteps(steps)
  return names.slice(1).map((name, i) => {
    const file = `${name}.diff`
    writeFileSync(join(diffs, file), diffStep(join(steps, names[i]!), join(steps, name)))
    return file
  })
}

/** The diff files that are missing or differ from what the steps give now. */
export function staleDiffs(steps: string, diffs: string): string[] {
  const names = listSteps(steps)
  return names.slice(1).flatMap((name, i) => {
    const file = join(diffs, `${name}.diff`)
    const want = diffStep(join(steps, names[i]!), join(steps, name))
    return existsSync(file) && readFileSync(file, 'utf8') === want ? [] : [`${name}.diff`]
  })
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes('--check')) {
    const stale = staleDiffs(STEPS, DIFFS)
    for (const f of stale) console.error(`stale: code/diffs/${f} (run pnpm diffs)`)
    if (stale.length) process.exit(1)
  } else {
    for (const f of writeDiffs(STEPS, DIFFS)) console.log(`wrote code/diffs/${f}`)
  }
}
