// The rules every lesson follows that the build can't check. Run with `pnpm test`.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { fileURLToPath } from 'node:url'
import { groups } from '../src/groups.ts'
import { parts } from '../src/course.ts'
import { lessonProblems, mdUnder, orderProblems } from './rules.ts'

const LEARN = fileURLToPath(new URL('../src/pages/learn/', import.meta.url))
const STEPS = fileURLToPath(new URL('../code/steps/', import.meta.url))
const BROKEN = fileURLToPath(new URL('./fixtures/learn/start/broken-lesson.md', import.meta.url))

test('the parts in src/course.ts are the course groups, in order', () => {
  assert.deepEqual(parts.map((p) => p.title), groups.learn.map((g) => g.title))
  for (const p of parts) assert.ok(p.competencies.length > 0, `${p.title} has no competencies`)
})

test('every lesson follows the rules (group and folder, 5E steps, evaluate, step folder, competency, no retyped game code)', () => {
  for (const file of mdUnder(LEARN)) assert.deepEqual(lessonProblems(file, STEPS), [], file)
})

test('lessons are ordered 1..n within each part', () => {
  assert.deepEqual(orderProblems(mdUnder(LEARN)), [])
})

test('the rules catch a broken lesson', () => {
  const problems = lessonProblems(BROKEN, STEPS).join('\n')
  for (const rule of ['folder:', '5E:', 'evaluate: no ::: quiz', 'evaluate: no zig build test', 'evaluate: no ### Exercise', 'step:', 'competency:', 'code:']) {
    assert.ok(problems.includes(rule), `expected a "${rule}" problem in:\n${problems}`)
  }
})
