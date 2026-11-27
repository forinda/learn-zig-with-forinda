// Builds, tests and runs every lesson step with Zig 0.17: `node scripts/check-steps.ts [filter]` (CI runs it on
// Linux, macOS and Windows). Running it checks the real terminal output path too: the program must exit cleanly and
// print something. One line per step, exit 1 when any fails. `filter` keeps steps whose name contains it.
import { spawnSync } from 'node:child_process'
import { existsSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

export const ZIG_VERSION = '0.17.0'
export const STEPS = fileURLToPath(new URL('../code/steps/', import.meta.url))

/** Step folders (NN-slug) under `dir`, sorted. */
export function listSteps(dir: string): string[] {
  if (!existsSync(dir)) return []
  return readdirSync(dir)
    .filter((name) => /^\d{2}-[a-z0-9-]+$/.test(name) && statSync(join(dir, name)).isDirectory())
    .sort()
}

/** Run `zig <args>` in `cwd`; null when it worked, else the first error line. `output`: stdout must not be empty. */
function zig(cwd: string, args: string[], output = false): string | null {
  const r = spawnSync('zig', args, { cwd, encoding: 'utf8', input: '' })
  if (r.error) return `zig not found: ${r.error.message}`
  if (r.status === 0) return output && !r.stdout.trim() ? `${args.join(' ')}: printed nothing` : null
  const out = `${r.stderr}\n${r.stdout}`
  return out.split('\n').find((l) => /error/i.test(l))?.trim() ?? `exit ${r.status}`
}

function main(): void {
  const version = spawnSync('zig', ['version'], { encoding: 'utf8' }).stdout?.trim()
  if (version !== ZIG_VERSION) {
    console.error(`Zig ${ZIG_VERSION} is required, found ${version ?? 'none'}`)
    process.exit(1)
  }
  const filter = process.argv[2] ?? ''
  let failed = 0
  for (const step of listSteps(STEPS).filter((s) => s.includes(filter))) {
    const dir = join(STEPS, step)
    const error = zig(dir, ['build']) ?? zig(dir, ['build', 'test']) ?? zig(dir, ['build', 'run'], true)
    console.log(error ? `FAIL ${step}: ${error}` : `ok ${step}`)
    if (error) failed++
  }
  if (failed) process.exit(1)
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main()
