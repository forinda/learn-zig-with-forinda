import { defineConfig } from 'vite'
import clarusjs from 'clarusjs/vite'
import markdown from '@clarusjs/content'
import { themeDocs } from '@clarusjs/theme-docs/vite.js'
import { schemas } from './src/schemas.ts'

// GitHub Pages serves the site under /learn-zig-with-forinda/ (BASE in the deploy workflow); locally it's at /.
export default defineConfig({
  base: process.env.BASE ?? '/',
  plugins: [
    // The sidebar from src/pages (frontmatter `group` + `order`), search, and llms.txt for AI tools.
    themeDocs({
      llms: {
        title: 'Zero to Hero in Zig',
        summary: 'A course from zero programming to confident Zig 0.17, building a terminal cycling race: basics, memory, data structures, simulation, AI, file I/O, the build system, C libraries and networking.',
        site: 'https://forinda.github.io/learn-zig-with-forinda',
      },
    }),
    clarusjs({
      // Moving between pages swaps the page instead of reloading it.
      fragments: true,
      head: {
        titleTemplate: '%s · Zero to Hero in Zig',
        // ```mermaid blocks become diagrams in the browser (public/diagrams.js).
        tags: [
          ['link', { rel: 'icon', href: '/logo.svg', type: 'image/svg+xml' }],
          ['script', { type: 'module', src: '/diagrams.js' }],
        ],
      },
      // Markdown pages (src/pages/**/*.md), in the docs layout (lessons pick the lesson layout in frontmatter).
      sources: [markdown({
        layout: '/src/layouts/docs.tscl',
        // Components in src/components are used by tag in Markdown, no @import needed.
        components: ['/src/components'],
        // ::: tip / ::: warning blocks and > [!NOTE] alerts.
        container: { tag: 'callout', from: '@clarusjs/theme-docs/callout.tscl' },
        // Line numbers on code blocks (not on shell commands: those are copied, not referred to by line).
        lineNumbers: true,
        // A copy button on every code block: readers copy the code into their own project.
        copy: { tag: 'copy', from: '@clarusjs/theme-docs/copy.tscl' },
        // ::: quiz blocks in lessons render through the theme's quiz (its options are an island).
        quiz: { tag: 'quiz', from: '@clarusjs/theme-docs/quiz.tscl' },
        // Every page's frontmatter is checked (src/schemas.ts); lessons need their step, minutes and competency.
        schema: schemas,
      })],
    }),
  ],
})
