# SpiderPublish — AGENTS.md

> Full version: [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents)
> Component Builder: [docs.spideriq.ai/site-builder/component-builder](https://docs.spideriq.ai/site-builder/component-builder)
> Tiers Reference: [docs.spideriq.ai/site-builder/component-tiers](https://docs.spideriq.ai/site-builder/component-tiers)
> Agent Reference: [docs.spideriq.ai/site-builder/component-agents-reference](https://docs.spideriq.ai/site-builder/component-agents-reference)

## Quick Reference

### Setup
1. Copy `.mcp.json` to your project root
2. Copy `CLAUDE.md` to your project root
3. Restart your IDE
4. Authenticate: `npx @spideriq/cli auth request --email admin@company.com --registry https://npm.spideriq.ai`

### Build a Site
```
template_get_help          → Read the full content reference
content_create_page        → Create pages with blocks
content_publish_page       → Publish pages
template_apply_theme       → Apply "default" theme
content_deploy_site        → Deploy to Cloudflare edge (2-5s)
```

### Block Types
`hero`, `features_grid`, `cta_section`, `testimonials`, `pricing_table`, `faq`, `stats_bar`, `rich_text`, `image`, `video_embed`, `code_example`, `logo_cloud`, `comparison_table`, `spacer`, `component`

### Page Templates
`default`, `landing`, `feature`, `legal`, `dynamic_landing`

### Upload Images
```bash
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }
```

### Dynamic Landing Pages
URL: `/lp/{page_slug}/{salesperson}/{google_place_id}`
Variables: `{{ lead.name }}`, `{{ lead.city }}`, `{{ lead.rating }}`, `{{ salesperson.name }}`

### IDAP (CRM Data)
```bash
GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml
GET /api/v1/idap/businesses/resolve?place_id=0x47e66fdad6f1cc73:0x341211b3fccd79e1
```

---

## Components (Shadow DOM — 4 Tiers)

Reusable UI blocks with automatic CSS isolation. The tier is detected from which fields are present:

| Tier | Name | What to Set | Best For |
|------|------|-------------|----------|
| 1 | Static | `html_template` + `css` | Heroes, footers, content sections |
| 2 | Interactive | + `js` | Accordions, tabs, counters, toggles |
| 3 | Rich | + `dependencies` | GSAP animations, carousels, charts |
| 4 | App | + `framework` + `source_code` | React/Vue/Svelte apps |

### Create a Component
```bash
POST /api/v1/dashboard/content/components
{ "slug": "hero-gradient", "name": "Gradient Hero", "category": "hero",
  "html_template": "<section><h1>{{ props.headline }}</h1></section>",
  "css": "section { background: linear-gradient(135deg, var(--primary), #000); padding: 5rem 2rem; color: white; }",
  "props_schema": { "type": "object", "properties": { "headline": { "type": "string" } }, "required": ["headline"] } }
```

### Add JavaScript (Tier 2)
```json
{ "js": "root.querySelector('button').addEventListener('click', () => { /* ... */ });" }
```
JS receives `root` (shadowRoot) and `props`. Use `root.querySelector()`, never `document.querySelector()`.

### Add CDN Libraries (Tier 3)
```json
{ "dependencies": ["gsap", "gsap/ScrollTrigger"], "js": "gsap.registerPlugin(ScrollTrigger); /* ... */" }
```
Available: `gsap`, `gsap/ScrollTrigger`, `gsap/Flip`, `animejs`, `alpinejs`, `chartjs`, `lottie`, `swiper`, `countup`, `three`. Check `GET /content/cdn-allowlist`.

### Framework Components (Tier 4)
```json
{ "framework": "react", "source_code": "import React from 'react';\nexport default function App(props) { return <h1>{props.headline}</h1>; }" }
```
Publish returns 202 (async build). Poll `GET .../build-status` until `success`.

### Use in Pages
```json
{ "type": "component", "component_slug": "hero-gradient", "props": { "headline": "Welcome" } }
```

### Component Examples
Ready-to-POST examples in `components/`:
- `hero-gradient.json` — Tier 1: gradient hero
- `pricing-cards.json` — Tier 1: 3-tier pricing
- `faq-accordion.json` — Tier 2: interactive FAQ accordion
- `stats-animated.json` — Tier 3: GSAP animated stats counter
- `pricing-toggle.json` — Tier 4: React pricing with monthly/annual toggle

---

### Rate Limits
- API: 100 requests/minute
- Jobs: 10 submissions/minute
- Always use `?format=yaml` (saves 40-76% tokens)

## Tutorials
- [Build a Homepage](https://docs.spideriq.ai/site-builder/tutorial-homepage)
- [Build a Blog](https://docs.spideriq.ai/site-builder/tutorial-blog)
- [Personalized Landing Page](https://docs.spideriq.ai/site-builder/tutorial-dynamic-landing)

## Full Documentation
- [AI Agent Guide](https://docs.spideriq.ai/site-builder/agents)
- [Component Builder Guide](https://docs.spideriq.ai/site-builder/component-builder)
- [Component Tiers Reference](https://docs.spideriq.ai/site-builder/component-tiers)
- [Component Agent Reference](https://docs.spideriq.ai/site-builder/component-agents-reference)
- [Gotchas & Best Practices](https://docs.spideriq.ai/site-builder/learnings)
- [Deploy Guide](https://docs.spideriq.ai/site-builder/deployment)
- [API Reference](https://docs.spideriq.ai/api-reference/introduction)
