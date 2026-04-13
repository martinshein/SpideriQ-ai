# SpiderPublish — Learnings & Gotchas

Things that cause silent failures or broken deploys. Read before building.

## Deploy

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Deploy without settings | Site deploys with blank branding, no site name | `PATCH /dashboard/content/settings` with `site_name` first |
| Deploy without templates | Site deploys with empty pages | `POST /dashboard/templates/apply-theme` first |
| Deploy without published pages | Deploy rejects (400) | Publish at least 1 page before deploying |
| Domain not set as primary | Preview link and deploy status don't show your URL | `POST /dashboard/content/domains/{domain}/primary` |
| No header navigation | Site renders with no menu | `PUT /dashboard/content/navigation/header` with items |

**Rule:** Always call `content_deploy_readiness` before `content_deploy_site`. It catches all of the above.

## Components

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Creating component with same slug+version twice | 400: "already exists" | Use `content_update_component` or increment version |
| Component left in draft status | Won't render on live pages | Publish via `POST /dashboard/content/components/{id}/publish` |
| Using Tailwind in component CSS | Classes don't work inside Shadow DOM | Write plain CSS, use `var(--primary)` for theme colors |
| `document.querySelector()` in JS | Queries escape the Shadow DOM | Use `root.querySelector()` — `root` is the shadowRoot |
| Tier 4 publish is async | 201 response but component not ready | Poll `GET .../build-status` until `success` |

## Content

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| No page with slug "home" | Visitors see 404 at `/` | Create a page with `"slug": "home"` |
| Blocks missing `id` field | Block may not render or save correctly | Every block needs a unique `id` string |
| Rich text with raw HTML components | `<my-component>` tags in rich_text don't render as Shadow DOM components | Use block type `component` with `component_slug` instead |

## API

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Forgetting `?format=yaml` | JSON responses waste 40-76% more tokens | Set `SPIDERIQ_FORMAT=yaml` in `.mcp.json` env |
| Using wrong auth for public vs dashboard endpoints | 401 or wrong data | Public `/content/*` uses `X-Content-Domain`, dashboard uses Bearer |
| Not checking deploy readiness | Deploying a half-configured site | `GET /dashboard/content/deploy/readiness` before deploy |
