# SpiderPublish — AI Agent Context

This project uses SpiderPublish (SpiderIQ's content platform) to build, manage, and deploy websites.

---

## Multi-Tenant Safety (Phase 11+12) — **READ FIRST**

Every dashboard call you make is enforced across five independent tenant locks. The first step on any new project is binding this directory to a specific client. If you skip this, your calls fall back to legacy URLs that carry a `Deprecation: true` / `Sunset: 2026-05-14` response header and will stop working after that date.

### Before you do anything: bind this directory

```bash
# List projects your token can access
npx @spideriq/cli use --list --registry https://npm.spideriq.ai

# Bind — writes ./spideriq.json (commit it like .vercel/project.json)
npx @spideriq/cli use <project>   # short id cli_xxx, brand slug, or company name
```

After this, every dashboard URL auto-rewrites to `/api/v1/dashboard/projects/{project_id}/...` and the backend enforces that your PAT, the URL, and every resource you touch all agree on which tenant is in play. Mismatches return 403 — never a silent cross-tenant write.

### Destructive operations are two-step by default

MCP tools like `content_publish_page`, `content_delete_page`, `content_update_settings`, `template_apply_theme`, and `content_deploy_site` now default to **`dry_run=true`**. The first call returns a preview envelope with a `confirm_token`; the second call (same args + `confirm_token`) actually mutates.

```
content_publish_page({ page_id: "abc-123" })
  → { dry_run: true, preview: { slug: "pricing", will_become: "published" },
      confirm_token: "cft_…", expires_at: "…" }

content_publish_page({ page_id: "abc-123", confirm_token: "cft_…" })
  → real publish result
```

For deploys, use the split tools:

```
content_deploy_site_preview()                       → returns preview_url + confirm_token
content_deploy_site_production({ confirm_token })   → actually deploys
```

Full details: `docs.spideriq.ai/site-builder/sessions` and `docs.spideriq.ai/site-builder/deploy-safely`.

---

## MCP Setup

The `.mcp.json` in this project connects to SpiderIQ. After IDE restart, you have 152+ tools.

## Authentication

```bash
# Check auth
npx @spideriq/cli auth whoami --registry https://npm.spideriq.ai

# Request access (emails admin, wait for approval)
npx @spideriq/cli auth request --email admin@company.com --registry https://npm.spideriq.ai

# Bind directory to project (MANDATORY after auth — see top of file)
npx @spideriq/cli use <project> --registry https://npm.spideriq.ai
```

## Build a Site

All dashboard URLs below assume the CLI/MCP auto-injects `/projects/{pid}/` from `./spideriq.json`. If no binding is set they still work via legacy paths but with Deprecation headers.

1. **Read the reference first:** `template_get_help` MCP tool (or `GET /api/v1/content/help?format=yaml`) — now includes dedicated `session_binding` + `deploy_workflow` sections
2. **Settings:** `PATCH /dashboard/projects/{pid}/content/settings` — REQUIRED: site_name, primary_color, logo. Gated: first call with `?dry_run=true`, then `?confirm_token=cft_...`
3. **Navigation:** `PUT /dashboard/projects/{pid}/content/navigation/header` — menu items (not gated)
4. **Pages:** `POST /dashboard/projects/{pid}/content/pages` — create with blocks (slug `home` for homepage) (not gated)
5. **Publish:** `POST /dashboard/projects/{pid}/content/pages/{id}/publish` — REQUIRED: at least 1 published page. Gated: dry_run → confirm_token
6. **Theme:** `POST /dashboard/projects/{pid}/templates/apply-theme` — REQUIRED: apply `default`. Gated: dry_run → confirm_token
7. **Check readiness:** `content_deploy_readiness` MCP tool — verify all blocking checks pass
8. **Deploy:** two steps (replaces the old single-step deploy):
   - `POST /dashboard/projects/{pid}/content/deploy/preview` → returns `preview_url` + `confirm_token`
   - Review `preview_url` in a browser
   - `POST /dashboard/projects/{pid}/content/deploy/production?confirm_token=cft_...` → live in ~2-5 seconds

## Deploy Requirements (IMPORTANT)

Deploy **rejects** if any of these are missing:
- **Site settings** with `site_name` (step 2)
- **At least 1 verified domain** (add via `content_add_domain`)
- **At least 1 template** / theme applied (step 6)
- **At least 1 published page** (step 5)

**Always call `content_deploy_readiness` before previewing the deploy.**

## Error Responses (Phase 11+12)

| Status | Meaning | What to do |
|---|---|---|
| `403` + `TokenInvalid` | Your `confirm_token` doesn't exist or was fabricated | Call the endpoint with `dry_run=true` to get a fresh token |
| `403` + `TokenClientMismatch` | The token was issued for a different project | Check your `spideriq.json` — you're in the wrong directory |
| `403` + `TokenActionMismatch` | Token was issued for a different action | Don't reuse tokens across operations; issue a new one |
| `403` + `TokenResourceMismatch` | Token was issued for a different page/component | Same — issue per-resource |
| `409` + `TokenConsumed` | Token already used once (single-use) | Issue a fresh one via `dry_run=true` |
| `410` + `TokenExpired` | Past `expires_at` (default 7 days) | Issue a fresh one |

## Common Mistakes

| Mistake | What Happens | Fix |
|---------|-------------|-----|
| Forget `spideriq use` at the start | Deprecation header on every response, legacy URLs stop working 2026-05-14 | Run `spideriq use <project>` once, commit `spideriq.json` |
| Call destructive MCP tool without `confirm_token` or explicit `dry_run=false` | Returns a preview envelope instead of mutating | Feature, not bug — call again with the returned `confirm_token` |
| Call `content_deploy_site` instead of the split preview/production tools | Still works (back-compat dispatcher) but discouraged | Use `content_deploy_site_preview` → `content_deploy_site_production` |
| Skip settings, go straight to deploy | 400: "Missing: Site Settings" | Set settings first (step 2) |
| Create components with same slug twice | 400: "already exists" | Use `content_update_component` or increment version |
| Create pages but forget to publish them | 400: "Missing: Published Pages" | Publish at least 1 page (step 5) |
| Skip `apply-theme` | 400: "Missing: Theme / Templates" | Apply a theme (step 6) |
| Deploy without adding a domain | 400: "Missing: Verified Domain" | Add domain via `content_add_domain` |

## Key Rules

- **Run `spideriq use` once per project** — every other rule below assumes you did.
- **Always read `/content/help` first** — it has every block type, Liquid filter, template variable, plus `session_binding` + `deploy_workflow` sections.
- **Always preview destructive ops** — MCP defaults to `dry_run=true`; only consume when you've seen the preview.
- **Check readiness before deploy preview** — `content_deploy_readiness` MCP tool.
- **Component slugs must be unique** per version — duplicates return 400.
- **Use `format=yaml`** on GET requests — saves 40-76% tokens.
- **Block types:** hero, features_grid, cta_section, testimonials, pricing_table, faq, stats_bar, rich_text, image, video_embed, code_example, logo_cloud, comparison_table, spacer, component
- **Page templates:** default, landing, feature, legal, dynamic_landing
- **Public endpoints** (GET /content/*) need no auth — use `X-Content-Domain` header
- **Dashboard endpoints** (POST/PATCH /dashboard/projects/{pid}/content/*) need Bearer auth + auto-injected project segment

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
- **publish / archive / delete are gated** (dry_run → confirm_token)

### Component API
```
POST   /dashboard/projects/{pid}/content/components                       — create
PATCH  /dashboard/projects/{pid}/content/components/{id}                  — update
POST   /dashboard/projects/{pid}/content/components/{id}/publish          — publish (gated: dry_run → confirm_token; Tier 4 returns 202)
POST   /dashboard/projects/{pid}/content/components/{id}/archive          — archive (gated)
DELETE /dashboard/projects/{pid}/content/components/{id}                  — delete (gated)
GET    /dashboard/projects/{pid}/content/components/{id}/build-status     — Tier 4 build status
POST   /dashboard/projects/{pid}/content/components/{id}/rebuild          — Tier 4 re-build
GET    /content/components                                                — list published (public, no binding needed)
GET    /content/cdn-allowlist                                             — list CDN libraries (public)
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

Submit any template: read the JSON, then `POST /api/v1/dashboard/projects/{pid}/content/pages` with the payload.

## API Base

- Production: `https://spideriq.ai/api/v1`
- Docs: `https://docs.spideriq.ai`
- Site Builder Docs: `https://docs.spideriq.ai/site-builder/overview`
- Session Binding: `https://docs.spideriq.ai/site-builder/sessions`
- Deploy Safely: `https://docs.spideriq.ai/site-builder/deploy-safely`
- Component Builder: `https://docs.spideriq.ai/site-builder/component-builder`
- Component Tiers: `https://docs.spideriq.ai/site-builder/component-tiers`
- Agent Reference: `https://docs.spideriq.ai/site-builder/component-agents-reference`
- Health: `GET /api/v1/system/health`
- Full Reference: `GET /api/v1/content/help` (YAML, now includes session + deploy workflow sections)

## GitHub

- Public repo: https://github.com/martinshein/SpideriQ-ai/tree/main/SpiderPublish
