// This site's navigation and theme settings: what @clarusjs/theme-docs shows in the header, sidebar and footer.
import { pagesNav, type ThemeConfig } from '@clarusjs/theme-docs/nav.ts'
import pages from 'virtual:theme-docs/pages'
import { sidebar } from './sidebar.ts'

export const sections = pagesNav(sidebar, pages)

export const theme: ThemeConfig = {
  brand: { text: 'Zero to Hero', accent: ' in Zig', logo: '/logo.svg' },
  sections,
  menuLinks: sections.map((s) => ({ label: s.title, href: s.href })),
  search: true,
  viewTransitions: true,
  // Lessons are the Course section's pages; progress (XP, quiz answers) stays in the browser.
  learn: { section: 'learn', progress: '/learn/progress' },
  pages,
  footer: 'Zero to Hero in Zig: learn Zig 0.17 by building a terminal racing game.',
}
