# SpiderPublish — Learnings & Gotchas

Things that cause silent failures or broken deploys. Read before building.

## Apr 2026 Triage — 5 silent-failure modes now caught (2026-04-24)

Consolidated from 8 agent session reports across 6 live projects. Half were silent-accept bugs (200 OK + blank page); half were opaque defaults. All fixed.

| Gotcha | What Happened | Fix (now live) |
|---|---|---|
| **Block payload silent-accept:** `{type: "component", data: {slug: "x", props: {...}}}` returned 200 OK but rendered blank | `component_slug` lives at the block's top level, not under `data`. The Liquid renderer's `{% component %}` tag read `block.component_slug` and got `undefined`. | Now returns `422` with a hint: `block[id=...] type='component' requires top-level component_slug (received data.slug='x' — move it to the top-level component_slug field)`. Reference JSON: [`components/block-component.json`](components/block-component.json). |
| **`rich_text` block with `data: {text: "..."}`** silently rendered empty | Template expects `data.html` (raw HTML) OR `data.content` (Tiptap JSON). `text` isn't a recognized field. | Now returns `422` naming the two valid shapes. Reference JSON: [`components/block-rich-text.json`](components/block-rich-text.json). |
| **Unknown fields** on `POST/PATCH /components` (e.g. `css_styles` instead of `css`) silently dropped | Pydantic's `extra='ignore'` default — unknown keys went straight to `/dev/null` | Now returns 200 OK with a `warnings[]` array in the response body: `Unknown field 'css_styles' was ignored. Did you mean 'css'?`. Two-layer match: substring-contains first, difflib fallback. |
| **Slug with `/` in it** (e.g. `product/pillowcase`) accepted at creation, then silently 404'd at serve time | The renderer's route matcher lost nested slugs to `/directory/*` regex precedence OR URL-encoding edge cases | Now returns `422` at creation. Use flat slugs (`product-pillowcase`). Nested doc paths use `parent_id` chains, not `/` in the slug. |
| **Dark body leaks into components** — first content component appears invisible | `--surface` CSS variable defaults to `#0A0A0B` (Tailwind `slate-950`). Every component without an explicit `:host { background-color }` renders invisible on a light-themed site. | Two fixes: (a) site-wide light theme via `content_update_settings({surface_color: "#ffffff", ...})` (see Theme Palette in AGENTS.md), (b) every content component should declare `:host { background-color: ... }` explicitly. Bonus: `font-family` doesn't inherit into Shadow DOM either — declare it in `css`. |

### Session-level tooling gains (2026-04-24)

| Capability | How |
|---|---|
| **Confirm your project binding** before a destructive deploy | `GET /api/v1/auth/whoami` or `npx @spideriq/cli auth whoami` → returns `{client_id, project_name, email, scopes, token_expires_at, ...}`. `project_name` is the client's company name on the record. |
| **Distinguish expired from invalid PAT** | 401 response body now structured: `{"detail": {"error": "token_expired" \| "token_invalid", "expires_at"?, "message"}}`. Expired variant includes regen URL. |
| **Preview a single component in isolation** | `POST /dashboard/projects/{pid}/content/components/{id}/preview` returns `{html, css, js, merged_props}` ready for iframe-srcdoc. ~100-300ms vs 60-90s full-site deploy. |
| **Audit internal links before deploy** | `GET /dashboard/projects/{pid}/content/audit/links` walks every published page's blocks + nav menus, returns `{valid_count, broken: [{path, source, reason}], proposed_redirects}`. `source` strings pinpoint the exact tree position (`page:home/block[2].cta_primary.url`). |
| **Chrome auto-skip** when a custom header/footer component is present | Mark the component with `category: "header"` or `"footer"` on create. Renderer suppresses the matching native `{% section %}` automatically. No more double-chrome, no `template='blank'` fallback. Manual override via `page.custom_fields.hide_native_chrome: true`. |
| **Empty-string props now suppress default_props** | `props: {image: ""}` on a page block now correctly overrides `default_props.image = "/placeholder.jpg"`. Falsy-but-meaningful values (`0`, `false`) preserved. |
| **Tilda / Webflow `<style>` extraction** — opt-in | Pass `auto_extract_css: true` on `component_create` / `component_update` and the server moves every inline `<style>...</style>` block into the `css` field before validation. Off by default (loud-error contract for hand-authored components). |

Recipes:
- [skills/recipes/link-audit/](skills/recipes/link-audit/) — full audit + proposed-redirect workflow
- [skills/recipes/tilda-migration/](skills/recipes/tilda-migration/) — end-to-end Tilda port using `auto_extract_css` + flat slugs + `category='header'|'footer'` components

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

## Blog Customization (read this if your AI agent suggests "patch the blog component")

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Trying to PATCH a `dm-blog-listing` / `<brand>-blog-listing` / "blog component" via `PATCH /content/components/{id}` | Returns 404 or 500 — **the component does not exist**. SpiderPublish blogs are template-based, not component-based. AI agents (especially AntiGravity / Gemini) sometimes hallucinate this name. | Use `content_override_section({section_slug: "blog-listing", liquid_source: ...})` (writes `templates/blog.liquid` per-tenant) or create a CMS page at slug `blog` to compose blocks instead. See "How to restyle the blog" below. |
| Building a parallel `/our-blog` (or `/articles`, etc.) page with a hand-rolled component because "the platform `/blog` is locked" | You lose native pagination, automatic post sync, and the canonical URL. Posts created via `content_create_post` won't appear there. | Override `templates/blog.liquid` instead — it keeps native pagination + all CMS posts + the `/blog` URL. |
| Wanting to add a custom `<header>` / hero block specifically on `/blog` | The hardcoded blog template doesn't compose other blocks — it renders a fixed Liquid layout. | **Two options:** (1) Create a CMS page at slug `blog`. The renderer prefers a CMS page over the hardcoded template (2026-04-30+). The page's blocks (hero, custom footer, anything) render via `templates/page.liquid`. (2) Edit `templates/blog.liquid` directly and put your custom markup in the Liquid source. |
| Want to restyle the post detail page (`/blog/{slug}`) | Same as the listing — `templates/blog-post.liquid` is overridable per-tenant. | `content_override_section({section_slug: "blog-post", liquid_source: ...})` or `template_upsert(path: "templates/blog-post.liquid", content: ...)`. |
| Want to restyle just the post card (the "row" in the listing AND the "related posts" block on single posts) | One file, used in two places: `snippets/post-card.liquid`. | `template_upsert(path: "snippets/post-card.liquid", content: ...)`. |

**How to restyle the blog (full recipe):**

```
# Easy path — content_override_section wraps template_upsert with a friendly slug
content_get_section_source({section_slug: "blog-listing"})    # see current source
content_override_section({section_slug: "blog-listing", liquid_source: <your custom blog.liquid>})
content_override_section({section_slug: "blog-post",    liquid_source: <your custom blog-post.liquid>})

# OR Block-composition path — make /blog a normal CMS page
content_create_page({slug: "blog", template: "default", blocks: [<hero block>, <custom>, ...]})
content_publish_page({id: <new-page-id>})
content_deploy_preview() → content_deploy_production({confirm_token: ...})

# OR Underlying API — full template control
template_upsert({path: "templates/blog.liquid",      content: ...})
template_upsert({path: "templates/blog-post.liquid", content: ...})
template_upsert({path: "snippets/post-card.liquid",  content: ...})
```

CLI equivalent: `spideriq templates set 'templates/blog.liquid' --file ./blog.liquid`

The Liquid engine merges per-tenant KV templates over the bundled default theme automatically. There is **no separate publish step** for templates — the override is live as soon as the next render reads from KV (after `content_deploy_*`).

## Marketplace Background Videos (super-admin only — not normal client work)

The bg-video gallery on every SpiderPublish tenant pulls from a **global** catalog (`content_bg_videos`) shared across all clients. It's super-admin only by design — your project token cannot write to it. Two paths to add new videos (super-admins only):

| Method | Use when |
|---|---|
| Dashboard `/admin/content/marketplace/bg-videos/new` — drop MP4 + poster, type Name (slug auto-fills), save | Adding 1-3 videos interactively |
| `npx @spideriq/cli@latest bg-videos add ./hero.mp4 --slug city-hotel --name "City Hotel" --poster ./hero.jpg` | Adding 5+ videos in a script |

Files up to 500 MB are accepted (raised from 10 MB on 2026-04-30). The CLI's `bg-videos upload` / `bg-videos create` / `bg-videos add` subcommands all 403 with a clear message if the token isn't super-admin.

`media upload` (the general-purpose CLI command) writes to a **different** bucket (per-tenant SpiderMedia) and the result will NOT appear in the marketplace gallery. They are different storage systems with different auth.

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

## Marketplace V2 (Phase G — May 2026)

The agent-discovery surface (`marketplace_search`, `list_data_sources`, `set_*_agent_meta`, `set_component_kind`) shipped 2026-05-05. New behaviour, new pitfalls.

| Gotcha | What Happens | Fix |
|--------|-------------|-----|
| Passing `mood: ["calm", "editorial"]` to `marketplace_search` expecting an AND-narrowing | Returns rows where mood overlaps EITHER value (any-of match against the TEXT[] column) — wider than expected | Pass a single value per axis for AND-style narrowing (`mood: ["calm"]`). Cross-axis is already AND (`mood AND palette AND brand_fit AND scene_type`). |
| Setting `kind="dynamic"` on a row missing `block_type` | DB CHECK constraint 400s with `chk_components_block_type_dynamic` | Set `block_type` (+ non-empty `sources`) via `content_update_component` first, OR pass kind+block_type+sources together in `content_create_component` |
| Putting `mood` / `palette` / `brand_fit_tags` / `scene_type` inside `agent_meta` | Silent no-op — the universal axes are top-level columns, agent_meta is a separate JSONB | Pass them as siblings of `agent_meta` in the request body |
| `agent_meta: {pace: "turbo"}` typo | 422 with the violating field name | Vocabulary is strict (`extra="forbid"` Pydantic). Pull the canonical vocab from `template_get_help` or `skills/content-platform/schema.yaml` `marketplace_v2_axes:` |
| Binding `idap.lead` to a List block | 400 — idap.lead is `is_collection=false` (singleton). Only Item Details accepts it | Use `idap.businesses` / `idap.cities` / `posts` for List bindings; reserve `idap.lead` for Item Details on per-request lead context |
| Calling `set_bg_video_agent_meta` from a project-scoped token | 403 super_admin-required | The bg-video + site-template catalogs are global — only super_admin can mutate. Components are per-tenant, so `set_component_agent_meta` works with the project token. |
| Forgetting that `set_*` mutation tools default `dry_run=true` | First call returns a preview envelope + `confirm_token`, no mutation | Either pass `dry_run=false` explicitly OR call once for preview then again with `confirm_token=<token>` (recommended — same Phase 11+12 pattern as deploy/publish/delete) |
| `palette` rejected with "list too long" | Cap is 12 entries on the write path | Trim the palette to ≤12. The catalog leans on a small consistent vocabulary (monochrome, deep-blue, cinematic, …) — long lists don't help search precision. |
