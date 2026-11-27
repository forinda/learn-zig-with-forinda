// Carry a fix forward: `node scripts/carry.ts <fromStep> <patch>` applies the patch (paths like src/main.zig,
// as code/diffs has them) to every step after `fromStep`, then builds and tests those steps. It stops at the
// first step the patch doesn't apply to and names it: that step needs the fix by hand.
import { spawnSync } from 'node:child_process'
import { resolve, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { listSteps, STEPS } from './check-steps.ts'

export type Carried = { applied: string[]; failedAt: string | null }

/** Apply `patch` to each step after `from` (by name order) in `steps`; `test` runs zig build test in each. */
export function carry(steps: string, from: string, patch: string, opts = { test: true }): Carried {
  const applied: string[] = []
  for (const step of listSteps(steps).filter((s) => s > from)) {
    const dir = join(steps, step)
    // run in the step's folder: git apply resolves the patch's paths (src/main.zig) from there, in a repo or not
    const args = ['apply', '-p0', resolve(patch)]
    const check = spawnSync('git', [...args.slice(0, 1), '--check', ...args.slice(1)], { cwd: dir, encoding: 'utf8' })
    if (check.status !== 0) return { applied, failedAt: step }
    spawnSync('git', args, { cwd: dir, encoding: 'utf8' })
    if (opts.test && spawnSync('zig', ['build', 'test'], { cwd: dir, stdio: 'inherit' }).status !== 0) return { applied, failedAt: step }
    applied.push(step)
  }
  return { applied, failedAt: null }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [from, patch] = process.argv.slice(2)
  if (!from || !patch) {
    console.error('usage: node scripts/carry.ts <fromStep> <patch>')
    process.exit(2)
  }
  const r = carry(STEPS, from, patch)
  console.log(`applied to: ${r.applied.join(', ') || 'none'}`)
  if (r.failedAt) {
    console.error(`stopped at ${r.failedAt}: the patch doesn't apply or its tests fail there; fix it by hand`)
    process.exit(1)
  }
}
