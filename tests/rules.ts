// The rules every lesson follows (tests/pages.test.ts runs them on src/pages/learn and on a broken fixture).
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { basename, dirname, join } from 'node:path'
import { parts } from '../src/course.ts'

export const STEPS_E = ['Engage', 'Explore', 'Explain', 'Elaborate', 'Evaluate'] as const
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

/** The body without fenced code (headings inside code samples aren't steps). */
const prose = (body: string) => body.replace(/^(```|~~~)[\s\S]*?^\1/gm, '')

/** What's wrong with one lesson (empty: nothing). `stepsDir`: code/steps. */
export function lessonProblems(file: string, stepsDir: string): string[] {
  const text = readFileSync(file, 'utf8')
  const fm = frontmatter(text)
  const body = text.replace(/^---\n[\s\S]*?\n---\n/, '')
  const problems: string[] = []

  const part = parts.find((p) => p.title === fm.group)
  if (!part) problems.push(`group: "${fm.group}" is not a part`)
  else if (basename(dirname(file)) !== part.slug) problems.push(`folder: a "${part.title}" lesson belongs in learn/${part.slug}/`)

  const h2 = [...prose(body).matchAll(/^## (.+)$/gm)].map((m) => m[1]!.trim())
  if (h2.join('|') !== STEPS_E.join('|')) problems.push(`5E: steps are [${h2.join(', ')}], expected [${STEPS_E.join(', ')}]`)

  const evaluate = body.split(/^## Evaluate\s*$/m)[1] ?? ''
  if (!/^:::+ *quiz\b/m.test(evaluate)) problems.push('evaluate: no ::: quiz')
  if (!/zig build test/.test(evaluate)) problems.push('evaluate: no zig build test')
  if (!/^### Exercise/m.test(evaluate)) problems.push('evaluate: no ### Exercise')

  if (!fm.step || !existsSync(join(stepsDir, fm.step))) problems.push(`step: code/steps/${fm.step} doesn't exist`)
  if (part && !part.competencies.includes(fm.competency ?? '')) problems.push(`competency: "${fm.competency}" isn't listed for ${part.title} in src/course.ts`)

  for (const m of body.matchAll(/^```zig[^\n]*\n([\s\S]*?)^```/gm)) {
    const lines = m[1]!.split('\n').length - 1
    if (lines > MAX_ZIG_LINES) problems.push(`code: a ${lines}-line zig block; game code comes from its step folder (<<< @/code/steps/...)`)
  }
  return problems
}

/** Lessons of each part ordered 1..n with no gaps or repeats. */
export function orderProblems(files: string[]): string[] {
  const byPart = new Map<string, number[]>()
  for (const f of files) {
    const fm = frontmatter(readFileSync(f, 'utf8'))
    byPart.set(fm.group ?? '', [...(byPart.get(fm.group ?? '') ?? []), Number(fm.order)])
  }
  return [...byPart].flatMap(([group, orders]) => {
    const sorted = [...orders].sort((a, b) => a - b)
    return sorted.every((o, i) => o === i + 1) ? [] : [`order: ${group} lessons are ordered [${sorted.join(', ')}], expected 1..${sorted.length}`]
  })
}
