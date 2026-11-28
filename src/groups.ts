// The site's sections and each one's sidebar groups, in order. src/sidebar.ts builds the sidebar from them;
// src/schemas.ts only accepts these titles in a page's `group`, so a typo fails the build. The Guide teaches and the
// Course checks understanding: both are grouped by the 13 parts. The course is one section (`learn`) so the lesson
// layout numbers every lesson across it.
import type { GroupIcon } from '@clarusjs/theme-docs/nav.ts'

type G = readonly { title: string; icon: GroupIcon }[]

export const sections = {
  start: 'Start here',
  guide: 'Guide',
  learn: 'Course',
} as const

export type SectionKey = keyof typeof sections

/** The 13 parts, in order (the Guide's and the Course's groups). */
const parts = [
  { title: 'Start', icon: 'rocket' },
  { title: 'Basics', icon: 'book' },
  { title: 'Structure', icon: 'layers' },
  { title: 'Memory', icon: 'box' },
  { title: 'Data structures and algorithms', icon: 'grid' },
  { title: 'A terminal game', icon: 'terminal' },
  { title: 'Simulation', icon: 'chart' },
  { title: 'AI', icon: 'sparkles' },
  { title: 'File I/O', icon: 'file' },
  { title: 'The build system', icon: 'wrench' },
  { title: 'C libraries', icon: 'code' },
  { title: 'Networking', icon: 'message' },
  { title: 'Hero', icon: 'shield' },
] as const

export const groups = {
  start: [{ title: 'Welcome', icon: 'rocket' }],
  guide: parts,
  learn: parts,
} as const satisfies Record<SectionKey, G>
