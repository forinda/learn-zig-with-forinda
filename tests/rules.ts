// The rules every guide page and lesson follows (tests/pages.test.ts runs them on src/pages and on broken fixtures).
// Guide pages teach (Engage, Explore, Explain, Elaborate); lessons check understanding (Recall, Predict, Fix it,
// Build it, and Stretch at the end of a part).
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { basename, dirname, join } from 'node:path'
import { parts } from '../src/course.ts'

export const GUIDE_STEPS = ['Engage', 'Explore', 'Explain', 'Elaborate'] as const
export const LESSON_STEPS = ['Recall', 'Predict', 'Fix it', 'Build it'] as const
export const STRETCH = 'Stretch'
export const MIN_QUIZZES = 3
export const MAX_ZIG_LINES = 15

/** Every .md file under `dir`, as absolute paths. */
export function mdUnder(dir: string): string[] {
  if (!existsSync(dir)) return []
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name)
    if (statSync(path).isDirectory()) return mdUnder(path)
    return name.endsWith('.md') ? [path] : []
  })
}

/** A page's frontmatter as plain key -> string (quotes removed). */
export function frontmatter(text: string): Record<string, string> {
  const m = text.match(/^---\n([\s\S]*?)\n---/)
  const out: Record<string, string> = {}
  for (const line of (m?.[1] ?? '').split('\n')) {
    const kv = line.match(/^([a-z]+):\s*(.*)$/)
    if (kv) out[kv[1]!] = kv[2]!.replace(/^"(.*)"$/, '$1')
  }
  return out
}

const body = (text: string) => text.replace(/^---\n[\s\S]*?\n---\n/, '')
/** The body without fenced code (headings inside code samples aren't steps). */
const prose = (text: string) => text.replace(/^(```|~~~)[\s\S]*?^\1/gm, '')
const h2s = (text: string) => [...prose(text).matchAll(/^## (.+)$/gm)].map((m) => m[1]!.trim())
/** The text of one `##` section (up to the next `##`). */
const section = (text: string, title: string) => text.split(new RegExp(`^## ${title}\\s*$`, 'm'))[1]?.split(/^## /m)[0] ?? ''

/** Problems both kinds of page share: part and folder, step folder, no long retyped game code. */
function common(file: string, fm: Record<string, string>, text: string, stepsDir: string): string[] {
  const problems: string[] = []
  const part = parts.find((p) => p.title === fm.group)
  if (!part) problems.push(`group: "${fm.group}" is not a part`)
  else if (basename(dirname(file)) !== part.slug) problems.push(`folder: a "${part.title}" page belongs in ${part.slug}/`)
  if (!fm.step || !existsSync(join(stepsDir, fm.step))) problems.push(`step: code/steps/${fm.step} doesn't exist`)
  for (const m of text.matchAll(/^```zig[^\n]*\n([\s\S]*?)^```/gm)) {
    const lines = m[1]!.split('\n').length - 1
    if (lines > MAX_ZIG_LINES) problems.push(`code: a ${lines}-line zig block; game code comes from its step folder (<<< @/code/steps/...)`)
  }
  return problems
}

/** Links in `text` to pages under `/prefix/`, as file paths under `pagesDir` (that may not exist). */
function linkedPages(text: string, prefix: string, pagesDir: string): string[] {
  return [...text.matchAll(new RegExp(`\\]\\((/${prefix}/[^)#\\s]+)`, 'g'))].map((m) => join(pagesDir, `${m[1]}.md`))
}

/** What's wrong with one guide page (empty: nothing). */
export function guideProblems(file: string, stepsDir: string, pagesDir: string): string[] {
  const text = readFileSync(file, 'utf8')
  const fm = frontmatter(text)
  const b = body(text)
  const problems = common(file, fm, b, stepsDir)
  const h = h2s(b)
  if (h.join('|') !== GUIDE_STEPS.join('|')) problems.push(`sections: [${h.join(', ')}], expected [${GUIDE_STEPS.join(', ')}]`)
  const lessons = linkedPages(b, 'learn', pagesDir)
  if (!lessons.length) problems.push('lesson: no link to its lesson (/learn/...)')
  else if (!existsSync(lessons.at(-1)!)) problems.push(`lesson: ${lessons.at(-1)} doesn't exist`)
  return problems
}

/** What's wrong with one lesson (empty: nothing). */
export function lessonProblems(file: string, stepsDir: string, pagesDir: string): string[] {
  const text = readFileSync(file, 'utf8')
  const fm = frontmatter(text)
  const b = body(text)
  const problems = common(file, fm, b, stepsDir)
  const h = h2s(b)
  const want = [...LESSON_STEPS].join('|')
  if (h.join('|') !== want && h.join('|') !== `${want}|${STRETCH}`) problems.push(`steps: [${h.join(', ')}], expected [${LESSON_STEPS.join(', ')}] (+ ${STRETCH})`)
  const quizzes = (b.match(/^:::+ *quiz\b/gm) ?? []).length
  if (quizzes < MIN_QUIZZES) problems.push(`quiz: ${quizzes} quizzes, at least ${MIN_QUIZZES}`)
  for (const s of ['Predict', 'Fix it']) if (!/^:::+ *quiz\b/m.test(section(b, s))) problems.push(`${s}: no ::: quiz`)
  const build = section(b, 'Build it')
  if (!/zig build test/.test(build)) problems.push('Build it: no zig build test')
  if (!/^### Exercise/m.test(build)) problems.push('Build it: no ### Exercise')
  const guides = linkedPages(b.split(/^## /m)[0] ?? '', 'guide', pagesDir)
  if (!guides.length) problems.push('guide: no "read first" link to its guide page (/guide/...) before the first step')
  else if (!existsSync(guides[0]!)) problems.push(`guide: ${guides[0]} doesn't exist`)
  const part = parts.find((p) => p.title === fm.group)
  if (part && !part.competencies.includes(fm.competency ?? '')) problems.push(`competency: "${fm.competency}" isn't listed for ${part.title} in src/course.ts`)
  return problems
}

/** Pages of each part ordered 1..n with no gaps or repeats. */
export function orderProblems(files: string[]): string[] {
  const byPart = new Map<string, number[]>()
  for (const f of files) {
    const fm = frontmatter(readFileSync(f, 'utf8'))
    byPart.set(fm.group ?? '', [...(byPart.get(fm.group ?? '') ?? []), Number(fm.order)])
  }
  return [...byPart].flatMap(([group, orders]) => {
    const sorted = [...orders].sort((a, b) => a - b)
    return sorted.every((o, i) => o === i + 1) ? [] : [`order: ${group} is ordered [${sorted.join(', ')}], expected 1..${sorted.length}`]
  })
}

/** Each part's last lesson ends with a Stretch step (the part's create task); no other lesson has one. */
export function stretchProblems(files: string[]): string[] {
  const byPart = new Map<string, { order: number; file: string }[]>()
  for (const f of files) {
    const fm = frontmatter(readFileSync(f, 'utf8'))
    byPart.set(fm.group ?? '', [...(byPart.get(fm.group ?? '') ?? []), { order: Number(fm.order), file: f }])
  }
  return [...byPart].flatMap(([group, list]) => {
    const last = Math.max(...list.map((l) => l.order))
    return list.flatMap(({ order, file }) => {
      const has = h2s(body(readFileSync(file, 'utf8'))).includes(STRETCH)
      if (order === last && !has) return [`stretch: ${group}'s last lesson (${basename(file)}) has no ## ${STRETCH}`]
      if (order !== last && has) return [`stretch: ${basename(file)} isn't ${group}'s last lesson but has ## ${STRETCH}`]
      return []
    })
  })
}
