// The step tooling: listing steps, the patch between two, and carrying a fix forward. Run with `pnpm test`.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { cpSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { listSteps } from './check-steps.ts'
import { diffStep, displayDiff, staleDiffs, writeDiffs } from './diff-steps.ts'
import { carry } from './carry.ts'

const FIXTURE = fileURLToPath(new URL('./fixtures/steps/', import.meta.url))

/** A scratch copy of the fixture steps (tests apply patches to it). */
function scratch(): { steps: string; diffs: string } {
  const root = mkdtempSync(join(tmpdir(), 'steps-'))
  cpSync(FIXTURE, join(root, 'steps'), { recursive: true })
  return { steps: join(root, 'steps'), diffs: join(root, 'diffs') }
}

test('listSteps: step folders only (NN-slug), sorted', () => {
  assert.deepEqual(listSteps(FIXTURE), ['01-a', '02-b'])
})

test("a step's diff shows what changed from the previous step, with plain paths", () => {
  const d = diffStep(join(FIXTURE, '01-a'), join(FIXTURE, '02-b'))
  assert.match(d, /\+    return "Terminal Tour";/)
  assert.match(d, /^--- src\/main\.zig$/m)
  assert.doesNotMatch(d, /01-a|02-b/)
  assert.doesNotMatch(d, /build\.zig/) // unchanged files aren't in it
})

test('a display diff leaves out the region markers', () => {
  const d = displayDiff(join(FIXTURE, '01-a'), join(FIXTURE, '02-b'))
  assert.match(d, /\+    return "Terminal Tour";/)
  assert.doesNotMatch(d, /#region|#endregion/)
})

test('writeDiffs writes one display diff per step after the first; staleDiffs finds an edited one', () => {
  const { steps, diffs } = scratch()
  assert.deepEqual(writeDiffs(steps, diffs), ['02-b.diff'])
  assert.deepEqual(staleDiffs(steps, diffs), [])
  writeFileSync(join(diffs, '02-b.diff'), 'edited by hand\n')
  assert.deepEqual(staleDiffs(steps, diffs), ['02-b.diff'])
})

test('carry applies a fix to every step after the given one', () => {
  const { steps } = scratch()
  const patch = join(steps, '..', 'fix.diff')
  writeFileSync(patch, diffStep(join(steps, '01-a'), join(steps, '02-b')).replaceAll('Terminal Tour', 'X'))
  // a fix written against 01-a's main.zig: carry it from 00 (every step) to see it apply to 01-a only
  // (02-b already has the function: the patch doesn't apply there, and carry names it)
  const r = carry(steps, '00', patch, { test: false })
  assert.deepEqual(r.applied, ['01-a'])
  assert.equal(r.failedAt, '02-b')
  assert.match(readFileSync(join(steps, '01-a', 'src', 'main.zig'), 'utf8'), /return "X";/)
})

test('carry applies inside a git repository too (where git apply resolves paths from the top)', () => {
  const root = mkdtempSync(join(tmpdir(), 'repo-'))
  const steps = join(root, 'code', 'steps')
  cpSync(FIXTURE, steps, { recursive: true })
  for (const args of [['init', '-q'], ['add', '-A'], ['-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-qm', 'x']]) spawnSync('git', args, { cwd: root })
  const patch = join(root, 'fix.diff')
  writeFileSync(patch, diffStep(join(steps, '01-a'), join(steps, '02-b')).replaceAll('Terminal Tour', 'X'))
  const r = carry(steps, '00', patch, { test: false })
  assert.deepEqual(r.applied, ['01-a'])
  assert.match(readFileSync(join(steps, '01-a', 'src', 'main.zig'), 'utf8'), /return "X";/)
})
