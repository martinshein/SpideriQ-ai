# SpiderPublish — Learnings & Gotchas

Things that cause silent failures or broken deploys. Read before building.

## Multi-Tenant Safety (Phase 11+12) — New

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Skipping `spideriq use` on a fresh project | Every call carries `Deprecation: true` + `Sunset: Wed, 14 May 2026` headers; calls will 410 after that date | Run `npx @spideriq/cli use <project>` once, commit `spideriq.json` |
| Two terminal windows in two folders with different `spideriq.json` | Each binds to its own project — this is **correct** behaviour (the whole point of Lock 3) | Feature not bug — keeps multi-client workflows safe |
| Calling `content_publish_page` and expecting an immediate publish | Returns a preview envelope with `dry_run: true` + `confirm_token` | Destructive MCP tools default to `dry_run=true` — call again with the returned `confirm_token` |
| Reusing the same `confirm_token` twice | First call succeeds, second returns `409 TokenConsumed` | Tokens are single-use. Issue a fresh one via another `dry_run=true` call |
| Using a 7-day-old `confirm_token` | `410 TokenExpired` | Issue a fresh one |
| Using an `update_settings` token on `apply_theme` | `403 TokenActionMismatch` | Per-action tokens. Issue the right one for the right action |
| `whoami` shows Token scoped to A but Session bound to B | Your calls will 403 on Lock 1↔2 | You're in the wrong directory, or `spideriq.json` is stale — re-run `spideriq use` |
| Editing `spideriq.json` by hand to point at another tenant | Lock 1 (PAT scope) still catches it server-side — 403 | The file isn't a security boundary; the backend-enforced token scope is |
| Legacy URL works but feels "discouraged" | It is — you'll see `Deprecation` headers on every response | Migrate to the scoped URL now; legacy disappears after 2026-05-14 |

**Quick debug:** If you're getting unexpected 403s on dashboard calls, run `npx spideriq whoami` — it shows both the PAT scope and the session binding, and flags any mismatch between them.

## Deploy

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Calling `content_deploy_site` instead of the new split tools | Still works (back-compat dispatcher) but no preview URL | Use `content_deploy_site_preview` → `content_deploy_site_production` |
| Calling `content_deploy_site_production` without a `confirm_token` | 422 (required field missing) | Always call `_preview` first, pass its `confirm_token` |
| Deploy without settings | Site deploys with blank branding, no site name | `PATCH /dashboard/projects/{pid}/content/settings` with `site_name` first (two-step) |
| Deploy without templates | Site deploys with empty pages | `POST /dashboard/projects/{pid}/templates/apply-theme` first (two-step) |
| Deploy without published pages | Deploy rejects (400) | Publish at least 1 page before deploying (two-step) |
| Domain not set as primary | Preview link and deploy status don't show your URL | `POST /dashboard/projects/{pid}/content/domains/{domain}/primary` |
| No header navigation | Site renders with no menu | `PUT /dashboard/projects/{pid}/content/navigation/header` with items |
| Preview URL returns 404 in the first ~60s | Cloudflare edge is still propagating the new Worker script | Wait 60 seconds, retry — don't "fix" the code |

**Rule:** Always call `content_deploy_readiness` before `content_deploy_site_preview`. It catches all the missing-prerequisite cases.

## Components

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Creating component with same slug+version twice | 400: "already exists" | Use `content_update_component` or increment version |
| Component left in draft status | Won't render on live pages | Publish via `content_publish_component` (two-step: dry_run → confirm) |
| Using Tailwind in component CSS | Classes don't work inside Shadow DOM | Write plain CSS, use `var(--primary)` for theme colors |
| `document.querySelector()` in JS | Queries escape the Shadow DOM | Use `root.querySelector()` — `root` is the shadowRoot |
| Tier 4 publish is async | 202 response but component not ready | Poll `GET .../build-status` until `success` |

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
| Not checking deploy readiness | Deploying a half-configured site | `content_deploy_readiness` before deploy-preview |
| Hitting `/api/v1/dashboard/content/...` from a bound directory | Works but carries Deprecation headers | The CLI/MCP auto-rewrites to scoped URLs — only raw `curl` skips the rewrite |
