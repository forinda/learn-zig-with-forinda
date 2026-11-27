// The difference between two lesson steps, as a patch (paths like src/main.zig): what `scripts/carry.ts` applies to
// later steps. `node scripts/diff-steps.ts 09-text-road 10-structs > fix.diff` prints one. (The guide pages show
// copyable code from each step's regions, not diffs.)
import { spawnSync } from 'node:child_process'
import { existsSync } from 'node:fs'
import { basename, dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { STEPS } from './check-steps.ts'

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

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [from, to] = process.argv.slice(2)
  if (!from || !to) {
    console.error('usage: node scripts/diff-steps.ts <fromStep> <toStep>')
    process.exit(2)
  }
  process.stdout.write(diffStep(join(STEPS, from), join(STEPS, to)))
}
