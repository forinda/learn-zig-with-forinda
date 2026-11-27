// The header's sections and each one's sidebar groups, from src/groups.ts. Pages fill the groups:
// src/pages/<section>/**/*.md, frontmatter `group` and `order`. A section's link is its first page.
import type { Section } from '@clarusjs/theme-docs/nav.ts'
import { groups, sections, type SectionKey } from './groups.ts'

export const sidebar: Section[] = (Object.keys(sections) as SectionKey[]).map((key) => ({
  key,
  title: sections[key],
  href: '',
  groups: groups[key].map((g) => ({ ...g, items: [] })),
}))
