---
title: "Hello, World"
date: 2026-10-13T09:00:00-05:00
draft: false
math: true
---

This is the first post on this blog, exported from Org mode to Markdown
with [ox-hugo](https://github.com/kaushalmodi/ox-hugo) and built into static HTML with [Hugo](https://gohugo.io/).


## Math

Inline math such as \(E = mc^2\) and display math both render with
self-hosted [KaTeX](https://katex.org/) -- no CDN, no third-party scripts.

\[
\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}
\]


## An interactive figure

The figure below is served by the self-hosted Shiny app in
`shiny-apps/example/` via the self-hosted Shiny Server, embedded with the
`shiny` shortcode:

{{< shiny app="example" height="650" >}}


## Subscribe

{{< subscribe >}}
