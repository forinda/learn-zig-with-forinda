// Renders ```mermaid code blocks as diagrams. @clarusjs/content outputs them as
// <div class="code-block language-mermaid">…<code>diagram text</code>; without JavaScript the
// text stays readable. Mermaid itself loads only on pages that have a diagram.
// A MutationObserver covers pages swapped in by fragment navigation.
const MERMAID = 'https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs'
let mermaid
let n = 0

async function render() {
  const blocks = [...document.querySelectorAll('div.code-block.language-mermaid:not([data-rendered])')]
  if (!blocks.length) return
  blocks.forEach((b) => b.setAttribute('data-rendered', ''))
  if (!mermaid) {
    mermaid = (await import(MERMAID)).default
    // the site's text font and a readable size (mermaid's default is small once a diagram is scaled to the column)
    mermaid.initialize({ startOnLoad: false, theme: 'neutral', securityLevel: 'strict', themeVariables: { fontSize: '16px', fontFamily: "'Geist Variable', ui-sans-serif, system-ui, sans-serif" } })
  }
  for (const block of blocks) {
    const text = block.querySelector('code')?.textContent ?? ''
    try {
      // render() draws off-screen, so diagrams in hidden lesson steps get their real size.
      const { svg } = await mermaid.render(`diagram-${++n}`, text)
      const figure = document.createElement('figure')
      figure.className = 'diagram'
      figure.innerHTML = svg
      block.replaceWith(figure)
    } catch (e) {
      console.warn('diagram failed to render; showing its source', e)
    }
  }
}

render()
new MutationObserver(render).observe(document.body, { childList: true, subtree: true })
