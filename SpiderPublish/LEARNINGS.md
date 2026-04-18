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

## Theme & Chrome

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Setting `primary_color: "#000000"` expecting a dark page background | No effect on background — `primary_color` is the ACCENT only (CTAs, links, borders) | Use the surface palette: `surface_color`, `surface_elevated_color`, `subtle_color`, `body_text_color`, `heading_color`. Defaults are already dark |
| Trying to modify `<header>` / `<footer>` from component JS (`document.querySelector('body > footer').style.backgroundColor = ...`) | Works once, then breaks on edge cache flush; flashes unstyled content on every page load | Use `content_override_section({section: "footer", liquid: ...})` — every live client (danmagi, sms-chemicals, mail.spideriq.ai) does |
| Creating a component with slug `"footer"` to replace the default site footer | Component renders wherever you add it as a block — does NOT replace the default footer section | Components and theme sections are different subsystems. Use `content_override_section` for chrome, components for page content |
| Using Tailwind utility classes inside component CSS (e.g. `bg-black`) | Classes don't resolve inside Shadow DOM | Write plain CSS, use `var(--primary)`, `var(--surface)`, `var(--body-text)`, etc. — theme CSS variables are auto-injected |
| Want a completely chrome-less page (no header/footer) | Setting `display: none` on default chrome via component CSS doesn't work (Shadow DOM scoping) | Set `page.template: "blank"` when creating the page. OR: `content_apply_layout_preset({preset: "blank"})` for site-wide |
| Default theme looks "too dark" when you wanted light | By design — the canonical palette is dark (Developer Noir). Default matches 90% of agent-facing sites | Make it light in a single call: `content_update_settings({surface_color: "#ffffff", body_text_color: "#18181b", heading_color: "#0a0a0a"})` |

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
| Subdomain deploy (`mail.client.com` on client's own CF zone) returns instant 522 (<100ms) | Worker Route not attached because CF `GET /zones?name=` only matches exact zone names | Fixed in v2.x — `_ensure_worker_route` now walks up the domain hierarchy. Re-run deploy |

**Rule:** Always call `content_deploy_readiness` before `content_deploy_site_preview`. It catches all the missing-prerequisite cases.

## Components

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Creating component with same slug+version twice | 400: "already exists" | Use `content_update_component` or increment version |
| Component left in draft status | Won't render on live pages | Publish via `content_publish_component` (two-step: dry_run → confirm) |
| Using Tailwind in component CSS | Classes don't work inside Shadow DOM | Write plain CSS, use `var(--primary)` / `var(--surface)` / `var(--body-text)` for theme colors |
| `document.querySelector()` in component JS for page-scope queries | Queries escape the Shadow DOM (sometimes works, sometimes doesn't) | Use `root.querySelector()` — `root` is the shadowRoot. For reading page scroll use `window.scrollY` + `window.innerHeight` directly |
| Using `document.querySelector` to modify site chrome from inside a component | Broken by design — Shadow DOM + edge caching + FOUC. See Theme & Chrome table | Use `content_override_section` instead |
| Tier 4 publish is async | 202 response but component not ready | Poll `GET .../build-status` until `success` |
| Expecting Framer Motion to be available as a Tier 3 CDN dep | Not allowlisted — Framer Motion is React-only (needs React runtime) | Use Tier 4 (React component with `framework: "react"`) if you need it. For pure HTML, use GSAP (already allowlisted) — it's what Framer Motion's useScroll delegates to conceptually |
| Including `<style>` tags in `html_template` | Silent failure in v1. v2.88.0+ returns 400 with a pointer to the `css` field | The Liquid renderer injects CSS via the separate `css` field on the component row; inline `<style>` in HTML is ignored at render time. Move rules to `css` |
| Updating a shared component on page A but other pages still show the old version | Each page's block stores `component_version` — pages that pin the old version keep rendering it even after `content_update_component` | Use `component_update_and_propagate` (v2.88.0+) — one call bumps the component AND repoints every consuming page's block pin in one transaction. Legacy flow (update + iterate pages) works too but is ~10× more requests |
| A bad `component_update_and_propagate` landed on production | Multiple pages now render the broken version | `component_rollback(slug, target_version="<known good>")` — creates a new forward version with the old content and repoints pages. Gate action is distinct so confirm_tokens can't cross-consume |
| Running `content_deploy_site_production` after `component_update_and_propagate` to "make the change live" | Works, but unnecessary — block-level page content renders live via the content API on next request. Tenant KV deploy only matters for templates/theme/config | Skip the deploy step unless you ALSO changed templates/theme/config. G-A + rollback mutate `content_pages.blocks` in-place; edge fetches pick up the change within the content-API cache TTL (60s) |

## Media & Scroll-Sequences

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Hardcoding 100+ frame URLs in a custom component's JS | Bundle bloat, concurrent GET flood triggers CDN rate-limit drops → black frames ("flashlight strobe") as the user scrolls | Use the global `sys-scroll-sequence` component with `{base_url, pattern, count}`. Feed it from a SpiderVideo `extract_frames` job — see `examples/scroll-sequence.sh` |
| Tunneling local frames through pinggy/serveo/localhost.run into `POST /media/files/import-url` | Free tunnels inject a "security warning" HTML interstitial on first request; `import-url` returns 200 OK and saves the HTML as `.webp`. Result: every Canvas frame fails to decode → site ships with black hero silently | Either (a) use `extract_frames` so frames are produced server-side from a video URL, or (b) use the `bulk-media-upload` recipe to multipart-POST local files directly. Never tunnel. |
| Building your own scroll-sequence component from scratch with GSAP | 12 hours of work + frame-preloading bugs + CDN DDoS risk + zero reuse | `sys-scroll-sequence` (is_global=true, Tier 3, already published) does this for you. You supply `{base_url, pattern, count}` and it handles canvas, GSAP ScrollTrigger, and progressive preloading. |
| Using `preload_strategy: "all"` with >60 frames on `sys-scroll-sequence` | First paint triggers 60+ concurrent GETs from the same client → CDN throttles → random black frames | Use `preload_strategy: "progressive"` (default) — ±15 frame window around the current scroll position. |
| `POST /media/files/import-url` appears to ignore your `filename` param | Pre-2026-04-18 the SpiderMedia backend always prepended `YYYYMMDD_HHMMSS_` to every key, breaking `{index}`-pattern lookups for `sys-scroll-sequence`. | **Fixed 2026-04-18.** Pass `preserve_filename: true` per-URL in the batch body (or batch-level default) — the key becomes `{folder}/{filename}` exactly. For scroll-sequences, `upload_local_directory(folder="scroll-sequences/*")` auto-enables this. |
| Hardcoding a scroll-sequence with URLs from `catbox.moe` / `raw.githubusercontent.com` / other public file hosts | Works initially, then rate-limit or link-rot breaks the site. No tenant isolation. No CF edge caching. | Host all site assets in the tenant's R2 (`media.cdn.spideriq.ai/clients/{cid}/...`). Every approved upload path does this automatically. |
| Uploading 120 × 1.6 MB DSLR JPG frames to a scroll-sequence, hoping for the best | 192 MB batch → first paint takes forever / CDN bill balloons / mobile users bounce. Beyond 2026-04-18, server returns 400 with `weight_policy_violated` | Use `upload_local_directory(folder="scroll-sequences/hero")` — defaults to `auto_optimize=true` which runs Sharp locally (WebP q75, max 1920px wide). 192 MB → ~8 MB. Server hard ceiling: 500 KB per file, 20 MB per batch for `scroll-sequences/*`. |
| `upload_local_directory` reports `sharp not available, continuing without optimization` | Platform-specific `sharp` optional install failed (e.g. uncommon Linux glibc, Alpine). Tool uploads originals, which then hit server ceilings. | `npm install sharp` in the MCP runtime's cwd. Or pre-optimize frames yourself with `cwebp -q 75` and re-run with `--no-auto-optimize`. |

## Content

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| No page with slug "home" | Visitors see 404 at `/` | Create a page with `"slug": "home"` |
| Blocks missing `id` field | Block may not render or save correctly | Every block needs a unique `id` string |
| Rich text with raw HTML components | `<my-component>` tags in rich_text don't render as Shadow DOM components | Use block type `component` with `component_slug` instead |
| Setting `page.template` to `"feature"` or `"legal"` | Unknown value — renderer falls back to `default` silently | Valid values: `default`, `landing`, `blank`, `dynamic_landing`. Anything else silently degrades |

## API

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Forgetting `?format=yaml` | JSON responses waste 40-76% more tokens | Set `SPIDERIQ_FORMAT=yaml` in `.mcp.json` env |
| Using wrong auth for public vs dashboard endpoints | 401 or wrong data | Public `/content/*` uses `X-Content-Domain`, dashboard uses Bearer |
| Not checking deploy readiness | Deploying a half-configured site | `content_deploy_readiness` before deploy-preview |
| Hitting `/api/v1/dashboard/content/...` from a bound directory | Works but carries Deprecation headers | The CLI/MCP auto-rewrites to scoped URLs — only raw `curl` skips the rewrite |
