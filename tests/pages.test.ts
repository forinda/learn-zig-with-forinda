// The rules every guide page and lesson follows that the build can't check. Run with `pnpm test`.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { fileURLToPath } from 'node:url'
import { groups } from '../src/groups.ts'
import { parts } from '../src/course.ts'
import { guideProblems, lessonProblems, mdUnder, orderProblems, pairProblems, stretchProblems } from './rules.ts'

const PAGES = fileURLToPath(new URL('../src/pages/', import.meta.url))
const GUIDE = fileURLToPath(new URL('../src/pages/guide/', import.meta.url))
const LEARN = fileURLToPath(new URL('../src/pages/learn/', import.meta.url))
const STEPS = fileURLToPath(new URL('../code/steps/', import.meta.url))
const BROKEN_LESSON = fileURLToPath(new URL('./fixtures/learn/start/broken-lesson.md', import.meta.url))
const BROKEN_GUIDE = fileURLToPath(new URL('./fixtures/guide/start/broken-guide.md', import.meta.url))
const WRONG_PAIR = fileURLToPath(new URL('./fixtures/pair/guide/basics/04-values-and-types.md', import.meta.url))

test('the parts in src/course.ts are the guide and course groups, in order', () => {
  assert.deepEqual(parts.map((p) => p.title), groups.learn.map((g) => g.title))
  assert.deepEqual(parts.map((p) => p.title), groups.guide.map((g) => g.title))
  for (const p of parts) assert.ok(p.competencies.length > 0, `${p.title} has no competencies`)
})

test('every guide page follows the rules (part and folder, an In the game section with its step code, step folder, link to its lesson)', () => {
  for (const file of mdUnder(GUIDE)) assert.deepEqual(guideProblems(file, STEPS, PAGES), [], file)
})

test('every lesson follows the rules (read-first link, check steps, quizzes, build exercise, competency)', () => {
  for (const file of mdUnder(LEARN)) assert.deepEqual(lessonProblems(file, STEPS, PAGES), [], file)
})

test('guide pages and lessons are ordered 1..n within each part; each part ends with a Stretch', () => {
  assert.deepEqual(orderProblems(mdUnder(GUIDE)), [])
  assert.deepEqual(orderProblems(mdUnder(LEARN)), [])
  assert.deepEqual(stretchProblems(mdUnder(LEARN)), [])
})

test('the rules catch a broken guide page', () => {
  const problems = guideProblems(BROKEN_GUIDE, STEPS, PAGES).join('\n')
  for (const rule of ['folder:', 'game: no', 'step:', 'lesson:']) assert.ok(problems.includes(rule), `expected "${rule}" in:\n${problems}`)
})

test('the rules catch a broken lesson', () => {
  const problems = lessonProblems(BROKEN_LESSON, STEPS, PAGES).join('\n')
  for (const rule of ['folder:', 'steps:', 'quiz:', 'Predict:', 'Fix it:', 'Build it: no zig build test', 'Build it: no ### Exercise', 'guide:', 'step:', 'competency:', 'code:']) {
    assert.ok(problems.includes(rule), `expected "${rule}" in:\n${problems}`)
  }
})

test('a guide page links to its own lesson (same part, same name), and every guide page has a lesson and back', () => {
  const problems = guideProblems(WRONG_PAIR, STEPS, PAGES).join('\n')
  assert.ok(problems.includes('lesson: links to /learn/basics/05-making-decisions'), problems)
  assert.deepEqual(pairProblems(PAGES), [])
})
