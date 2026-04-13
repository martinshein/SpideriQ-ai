# SpiderPublish — AI Agent Context

This project uses SpiderPublish (SpiderIQ's content platform) to build, manage, and deploy websites.

## MCP Setup

The `.mcp.json` in this project connects to SpiderIQ. After IDE restart, you have 146+ tools.

## Authentication

Run `npx @spideriq/cli auth whoami --registry https://npm.spideriq.ai` to check auth status.
If not authenticated: `npx @spideriq/cli auth request --email admin@company.com --registry https://npm.spideriq.ai`

## Build a Site

1. **Read the reference first:** Use `template_get_help` MCP tool (or `GET /api/v1/content/help?format=yaml`)
2. **Settings:** `PATCH /api/v1/dashboard/content/settings` — site_name, primary_color, logo
3. **Navigation:** `PUT /api/v1/dashboard/content/navigation/header` — menu items
4. **Pages:** `POST /api/v1/dashboard/content/pages` — create with blocks
5. **Publish:** `POST /api/v1/dashboard/content/pages/{id}/publish`
6. **Theme:** `POST /api/v1/dashboard/templates/apply-theme` — apply "default"
7. **Deploy:** `POST /api/v1/dashboard/content/deploy` — live in ~2-5 seconds

## Key Rules

- **Always read `/content/help` first** — it has every block type, Liquid filter, and template variable
- **Use `format=yaml`** on GET requests — saves 40-76% tokens
- **Block types:** hero, features_grid, cta_section, testimonials, pricing_table, faq, stats_bar, rich_text, image, video_embed, code_example, logo_cloud, comparison_table, spacer, component
- **Page templates:** default, landing, feature, legal, dynamic_landing
- **Public endpoints** (GET /content/*) need no auth — use `X-Content-Domain` header
- **Dashboard endpoints** (POST/PATCH /dashboard/content/*) need Bearer auth

## Components (Shadow DOM — 4 Tiers)

Reusable UI blocks with automatic CSS isolation. Tier is auto-detected from fields:

| Tier | Name | Fields | Best For |
|------|------|--------|----------|
| 1 | Static | `html_template` + `css` | Heroes, footers, content |
| 2 | Interactive | + `js` | Accordions, tabs, counters |
| 3 | Rich | + `dependencies` | GSAP animations, carousels, charts |
| 4 | App | + `framework` + `source_code` | React/Vue/Svelte apps |

### Component Rules
- **CSS is isolated** via Shadow DOM — no leaks, no Tailwind, write plain CSS in `css` field
- **Use `var(--primary)`** for theme colors — auto-injected into every component
- **JS scoping (Tier 2+):** `root.querySelector()` only, never `document.querySelector()`. `root` is the shadowRoot, `props` is the merged props object
- **CDN libraries (Tier 3):** set `dependencies` array with allowlist keys. Check `GET /content/cdn-allowlist` for available libraries (gsap, chartjs, swiper, lottie, etc.)
- **Framework (Tier 4):** set `framework` (react/vue/svelte) + `source_code`. Publish returns 202 (async build). Poll `build-status` endpoint
- **Props:** define `props_schema` (JSON Schema) + `default_props`. Block props override defaults
- **Status flow:** draft → published → archived. Only published components render on live pages

### Component API
```
POST   /dashboard/content/components           — create
PATCH  /dashboard/content/components/{id}      — update
POST   /dashboard/content/components/{id}/publish  — publish (202 for Tier 4)
GET    /dashboard/content/components/{id}/build-status  — Tier 4 build status
POST   /dashboard/content/components/{id}/rebuild       — Tier 4 re-build
GET    /content/components                     — list published (public)
GET    /content/cdn-allowlist                  — list CDN libraries (public)
```

### Using Components in Pages
```json
{ "type": "component", "component_slug": "hero-gradient", "component_version": "1.0.0", "props": { "headline": "Welcome" } }
```

### Component Examples
Ready-to-POST JSON payloads in `components/`:
- `hero-gradient.json` — Tier 1: gradient hero with CTA
- `pricing-cards.json` — Tier 1: 3-tier pricing cards
- `faq-accordion.json` — Tier 2: interactive accordion with scoped JS
- `stats-animated.json` — Tier 3: GSAP ScrollTrigger animated counters
- `pricing-toggle.json` — Tier 4: React monthly/annual pricing toggle

## Dynamic Landing Pages

For personalized outreach pages:
- Template: `dynamic_landing`
- URL: `/lp/{page_slug}/{salesperson}/{google_place_id}`
- Variables: `{{ lead.name }}`, `{{ lead.city }}`, `{{ salesperson.name }}`
- Lead data fetched automatically from IDAP by Place ID

## Uploading Images

```bash
# Import from URL (recommended)
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }

# Returns: { "url": "https://media.cdn.spideriq.ai/..." }
# Use in blocks: { "type": "image", "data": { "url": "https://media.cdn.spideriq.ai/..." } }
```

## IDAP Data Access

Read CRM data (businesses, emails, contacts, phones):
- `GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml`
- `GET /api/v1/idap/businesses/{id}?include=emails,phones,domains,contacts`
- `GET /api/v1/idap/businesses/resolve?place_id={google_place_id}`
- `POST /api/v1/idap/businesses/{id}/flags` — flag leads as qualified/contacted

## Templates

Ready-to-submit payloads are in the `templates/` directory:
- `templates/homepage.json` — company homepage
- `templates/blog-setup.json` — blog with author + posts
- `templates/dynamic-landing.json` — personalized outreach page

Submit any template: read the JSON, then `POST /api/v1/dashboard/content/pages` with the payload.

## API Base

- Production: `https://spideriq.ai/api/v1`
- Docs: `https://docs.spideriq.ai`
- Site Builder Docs: `https://docs.spideriq.ai/site-builder/overview`
- Component Builder: `https://docs.spideriq.ai/site-builder/component-builder`
- Component Tiers: `https://docs.spideriq.ai/site-builder/component-tiers`
- Agent Reference: `https://docs.spideriq.ai/site-builder/component-agents-reference`
- Health: `GET /api/v1/system/health`
- Full Reference: `GET /api/v1/content/help` (~2,867 tokens YAML)

## GitHub

- Public repo: https://github.com/martinshein/SpideriQ-ai/tree/main/SpiderPublish
