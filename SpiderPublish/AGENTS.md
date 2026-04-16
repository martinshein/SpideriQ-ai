# SpiderPublish — AGENTS.md

> Full version: [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents)
> **Session Binding (Phase 11+12):** [docs.spideriq.ai/site-builder/sessions](https://docs.spideriq.ai/site-builder/sessions)
> **Deploy Safely (preview→confirm):** [docs.spideriq.ai/site-builder/deploy-safely](https://docs.spideriq.ai/site-builder/deploy-safely)
> Component Builder: [docs.spideriq.ai/site-builder/component-builder](https://docs.spideriq.ai/site-builder/component-builder)
> Tiers Reference: [docs.spideriq.ai/site-builder/component-tiers](https://docs.spideriq.ai/site-builder/component-tiers)
> Agent Reference: [docs.spideriq.ai/site-builder/component-agents-reference](https://docs.spideriq.ai/site-builder/component-agents-reference)

**Current package versions:** `@spideriq/cli@0.8.3`, `@spideriq/mcp-publish@0.1.0` — **87 tools** (atomic SpiderPublish slice). The kitchen-sink `@spideriq/mcp@0.8.4` (157 tools) is still published for backward compatibility, but `@spideriq/mcp-publish` is what the starter kit's `.mcp.json` now ships — under the ~128-tool injection limit enforced by some IDE/LLM stacks, and less context burn per message.

## Quick Reference

### Setup
1. Copy `.mcp.json` to your project root
2. Copy `CLAUDE.md` to your project root
3. Restart your IDE
4. Authenticate: `npx @spideriq/cli auth request --email admin@company.com`
5. **Bind this directory to a project** (mandatory): `npx @spideriq/cli use <project>` — writes `./spideriq.json`

From step 5 on, every dashboard call auto-rewrites to `/api/v1/dashboard/projects/{project_id}/...` and destructive tools default to `dry_run=true` (preview → confirm). Skipping step 5 falls back to legacy URLs that stop working 2026-05-14.

### Build a Site (follow ALL steps)
```
template_get_help                     → 0. Read the full content reference (tasks index, chrome_override, theme_palette, session_binding, deploy_workflow)
content_update_settings               → 1. REQUIRED: Set site_name + optional theme palette (see Theme Palette below)
   └─ default dry_run=true            →    First call returns preview + confirm_token. Call again with confirm_token to apply.
content_update_navigation             → 2. Set up header menu items (not gated)
content_create_page                   → 3. Create pages with blocks (slug "home" for homepage; template picks layout — see Page Templates; not gated)
content_publish_page                  → 4. REQUIRED: Publish at least 1 page
   └─ default dry_run=true            →    Same two-step flow
template_apply_theme                  → 5. REQUIRED: Apply "default" theme
   └─ default dry_run=true            →    Same two-step flow
content_deploy_readiness              → 6. Check if site is ready to deploy (not gated; read-only)
content_deploy_site_preview           → 7. Returns preview_url + confirm_token. Open preview_url in a browser.
content_deploy_site_production        → 8. Pass confirm_token from step 7. Deploys to Cloudflare edge (2-5s).
```

### Customize Header/Footer (NEW in v0.8.2)

Three tools for per-client theme-file overrides. THE supported path for site-chrome customization — do NOT build JS Shadow-DOM-escape hacks.

```
content_get_section_source            → Read current Liquid source for header | footer | layout | head | hero
content_override_section              → Upload custom Liquid that wins over the default theme
content_apply_layout_preset           → Apply a canned layout/theme.liquid: default | blank | landing
```

Typical workflow to "make the footer dark":
```
1. content_get_section_source({section: "footer"}) → returns { path, source, is_override }
2. modify the returned Liquid in your own context
3. content_override_section({section: "footer", liquid: modified})
4. content_deploy_site_preview() → content_deploy_site_production(confirm_token)
```

Used in production by danmagi.com, sms-chemicals.com, mail.spideriq.ai.

### Deploy Requirements

Deploy **rejects** if any blocking item is missing. Always call `content_deploy_readiness` first.

| Requirement | MCP Tool |
|-------------|----------|
| Site settings with `site_name` | `content_update_settings` |
| At least 1 verified domain | `content_add_domain` |
| At least 1 template (theme applied) | `template_apply_theme` |
| At least 1 published page | `content_publish_page` |

### Error Responses (Phase 11+12)

| Status | Cause | Fix |
|---|---|---|
| `403 TokenInvalid` | `confirm_token` doesn't exist | Issue a fresh one via `dry_run=true` |
| `403 TokenClientMismatch` | Token was for a different project | Wrong directory — check `spideriq.json` |
| `403 TokenActionMismatch` | Token was for a different action | Don't reuse tokens across operations |
| `409 TokenConsumed` | Single-use token already used | Issue a fresh one |
| `410 TokenExpired` | Past expires_at (7 days) | Issue a fresh one |

### Common Mistakes

- **Forget `spideriq use`** → every call carries `Deprecation: true` header; will 410 after 2026-05-14
- **Call destructive tool without `confirm_token`** → you get a preview envelope instead of a mutation (by design)
- **Set `primary_color: "#000000"` expecting dark background** → primary_color is the ACCENT only; use `surface_color` + `body_text_color` + `heading_color` for the page palette (see Theme Palette)
- **Create component with slug "footer" to override the default** → Components ≠ theme sections. Use `content_override_section`
- **Build `document.querySelector('body > footer').style...` from component JS** → breaks on cache flush, FOUC. Use `content_override_section` instead
- **Reuse a `confirm_token`** → 409 on the second call (single-use)
- **Component slug reuse** → 400 error. Use update or increment version.
- **Deploying before publishing pages** → 400 "Missing: Published Pages"
- **Skipping settings** → 400 "Missing: Site Settings"
- **Skipping theme** → 400 "Missing: Theme / Templates"

### Block Types
`hero`, `features_grid`, `cta_section`, `testimonials`, `pricing_table`, `faq`, `stats_bar`, `rich_text`, `image`, `video_embed`, `code_example`, `logo_cloud`, `comparison_table`, `spacer`, `component`

### Page Templates
`default` (header + footer), `landing` (full-bleed main), `blank` (no chrome at all — full canvas), `dynamic_landing` (/lp/ routes with lead data). Unknown values fall back to `default`.

### Theme Palette (NEW in v0.8.2)

6 settings fields control the site palette. Null values = default dark.

| Field | Purpose | Default |
|---|---|---|
| `primary_color` | Accent (CTAs, links, borders) | `#eebf01` |
| `surface_color` | Body / main background | `#0A0A0B` |
| `surface_elevated_color` | Card / panel background | `#111113` |
| `subtle_color` | Border / subtle bg | `#1A1A1D` |
| `body_text_color` | Default body text | `#e5e5e5` |
| `heading_color` | Headings / logo text | `#ffffff` |

Make the whole site light: set `surface_color: "#ffffff"`, `surface_elevated_color: "#f5f5f5"`, `subtle_color: "#e5e5e5"`, `body_text_color: "#18181b"`, `heading_color: "#0a0a0a"`.

### Upload Images
```bash
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }
```

### Dynamic Landing Pages
URL: `/lp/{page_slug}/{google_place_id}` or `/lp/{page_slug}/{salesperson}/{google_place_id}`

**Use flat email-marketing merge tags** (Mailchimp/HubSpot/ActiveCampaign style — every LLM already knows them):
`{{ firstname }}`, `{{ company_name }}`, `{{ city }}`, `{{ industry }}`, `{{ rating }}`, `{{ email }}`, `{{ phone }}`, `{{ logo }}`, `{{ team_size }}`, `{{ founded }}`, `{{ revenue }}`, plus `{% for %}` arrays for `emails`, `phones`, `contacts`, `officers`, `pain_points`, `categories`. ~40 tags total.

**Full reference (read first):** [MERGE-TAGS.md](./MERGE-TAGS.md) · live at https://docs.spideriq.ai/site-builder/merge-tags/ · API: `GET /api/v1/content/variables?format=yaml` · MCP: `content_get_variables` (in `@spideriq/mcp-publish@0.1.0+` and `@spideriq/mcp@0.8.3+`).

**Preview without real data:** `/lp/{slug}/demo` — serves the built-in Mario's Pizzeria fixture with every tag populated.

Power-user: the raw `lead.*` nested shape is still in scope for fields not surfaced as merge tags. `{{ salesperson.* }}` also available when the URL includes a salesperson slug.

Ready-to-run end-to-end: [`examples/personalized-landing.sh`](./examples/personalized-landing.sh).

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
| 3 | Rich | + `dependencies` | GSAP animations, carousels, charts, scroll-scrubbed heroes |
| 4 | App | + `framework` + `source_code` | React/Vue/Svelte apps |

All destructive component operations (`publish`, `archive`, `delete`) default to `dry_run=true` in MCP — call twice with `confirm_token` to actually mutate.

### Create a Component
```bash
POST /api/v1/dashboard/projects/{pid}/content/components
{ "slug": "hero-gradient", "name": "Gradient Hero", "category": "hero",
  "html_template": "<section><h1>{{ props.headline }}</h1></section>",
  "css": "section { background: linear-gradient(135deg, var(--primary), var(--surface)); padding: 5rem 2rem; color: var(--heading); }",
  "props_schema": { "type": "object", "properties": { "headline": { "type": "string" } }, "required": ["headline"] } }
```

### Add JavaScript (Tier 2)
```json
{ "js": "root.querySelector('button').addEventListener('click', () => { /* ... */ });" }
```
JS receives `root` (shadowRoot) and `props`. Use `root.querySelector()`, never `document.querySelector()`. Never use JS to modify site chrome — use `content_override_section` instead.

### Add CDN Libraries (Tier 3)
```json
{ "dependencies": ["gsap", "gsap/ScrollTrigger"], "js": "gsap.registerPlugin(ScrollTrigger); /* ... */" }
```
Available: `gsap`, `gsap/ScrollTrigger`, `gsap/Flip`, `animejs`, `alpinejs`, `chartjs`, `lottie`, `swiper`, `countup`, `three`. Check `GET /content/cdn-allowlist`. **Framer Motion is NOT allowlisted** (React-only — use Tier 4 if you need it).

### Framework Components (Tier 4)
```json
{ "framework": "react", "source_code": "import React from 'react';\nexport default function App(props) { return <h1>{props.headline}</h1>; }" }
```
Publish returns 202 (async build). Poll `GET .../build-status` until `success`.

### Use in Pages
```json
{ "type": "component", "component_slug": "hero-gradient", "props": { "headline": "Welcome" } }
```

### Scroll-Linked Hero (image sequence)

The canonical pattern for cinematic scroll-scrubbed heroes (like danmagi.com's opening section):

```
Tier 3 component, deps: ["gsap", "gsap/ScrollTrigger"]
HTML: <section class="seq"><div class="sticky"><canvas id="c"></canvas></div></section>
CSS:  .seq { height: 400vh } .sticky { position: sticky; top: 0; height: 100vh }
JS:   preload 120 frames → gsap.to({frame}, { scrollTrigger: { trigger, start, end, scrub: 1 }, onUpdate: drawImage })
```

Pair with `template: "blank"` so the hero fills the viewport without the default header/footer. See CLAUDE.md `Scroll-Linked Hero` section for the full recipe.

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
- [Session Binding](https://docs.spideriq.ai/site-builder/sessions)
- [Deploy Safely](https://docs.spideriq.ai/site-builder/deploy-safely)
- [Component Builder Guide](https://docs.spideriq.ai/site-builder/component-builder)
- [Component Tiers Reference](https://docs.spideriq.ai/site-builder/component-tiers)
- [Component Agent Reference](https://docs.spideriq.ai/site-builder/component-agents-reference)
- [Gotchas & Best Practices](https://docs.spideriq.ai/site-builder/learnings)
- [Deploy Guide](https://docs.spideriq.ai/site-builder/deployment)
- [API Reference](https://docs.spideriq.ai/api-reference/introduction)
