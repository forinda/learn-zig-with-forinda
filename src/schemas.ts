// Frontmatter rules for every page: markdown({ schema }) in vite.config.ts fails the build when one is broken.
import type { StandardSchema } from '@clarusjs/content'
import { groups } from './groups.ts'

type Issue = { message: string; path: string[] }
type Data = Record<string, unknown>

const text = (d: Data, key: string, issues: Issue[]) => {
  if (typeof d[key] !== 'string' || !(d[key] as string).trim()) issues.push({ message: 'Expected a non-empty string', path: [key] })
}

function schema(vendorRules: (d: Data, issues: Issue[]) => void): StandardSchema<Data> {
  return {
    '~standard': {
      version: 1,
      vendor: 'forinda-zig-learn',
      validate(value) {
        const d = (value ?? {}) as Data
        const issues: Issue[] = []
        vendorRules(d, issues)
        return issues.length ? { issues } : { value: d }
      },
    },
  }
}

const page = (allowed: readonly string[]) => (d: Data, issues: Issue[]) => {
  text(d, 'title', issues)
  text(d, 'description', issues)
  if (!allowed.includes(d.group as string)) issues.push({ message: `Expected one of: ${allowed.join(', ')}`, path: ['group'] })
  if (!Number.isInteger(d.order)) issues.push({ message: 'Expected a whole number', path: ['order'] })
}

const startPage = page(groups.start.map((g) => g.title))
const coursePage = page(groups.learn.map((g) => g.title))
const stepName = (d: Data, issues: Issue[]) => {
  if (typeof d.step !== 'string' || !/^\d{2}-[a-z0-9-]+$/.test(d.step)) issues.push({ message: 'Expected a step folder name like 01-hello', path: ['step'] })
}

/** A guide page: teaching, in the docs layout, paired with a code step. */
const guidePage = (d: Data, issues: Issue[]) => {
  page(groups.guide.map((g) => g.title))(d, issues)
  stepName(d, issues)
}

/** A lesson: checks understanding, in the lesson layout, one `##` step at a time, paired with a code step. */
const lesson = (d: Data, issues: Issue[]) => {
  coursePage(d, issues)
  if (d.layout !== '/src/layouts/lesson.tscl') issues.push({ message: 'Expected /src/layouts/lesson.tscl', path: ['layout'] })
  if (d.steps !== true) issues.push({ message: 'Expected true', path: ['steps'] })
  if (!Number.isInteger(d.minutes) || (d.minutes as number) <= 0) issues.push({ message: 'Expected a positive whole number', path: ['minutes'] })
  stepName(d, issues)
  text(d, 'competency', issues)
}

/** One schema per folder, keyed by the glob vite.config.ts applies it to (the first match wins). */
export const schemas = {
  'guide/**/*.md': schema(guidePage),
  'learn/**/*.md': schema(lesson),
  'start/**/*.md': schema(startPage),
  'index.md': schema(startPage),
}
