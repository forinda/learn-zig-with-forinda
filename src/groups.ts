// The site's sections and each one's sidebar groups, in order. src/sidebar.ts builds the sidebar from them;
// src/schemas.ts only accepts these titles in a page's `group`, so a typo fails the build. The course is one
// section (`learn`) so the lesson layout numbers every lesson across it; its groups are the 13 parts.
import type { GroupIcon } from '@clarusjs/theme-docs/nav.ts'

type G = readonly { title: string; icon: GroupIcon }[]

export const sections = {
  start: 'Start here',
  learn: 'Course',
} as const

export type SectionKey = keyof typeof sections

export const groups = {
  start: [{ title: 'Welcome', icon: 'rocket' }],
  learn: [
    { title: 'Start', icon: 'rocket' },
    { title: 'Basics', icon: 'book' },
    { title: 'Structure', icon: 'layers' },
    { title: 'Memory', icon: 'box' },
    { title: 'Data structures', icon: 'grid' },
    { title: 'A terminal game', icon: 'terminal' },
    { title: 'Simulation', icon: 'chart' },
    { title: 'AI', icon: 'sparkles' },
    { title: 'File I/O', icon: 'file' },
    { title: 'The build system', icon: 'wrench' },
    { title: 'C libraries', icon: 'code' },
    { title: 'Networking', icon: 'message' },
    { title: 'Hero', icon: 'shield' },
  ],
} as const satisfies Record<SectionKey, G>
