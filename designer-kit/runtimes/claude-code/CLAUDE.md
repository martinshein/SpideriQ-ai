# SpiderPublish — Claude Code Context

> **Built from canonical sources in [shared/](../../shared/).** Edit shared content there, run `npm run build` to regenerate.

This file binds your Claude Code session to the SpiderPublish content platform: the safety contract, the tool catalog, and pointers to skills you can pull in by name.

# SpiderPublish — AI Agent Context

This project uses SpiderPublish (SpiderIQ's content platform) to build, manage, and deploy websites.

**Current package versions (1.11.0, 2026-05-09):** `@spideriq/cli@1.11.0`, `@spideriq/mcp-publish@1.11.0`, `@spideriq/core@1.10.0` — **94 atomic SpiderPublish tools** (pages, posts, docs, templates, components, domains, media, directory, playbook, scroll-sequence + section-override + component-propagation + local-upload one-shots; +1 from P2 Page Export + PageAuditor 2026-05-09; +5 from P4 Page Locking + Versions 2026-05-09). The `.mcp.json` in this starter kit pins `@spideriq/mcp-publish` instead of the kitchen-sink `@spideriq/mcp@1.11.0` (which also includes SpiderBook booking tools) — some IDE/LLM stacks silently drop tool injections above ~128 tools, and every tool schema re-injects into LLM context on every turn. If you need mail / leads / gate / admin / booking tools too, add a second MCP server entry for `@spideriq/mcp-mail` / `-leads` / `-gate` / `-admin`, or fall back to `@spideriq/mcp` for the whole surface.

---

## Multi-Tenant Safety (Phase 11+12) — **READ FIRST**

Every dashboard call you make is enforced across five independent tenant locks. The first step on any new project is binding this directory to a specific client. If you skip this, your calls fall back to legacy URLs that carry a `Deprecation: true` / `Sunset: 2026-05-14` response header and will stop working after that date.

### Before you do anything: bind this directory

```bash
# List projects your token can access
npx @spideriq/cli use --list

# Bind — writes ./spideriq.json (commit it like .vercel/project.json)
npx @spideriq/cli use <project>   # short id cli_xxx, brand slug, or company name
```

After this, every dashboard URL auto-rewrites to `/api/v1/dashboard/projects/{project_id}/...` and the backend enforces that your PAT, the URL, and every resource you touch all agree on which tenant is in play. Mismatches return 403 — never a silent cross-tenant write.

### Destructive operations are two-step by default

MCP tools like `content_publish_page`, `content_delete_page`, `content_update_settings`, `template_apply_theme`, and `content_deploy_site` default to **`dry_run=true`**. The first call returns a preview envelope with a `confirm_token`; the second call (same args + `confirm_token`) actually mutates.

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

The `.mcp.json` in this project connects to SpiderIQ. After IDE restart, you have 155 tools.

## Authentication

```bash
# Check auth
npx @spideriq/cli auth whoami

# Request access (emails admin, wait for approval)
npx @spideriq/cli auth request --email admin@company.com

# Bind directory to project (MANDATORY after auth — see top of file)
npx @spideriq/cli use <project>
```

## Build a Site

All dashboard URLs below assume the CLI/MCP auto-injects `/projects/{pid}/` from `./spideriq.json`. If no binding is set they still work via legacy paths but with Deprecation headers.

1. **Read the reference first:** `template_get_help` MCP tool (or `GET /api/v1/content/help?format=yaml`) — includes `tasks` index, `getting_started` preamble, `chrome_override`, `theme_palette`, `session_binding`, `deploy_workflow` sections.
2. **Settings:** `PATCH /dashboard/projects/{pid}/content/settings` — REQUIRED: `site_name`. Optional but recommended: `primary_color` (accent), `logo_light_url`, plus the full theme palette below. Gated: first call with `?dry_run=true`, then `?confirm_token=cft_...`
3. **Navigation:** `PUT /dashboard/projects/{pid}/content/navigation/header` — menu items (not gated)
   An item may carry a `source` binding (`{kind: "folder", folder_id, depth}` or `{kind: "site", depth}`) instead of a `url`, so the menu is generated from the page tree and only ever lists **published** pages. The authenticated read deliberately returns the binding *un-expanded* — never write the expansion back. See "Folder-driven navigation" in the catalog.
4. **Pages:** `POST /dashboard/projects/{pid}/content/pages` — create with blocks (slug `home` for homepage; `template` picks the layout — see Page Templates below) (not gated). Pass `is_folder: true` for a dashboard-only folder; `parent_id` and `index_page_id` on update move a page into a folder and pin the folder's landing page.
5. **Publish:** `POST /dashboard/projects/{pid}/content/pages/{id}/publish` — REQUIRED: at least 1 published page. Gated.
6. **Theme:** `POST /dashboard/projects/{pid}/templates/apply-theme` — REQUIRED: apply `default`. Gated.
7. **Check readiness:** `content_deploy_readiness` MCP tool — verify all blocking checks pass.
8. **Deploy:** two steps (replaces the old single-step deploy):
   - `POST /dashboard/projects/{pid}/content/deploy/preview` → returns `preview_url` + `confirm_token`
   - Review `preview_url` in a browser
   - `POST /dashboard/projects/{pid}/content/deploy/production?confirm_token=cft_...` → live in ~2-5 seconds

## Duplicate page / post / doc / block (2026-04-24)

When you want a starting point that mirrors an existing page, fork it as a draft. Each call returns a new resource with `status='draft'`, fresh UUIDs on every block, and `{slug}-copy[-N]` slug auto-generated unless you pass `new_slug`. Title gets ` (Copy)` appended.

```bash
# MCP
content_duplicate_page(page_id="...", new_slug?="...")
content_duplicate_block(page_id="...", block_id="...", position?: "after" | "before" | <int>)
content_duplicate_post(post_id="...", new_slug?="...")
content_duplicate_doc(doc_id="...", new_slug?="...")

# CLI
spideriq content pages:duplicate <page_id> [--slug new-slug]
spideriq content blocks:duplicate <page_id> <block_id> [--position after|before|N]
spideriq content posts duplicate <post_id> [--slug new-slug]
spideriq content docs:duplicate <doc_id> [--slug new-slug]
```

NOT gated by `dry_run` / `confirm_token` — duplicating creates a new row, doesn't overwrite state. 409 on slug collision when you provide `new_slug`; 404 if the source isn't in your tenant. Block duplication targets the same page (the new block is inserted at the chosen position; original keeps its place).

Use this primitive for: "make a copy of the homepage and tweak it as the holiday version", "fork a published blog post and rewrite as a follow-up", "duplicate the pricing-grid block on the same page so I have an annual + monthly variant side by side."

Runnable example: [examples/duplicate-page.sh](./examples/duplicate-page.sh).

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

### PAT Auth Errors (2026-04-24)

Distinguishable from the confirm-token errors above. Response body is `{"detail": {"error": "<code>", "message": "...", "expires_at"?: "..."}}`.

| Status | `error` code | What it means |
|---|---|---|
| `401` | `token_expired` | Your PAT passed `expires_at`. Body includes `expires_at` + regen URL. Run `spideriq auth request --email <admin>` or go to `https://app.spideriq.ai/settings/tokens`. |
| `401` | `token_invalid` | PAT is unknown or malformed. Check `~/.spideriq/credentials.json`. |

### `whoami` — confirm project binding before deploying

```bash
curl -H "Authorization: Bearer $SPIDERIQ_PAT" https://spideriq.ai/api/v1/auth/whoami
# → {authenticated, auth_type, client_id, project_name, email, scopes, token_expires_at, ...}

# Or via CLI:
npx @spideriq/cli auth whoami
```

`project_name` is the company name on the client record — quickest way to verify you're about to mutate the right tenant.

## Common Mistakes

| Mistake | What Happens | Fix |
|---------|-------------|-----|
| Forget `spideriq use` at the start | Deprecation header on every response, legacy URLs stop working 2026-05-14 | Run `spideriq use <project>` once, commit `spideriq.json` |
| Call destructive MCP tool without `confirm_token` or explicit `dry_run=false` | Returns a preview envelope instead of mutating | Feature, not bug — call again with the returned `confirm_token` |
| Set `primary_color: "#000000"` expecting a dark page background | `primary_color` is the accent (CTAs, links); background is unchanged | Use `surface_color` / `body_text_color` / `heading_color` — see Theme Palette below |
| Build JavaScript that modifies `<header>` / `<footer>` from component JS | Works once, breaks on edge cache flush, FOUC on every page load | Use `content_override_section` — see Customize Header/Footer below |
| Create a component with `slug: "footer"` to replace the default footer | Component renders as a block wherever you add it, doesn't touch the real footer | Components ≠ theme sections. Use `content_override_section({section: "footer", ...})` |
| Create components with same slug+version twice | 400: "already exists" | Use `content_update_component` or increment version |
| Create pages but forget to publish them | 400: "Missing: Published Pages" | Publish at least 1 page (step 5) |
| Skip `apply-theme` | 400: "Missing: Theme / Templates" | Apply a theme (step 6) |
| Deploy without adding a domain | 400: "Missing: Verified Domain" | Add domain via `content_add_domain` |

## Key Rules

- **Run `spideriq use` once per project** — every other rule assumes you did.
- **Always read `/content/help` first** — it has every block type, Liquid filter, template variable, plus `tasks`, `session_binding`, `deploy_workflow`, `chrome_override`, `theme_palette`.
- **Always preview destructive ops** — MCP defaults to `dry_run=true`; only consume when you've seen the preview.
- **Check readiness before deploy preview** — `content_deploy_readiness` MCP tool.
- **Component slugs must be unique** per version — duplicates return 400.
- **Use `format=yaml`** on GET requests — saves 40-76% tokens.
- **Block types:** `hero, features_grid, cta_section, testimonials, pricing_table, faq, stats_bar, rich_text, image, video_embed, code_example, logo_cloud, comparison_table, spacer, component`
- **Page templates:** `default, landing, blank, dynamic_landing` (see Page Templates below)
- **Public endpoints** (GET /content/*) need no auth — use `X-Content-Domain` header
- **Dashboard endpoints** (POST/PATCH /dashboard/projects/{pid}/content/*) need Bearer auth + auto-injected project segment

---

## Page Templates

The `template` field on a page row picks the Liquid layout it renders with. Unknown values fall back to `default` silently.

| Template | What it does | Use for |
|---|---|---|
| `default` | Standard page with header + footer + default body classes | Most pages |
| `landing` | Header + footer retained, main is full-bleed (no max-width container) | Marketing pages with full-width sections |
| `blank` | No header, no footer, no default body classes, no layout wrapper | Landing pages with a custom hero that paints the whole viewport. Complete freedom. |
| `dynamic_landing` | Populated with lead + salesperson data from IDAP | `/lp/` routes only |

---

## Theme Palette

Six settings fields control the site's color palette. Null values fall back to the canonical dark default.

| Setting | Purpose | Default |
|---|---|---|
| `primary_color` | Accent — CTAs, links, highlighted borders | `#eebf01` (SpiderIQ yellow) |
| `surface_color` | Body / main background | `#0A0A0B` (near-black) |
| `surface_elevated_color` | Card / panel background | `#111113` |
| `subtle_color` | Border / subtle background | `#1A1A1D` |
| `body_text_color` | Default body text | `#e5e5e5` |
| `heading_color` | Headings / logo text | `#ffffff` |

**Make the whole site light:**

```json
PATCH /dashboard/projects/{pid}/content/settings?dry_run=true
{
  "primary_color":          "#3b82f6",
  "surface_color":          "#ffffff",
  "surface_elevated_color": "#f5f5f5",
  "subtle_color":           "#e5e5e5",
  "body_text_color":        "#18181b",
  "heading_color":          "#0a0a0a"
}
```

Then confirm with the returned `confirm_token`.

**CSS variables exposed:** `--primary`, `--primary-rgb`, `--surface`, `--surface-elevated`, `--subtle`, `--body-text`, `--heading`. Components can reference them directly — e.g. `background: var(--surface-elevated);`.

**Important:** `primary_color` is ONLY the accent. It does NOT change the page background. If you want "the whole site dark/light," set the surface/text fields.

---

## Customize Header/Footer

For changes beyond colors — custom markup, different navigation layout, removing chrome entirely — use per-client template overrides. This is THE supported path. Three tools:

```
content_get_section_source({ section: "footer" })
  → { path: "sections/footer.liquid", source: "<footer class=...>", is_override: false }

# modify the returned Liquid in your own context …

content_override_section({ section: "footer", liquid: "<footer class='my-dark'>...</footer>" })
  → uploads to your client's KV; takes precedence over the default

content_deploy_preview() → content_deploy_production(confirm_token)
  → ships
```

**Sections available:** `header`, `footer`, `layout`, `head`, `hero`.

**Layout presets** for common "wrap the whole site differently" asks:

```
content_apply_layout_preset({ preset: "default" | "blank" | "landing" })
  → uploads a canned layout/theme.liquid override
```

### Chrome auto-skip (2026-04-24) — simpler for per-page custom header/footer

If a page has a block whose component has `category: "header"` (or `"footer"`), the renderer now **automatically suppresses** the native `{% section 'header' %}` (or `'footer'`) for that page. You get one chrome per page, no double-render, no `template='blank'` fallback.

```bash
# Mark your custom header component:
POST /dashboard/projects/{pid}/content/components
{ "slug": "acme-header", "category": "header", "html_template": "...", "css": "..." }

# Use it in a page block — native header auto-suppressed:
{ "slug": "home", "blocks": [{"id":"b1","type":"component","component_slug":"acme-header"}, ...]}
```

Prefer this over `content_override_section` when the header/footer should vary per-page. Prefer `content_override_section` when it's a site-wide design change (darker style, different logo placement, etc.).

**Manual override** — rides on the existing `custom_fields` JSONB on `content_pages`:

```json
{ "custom_fields": {"hide_native_chrome": true} }
// granular:
{ "custom_fields": {"hide_native_header": true, "hide_native_footer": false} }
```

### Default background is dark — override via settings

`--surface` defaults to `#0A0A0B` (Tailwind `slate-950`). Components without an explicit `:host { background-color: ... }` render invisible on a light-themed design. Two fixes:

1. **Site-wide light theme:** set `surface_color: "#ffffff"` via Theme Palette above. Every component's `:host` inherits `var(--surface)`.
2. **Per-component background:** always declare `:host { background-color: ... }` in the component's `css` field. Required for any component that might appear on a light or mixed-surface site.

Also: `font-family` does NOT inherit into the Shadow DOM root. Declare it in the component's `css` or rely on the theme CSS variables injected into `:host` by the renderer.

### Empty-string props now suppress `default_props` (2026-04-24)

Passing `props.image: ""` on a page block now correctly overrides `default_props.image: "/placeholder.jpg"`. Falsy-but-meaningful values (`0`, `false`) are preserved — the filter only drops empty strings and `null`.

### Preview a single component in isolation (2026-04-24)

Before a full-site deploy, render one component standalone for quick Shadow DOM / layout checks (~100–300 ms):

```bash
POST /dashboard/projects/{pid}/content/components/{component_id}/preview
{ "props": { "headline": "Hello" }, "viewport": "desktop" }
# → { html, css, js, custom_element_tag, merged_props, framework?, bundle_url? }
```

Drop the returned `html` into an `<iframe srcdoc="...">`. Full recipe: [examples/preview-component.sh](examples/preview-component.sh).

### Audit internal links before deploy (2026-04-24)

Walks every published page's blocks + all navigation menus; compares `/path` references against published pages/posts + active redirects:

```bash
GET /dashboard/projects/{pid}/content/audit/links
# → { valid_count, broken: [{path, source, reason}], proposed_redirects, known_redirects }
```

`source` = exact tree position (e.g. `page:home/block[2].cta_primary.url`). Runnable: [examples/audit-links.sh](examples/audit-links.sh). Recipe: [skills/recipes/link-audit/](skills/recipes/link-audit/).

| Preset | What it produces |
|---|---|
| `default` | Header + footer, standard `bg-surface` body |
| `blank` | No header, no footer, no body classes — complete freedom for full-bleed heroes |
| `landing` | Header retained, no footer, full-bleed main |

**Do NOT** build JavaScript that queries `document.querySelector('body > footer')` from a component's JS to modify site chrome — it breaks on Shadow DOM hydration, flashes unstyled content, and drops on edge cache flushes. Use `content_override_section` instead. Every live client does.

Used in production by: `thedanmagi.com`, `sms-chemicals.com`, `mail.spideriq.ai`.

---

## Scroll-Linked Hero (Image Sequence)

Cinematic scroll-scrubbed frame sequence heroes (like `thedanmagi.com`) are a Tier 3 component pattern. The canonical reference is `danmagi-flow-video` v1.3.0. The recipe:

**HTML:**
```html
<section class="flow-sequence-container">
  <div class="flow-sticky">
    <canvas id="flow-canvas"></canvas>
  </div>
</section>
```

**CSS:**
```css
:host { display: block; }
.flow-sequence-container { height: 400vh; position: relative; background: var(--surface); }
.flow-sticky {
  position: sticky; top: 0;
  height: 100vh; width: 100%;
  overflow: hidden;
  display: flex; align-items: center; justify-content: center;
}
#flow-canvas { width: 100%; height: 100%; object-fit: contain; }
```

**JS** (with `dependencies: ["gsap", "gsap/ScrollTrigger"]`):
```js
const frameCount = 120;
const frameUrl = i => `https://YOUR-FRAMES/frame_${String(i+1).padStart(4,'0')}.jpg`;
const canvas = root.querySelector('#flow-canvas');
const ctx = canvas.getContext('2d');
canvas.width = 1280; canvas.height = 720;
const images = [];
const seq = { frame: 0 };
for (let i = 0; i < frameCount; i++) {
  const img = new Image();
  img.src = frameUrl(i);
  img.onload = () => { if (Math.round(seq.frame) === i) ctx.drawImage(img, 0, 0, 1280, 720); };
  images.push(img);
}
const init = () => {
  if (typeof gsap === 'undefined' || typeof ScrollTrigger === 'undefined') return setTimeout(init, 50);
  gsap.registerPlugin(ScrollTrigger);
  gsap.to(seq, {
    frame: frameCount - 1, snap: 'frame', ease: 'none',
    scrollTrigger: { trigger: root.querySelector('.flow-sequence-container'), start: 'top top', end: 'bottom bottom', scrub: 1 },
    onUpdate: () => { const f = Math.round(seq.frame); if (images[f]?.complete) ctx.drawImage(images[f], 0, 0, 1280, 720); }
  });
};
init();
```

**Frame hosting:** any public R2/S3 bucket, `https://media.cdn.spideriq.ai/...` (via our media upload endpoint), or the client's KV at `/_assets/...`. ~120 frames @ ~50 KB each = ~6 MB total.

**Pair with:** `page.template: "blank"` so the hero fills the viewport without the default header/footer chrome.

---

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
- **Use `var(--primary)`, `var(--surface)`, `var(--body-text)`** etc. for theme colors — auto-injected into every component's Shadow DOM
- **JS scoping (Tier 2+):** `root.querySelector()` only, never `document.querySelector()`. `root` is the shadowRoot, `props` is the merged props object
- **Never use JS to modify site chrome** — the component's Shadow DOM cannot cleanly reach the outer document's header/footer. Use `content_override_section` (see above)
- **CDN libraries (Tier 3):** set `dependencies` array with allowlist keys. Check `GET /content/cdn-allowlist` for available libraries (`gsap`, `gsap/ScrollTrigger`, `chartjs`, `swiper`, `lottie`, `three`, `animejs`, `alpinejs`, `countup` — 10 libraries). Framer Motion is NOT allowlisted (React-only — use Tier 4 if you need it)
- **Framework (Tier 4):** set `framework` (react/vue/svelte) + `source_code`. Publish returns 202 (async build). Poll `build-status` endpoint
- **Props:** define `props_schema` (JSON Schema) + `default_props`. Block props override defaults
- **Status flow:** draft → published → archived. Only published components render on live pages
- **publish / archive / delete are gated** (dry_run → confirm_token)

### Component API
```
POST   /dashboard/projects/{pid}/content/components                       — create
PATCH  /dashboard/projects/{pid}/content/components/{id}                  — update
POST   /dashboard/projects/{pid}/content/components/{id}/publish          — publish (gated; Tier 4 returns 202)
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

---

## Dynamic Landing Pages

For personalized outreach pages — each visitor sees their own business data from the CRM.

- **Template:** `dynamic_landing`
- **URL:** `/lp/{page_slug}/{google_place_id}` or `/lp/{page_slug}/{salesperson}/{google_place_id}`
- **Preferred vocabulary — email-marketing-style merge tags** (the same Mailchimp/HubSpot/ActiveCampaign tokens every LLM already knows):
  - `{{ firstname }}` `{{ lastname }}` `{{ full_name }}` `{{ job_title }}` — top contact (owner/founder/exec-prioritized)
  - `{{ company_name }}` `{{ legal_name }}` `{{ industry }}` `{{ description }}` — the business
  - `{{ city }}` `{{ country_code }}` `{{ address }}` `{{ postal_code }}` — location
  - `{{ rating }}` `{{ reviews_count }}` `{{ team_size }}` `{{ founded }}` `{{ revenue }}` — vitals
  - `{{ email }}` `{{ phone }}` `{{ mobile }}` `{{ logo }}` `{{ website }}` — contact + branding
  - Arrays for `{% for %}`: `{{ emails }}` `{{ phones }}` `{{ contacts }}` `{{ officers }}` `{{ pain_points }}` `{{ categories }}`

  **Full reference:** [MERGE-TAGS.md](./MERGE-TAGS.md) in this starter kit · live at https://docs.spideriq.ai/site-builder/merge-tags/ · API: `curl https://spideriq.ai/api/v1/content/variables?format=yaml` · MCP tool: `content_get_variables` (flagged "START HERE" in `@spideriq/mcp-publish@0.1.0+` and `@spideriq/mcp@0.8.3+`).

- **Null-safe:** every singular returns `""` when missing, every array returns `[]`. `{% if revenue %}` branches correctly. `{{ revenue | default: "not on file" }}` gives fallbacks.
- **Preview without real data:** `/lp/{slug}/demo` — serves the built-in Mario's Pizzeria fixture (every tag populated).
- **Power-user escape hatch:** the raw `lead.*` nested shape is still in scope — use for fields not surfaced as merge tags (e.g. `{{ lead.related.domains[0].company_vitals.tech_stack }}`).
- **Salesperson URLs:** `/lp/{slug}/{salesperson}/{place_id}` also exposes `{{ salesperson.name }}`, `{{ salesperson.calendar_url }}`, etc. from template config.

**Ready-to-run example:** [`examples/personalized-landing.sh`](./examples/personalized-landing.sh) — creates + publishes + deploys a merge-tag template end-to-end in ~30 seconds.

---

## Directory Pages

SEO-friendly programmatic pages at `/directory`, `/directory/{category}`, `/directory/{category}/{city}`, `/directory/{category}/{city}/{listing}`. The tenant Liquid renderer ships `directory-category.liquid`, `directory-city.liquid`, `directory-listing.liquid` by default — no custom template needed.

```
# 1. Category
directory_create_category(name="Plumbers", slug="plumbers", description="Licensed plumbers and emergency services")

# 2. Listings — bulk insert JSON array OR pull normalized data from an IDAP bundle
directory_bulk_upsert_listings(category_slug="plumbers", listings=[...])
# OR
directory_import_from_idap(category_slug="plumbers", idap_bundle_id="<bundle_id>")

# 3. Deploy
content_deploy_site(dry_run=true) → confirm_token → confirm
```

Listings auto-join `/sitemap.xml` on publish. Override default templates via `content_override_section("templates/directory-listing", liquid_source=...)` if you need a custom layout.

**Ready-to-run example:** [`examples/directory-bulk-import.sh`](./examples/directory-bulk-import.sh) — seed a category from a listings JSON file.

**Full guide:** [`skills/recipes/directory/`](./skills/recipes/directory/)

---

## Booking (Appointments)

Cal.com-powered appointment booking for any tenant. Ships a customer widget (`<spider-booking-widget>`), a standalone route at `/book/{flow_id}`, and a `{% booking %}` Liquid tag for embedding inside any page template.

```
# 1. Find an archetype and clone it into the tenant's library
booking_template_list(category="nail-salon")
booking_template_clone(template_id="nail-salon-default", business_id="<uuid>", name="Downtown Salon Bookings")

# 2. Theme + translate (optional)
booking_flow_update(flow_id=<id>, theme={primary_color: "#e8556f", button_label: "Book now"},
                    translations={"es": {"steps.pick_service.label": "Elige un servicio"}})

# 3. Publish — dry_run first (provisions the cal.com event type on commit)
booking_flow_publish(flow_id=<id>, dry_run=true)      → confirm_token
booking_flow_publish(flow_id=<id>, confirm_token=...) → live

# 4. Grab the public URL
booking_flow_preview(flow_id=<id>)                    → /book/{flow_id}

# 5. Redeploy so the Liquid tag / /book route pick up the new flow
content_deploy_site(dry_run=true) → confirm_token → confirm
```

Embed in a page template:
```liquid
{% booking flow_id: business.booking_flow_id %}
```

Customer self-service uses the signed `manage_token` from the confirmation email:
```
booking_reschedule(manage_token="bkm_...", new_slot_start="2026-04-20T14:00:00Z")
booking_cancel(manage_token="bkm_...", reason="customer request")
```
(Reschedule / cancel are NOT gated server-side — they hit cal.com directly. Confirm with the caller before firing.)

**Ready-to-run example:** [`examples/booking-flow.sh`](./examples/booking-flow.sh) — clone → theme → publish → preview → deploy in one script.

**Full guide:** [`skills/booking/`](./skills/booking/)

---

## Change a Component Everywhere (Component Propagation)

When you edit a shared component (a `header`, `hero`, `footer`, `cta` block), every page that references it needs its block version pin updated. The one-shot tool handles all of that in a single call.

```
# Preview the blast radius
component_update_and_propagate(
  slug="hero", css="...new rules...", bump="patch",
  dry_run=true
)
# → returns affected_pages=[{slug, block_index, old_version, new_version}, ...], confirm_token

# Commit
component_update_and_propagate(slug="hero", css="...", bump="patch", confirm_token="cft_...")

# Roll back if needed — creates a new forward version with the old content, repoints pages
component_rollback(slug="hero", version="1.4.2")
```

Staging the rollout: pass `pages=["home"]` on the first commit to update only the home page, validate, then call again with `pages` omitted to roll to all.

**Full guide:** [`skills/recipes/component-update-and-propagate/`](./skills/recipes/component-update-and-propagate/)

---

## Uploading Images

```bash
# Import from URL (recommended)
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }

# Returns: { "url": "https://media.cdn.spideriq.ai/..." }
# Use in blocks: { "type": "image", "data": { "url": "https://media.cdn.spideriq.ai/..." } }
```

---

## IDAP Data Access

Read CRM data (businesses, emails, contacts, phones):
- `GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml`
- `GET /api/v1/idap/businesses/{id}?include=emails,phones,domains,contacts`
- `GET /api/v1/idap/businesses/resolve?place_id={google_place_id}`
- `POST /api/v1/idap/businesses/{id}/flags` — flag leads as qualified/contacted

---

## Templates

Ready-to-submit payloads are in the `templates/` directory:
- `templates/homepage.json` — company homepage (`template: "landing"`)
- `templates/blog-setup.json` — blog with author + posts
- `templates/dynamic-landing.json` — personalized outreach page

Submit any template: read the JSON, then `POST /api/v1/dashboard/projects/{pid}/content/pages` with the payload.

---

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
- Full Reference: `GET /api/v1/content/help` (YAML — includes `tasks` index, `chrome_override`, `theme_palette`, `session_binding`, `deploy_workflow`)

---

## Marketplace V2 — Find by intent (May 2026)

The marketplace has two access patterns. Use the right one for the task:

| Pattern | When | Tool |
|---|---|---|
| **Browse by category** | "Show me all hero blocks" | `content_list_marketplace_components(category="hero")` |
| **Search by intent** | "Find me a calm cinematic background for a luxury hotel" | `marketplace_search(mood=["calm"], brand_fit=["hospitality"], asset_types=["bg_video"])` |

`marketplace_search` filters across all 3 marketplace tables (bg-videos / components / site-templates) by 4 universal axes + per-asset `agent_meta`:

```
Universal axes (top-level columns; NOT inside agent_meta):
  mood          TEXT[]    any-of match in search; controlled vocabulary
  palette       TEXT[]    any-of match; free-form (cap 12 entries on write)
  brand_fit     TEXT[]    any-of match; controlled vocabulary
  scene_type    VARCHAR   single-value; controlled vocabulary

Per-asset agent_meta (JSONB, extra="forbid"):
  bg_video       → pace, time_of_day, weather, has_people, aspect_ratio,
                   has_audio, music_tempo_bpm, transcript
  component      → interaction_pattern, trigger_kind, placement,
                   motion_safety, accessibility_notes, conversion_strategy
  site_template  → page_count, has_blog, has_pricing, has_directory,
                   has_booking, conversion_strategy, style_aesthetic,
                   component_set
```

Full vocabulary in `skills/content-platform/schema.yaml` under `marketplace_v2_axes:`. Or `template_get_help` returns the canonical YAML.

### 4-class behavioural taxonomy (`kind`)

Every component carries a `kind` that dictates how the renderer treats it:

| kind | Props? | Reads data? | JS? | Examples |
|---|---|---|---|---|
| `static` | ✓ | – | no | hero-headline, faq-accordion, pricing-3tier |
| `interactive` | ✓ | – | yes | sys-timer-fixed-date, sys-popup-exit-intent |
| `dynamic` | ✓ | yes | optional | List, Item Details — bind to a source via `data_binding` |
| `extension` | ✓ | yes | varies | sys-geo-md-mirror (renderer hooks, not in-page UI) |

Set with `set_component_kind(component_id, kind)`. Server-side CHECK constraints enforce invariants — `kind="dynamic"` requires `block_type` + non-empty `sources` to be set on the row first, or the PATCH 400s.

### Curate for findability

If you create a component clients should be able to find via intent search, set the discovery axes after publishing:

```
set_component_agent_meta(
  component_id = "...",
  mood = ["calm", "editorial"],
  brand_fit_tags = ["saas", "agency"],
  scene_type = "feature-grid",
  agent_meta = {
    interaction_pattern: "static",
    placement: "above-fold",
    conversion_strategy: "education"
  }
)
```

Same shape for `set_bg_video_agent_meta` (super_admin) and `set_site_template_agent_meta` (super_admin) but with the per-asset agent_meta keys.

### Insert flow

```
marketplace_search(mood=["calm"], asset_types=["bg_video"])     → pick a slug
content_insert_section(page_id, component_slug="sys-bg-video",
                       props={video_slug: "<chosen>"},
                       position="start", dry_run=true)            → confirm_token
content_insert_section(... confirm_token=<token>)                → committed; page in draft
content_publish_page(page_id, dry_run=true) → confirm           → published
content_deploy_site_production(confirm_token=...)               → live on edge
```

Full recipe: `skills/recipes/marketplace-search-and-insert/`. Runnable: `examples/marketplace-search-and-insert.sh`.

---

## GitHub

- Public repo: https://github.com/SpiderIQ/SpiderPublish/tree/main/designer-kit

---

# SpiderPublish — AGENTS.md

> Full version: [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents)
> **VSCode / Cursor / Antigravity extension (v0.1.0+):** [docs.spideriq.ai/extension](https://docs.spideriq.ai/extension) — install the SpiderPublish extension to operate this CMS from your IDE: native diffs, snapshot-bound preview→confirm push, JSONPath → file:line diagnostics, pre-push link audit with "Accept redirect" Quick Fix. The extension wraps the same `@spideriq/mcp-publish` surface this AGENTS.md describes — anything you can do via raw MCP, you can do via the extension UI.
> **Antigravity Knowledge Items:** the kit ships 11 pre-built KIs in [`knowledge/antigravity/`](./knowledge/antigravity/) covering capability discovery, page creation, marketplace search, deploy, personalized landing, booking, scroll-sequence, GEO readability, MCP package picking, CLI reference, and IDE extension setup. Install with `bash examples/install-antigravity-kis.sh` — copies them to `~/.gemini/antigravity/knowledge/`. Antigravity auto-loads relevant KIs based on user intent; no `/slash` invocation needed.
> **Session Binding (Phase 11+12):** [docs.spideriq.ai/site-builder/sessions](https://docs.spideriq.ai/site-builder/sessions)
> **Deploy Safely (preview→confirm):** [docs.spideriq.ai/site-builder/deploy-safely](https://docs.spideriq.ai/site-builder/deploy-safely)
> Component Builder: [docs.spideriq.ai/site-builder/component-builder](https://docs.spideriq.ai/site-builder/component-builder)
> Tiers Reference: [docs.spideriq.ai/site-builder/component-tiers](https://docs.spideriq.ai/site-builder/component-tiers)
> Agent Reference: [docs.spideriq.ai/site-builder/component-agents-reference](https://docs.spideriq.ai/site-builder/component-agents-reference)

**Current package versions (1.7.0, 2026-05-06):** `@spideriq/cli@1.7.0`, `@spideriq/mcp-publish@1.7.0`, `@spideriq/core@1.6.0`. **New in 1.7.0:** `marketplace_suggest_agent_meta` — wraps the SpiderGate-powered inference engine so external LLM agents can suggest mood / palette / brand_fit_tags / scene_type / agent_meta for marketplace assets they upload (two-step: suggest → review → apply via the existing `set_*_agent_meta` tools). The atomic publish slice now exposes **7 Marketplace V2 tools** total (search, list_data_sources, set_component_kind, set_component_agent_meta, set_bg_video_agent_meta, set_site_template_agent_meta, marketplace_suggest_agent_meta) — see the "Marketplace V2" section below. The kitchen-sink `@spideriq/mcp@1.7.0` totals 126 tools and bundles SpiderBook booking + mail / leads / gate / admin slices. The starter kit's `.mcp.json` defaults to `@spideriq/mcp-publish` — under the ~128-tool injection limit enforced by some IDE/LLM stacks, and less context burn per message.

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
| `423 page_locked` | Page is locked by another actor (P4) | Read `detail.unlock_endpoint` + `locked_reason` — back off OR call `content_unlock_page` if you're the lock-holder |
| `403 force_required` | `?force=true` from a non-super_admin / non-brand_admin role | Either elevate, or wait for the lock-holder to unlock |

### Page Locking + Version Restore (P4, 2026-05-09)

Pages can be **locked** against further edits during client review or scheduled launch. Mutations on a locked page (`content_update_page`, `content_publish_page`, `content_unpublish_page`, `content_delete_page`, `content_insert_section`, `content_restore_page_version`) return **HTTP 423 Locked** with this body:

```json
{
  "detail": {
    "error": "page_locked",
    "message": "Page is locked by api:cli_xxx.",
    "locked_by_actor_id": "api:cli_xxx",
    "locked_at": "2026-05-09T21:11:00Z",
    "locked_reason": "client review week of 2026-05-12",
    "unlock_endpoint": "/api/v1/dashboard/projects/cli_xxx/content/pages/<id>/unlock"
  }
}
```

**Recovery path:** parse `locked_by_actor_id`. If it matches your `actor_id`, call `content_unlock_page({page_id})`. Otherwise read `locked_reason` — if it names a deadline, back off. Do NOT loop on the 423 retry without backoff; the lock provenance won't change until someone explicitly unlocks. Versions endpoints (`content_list_page_versions`, `content_get_page_version`) are read-only and work on locked pages.

**5 new MCP tools** in `@spideriq/mcp-publish@1.11.0+` and kitchen-sink `@spideriq/mcp@1.11.0+` (94 atomic tools total):

| Tool | What it does |
|---|---|
| `content_lock_page({page_id, reason?})` | Lock the page. Idempotent — re-locking refreshes `locked_at` and `reason`. |
| `content_unlock_page({page_id, force?})` | Unlock. Default — only the lock-holder. `force=true` requires super_admin or brand_admin (server-enforced). |
| `content_list_page_versions({page_id})` | Snapshot log (newest first) — `version_number`, `title`, `block_count`, `blocks_size`, `change_summary`, `created_at`. |
| `content_get_page_version({page_id, version_number})` | Single snapshot in full (with `blocks`) — diff against current before restore. |
| `content_restore_page_version({page_id, version_number, dry_run?, confirm_token?, force?})` | Phase 11+12 dry_run/confirm_token gated. Appends new version row recording the restore. |

Recipe walkthrough: [`shared/recipes/lock-during-review/SKILL.md`](../recipes/lock-during-review/SKILL.md).

### Rules + Audit envelope (P5, 2026-05-10)

Every component-targeted MCP mutation now ships a **`_rules`** block on `dry_run` and an **`_audit`** block on the success response. Reads of `content_get_page` decorate with **`_page_audit`** when `audit_level != off`. Replaces "insert blindly and hope it renders" with a single-roundtrip authoring loop where the agent learns the canonical tool path BEFORE inserting and sees broken state IMMEDIATELY on the response.

**Three rule sources** composed by the server (no agent action required):

| Source | Where it comes from | When present |
|---|---|---|
| **A — intrinsic** | derived from the component's `kind` / `dependencies` / `props_schema` at request time | always |
| **B — authored** | raw passthrough from `content_components.authoring_hints` (the `preferred_path`, `common_mistakes`, `must_set`, `must_not_set` fields) | when the component author populated the column |
| **C — cross_cutting** | `PageAuditor.audit_page` findings on the target page BEFORE the mutation lands | only on dry_run of `page_insert_section` |

**`_rules` envelope (on dry_run):**

```json
{
  "preview": {...},
  "confirm_token": "cft_xxx",
  "expires_at": "...",
  "_rules": {
    "component_slug": "sys-scroll-sequence",
    "component_version": "1.1.0",
    "kind": "interactive",
    "intrinsic": [
      { "rule_id": "intrinsic.scroll_sequence_frames_required", "severity": "error", "message": "...", "suggested_fix": "..." }
    ],
    "authored": {
      "preferred_path": "Use the video_to_scroll_sequence MCP tool — it extracts frames from a video file and creates this block in one call.",
      "must_set": ["frames"]
    },
    "cross_cutting": [...]
  }
}
```

**`_audit` envelope (on the actual mutation):**

```json
{
  "success": true,
  "page_id": "...",
  "new_block_id": "...",
  "_audit": {
    "site_level":      [],
    "page_level":      [],
    "block_level":     [{ "rule_id": "insertion.scroll_sequence_empty_frames", "severity": "error", "scope": "block", "target": "<id>", "message": "...", "suggested_fix": "..." }],
    "component_level": [],
    "summary": { "errors": 1, "warnings": 0, "info": 0 }
  }
}
```

**Mutation rules (P5):**

| Severity | Rule | Catches |
|---|---|---|
| error | `insertion.scroll_sequence_empty_frames` | scroll-sequence inserted with 0 frames bound — section renders blank at runtime |
| error | `insertion.unknown_component` | `component_slug` doesn't resolve for this client (not in library, not global) |
| error | `creation.interactive_without_js` | new component with `kind=interactive` but no `js` body — hydrates as static markup |
| warn | `insertion.missing_required_prop` | `authoring_hints.must_set` lists a prop that's empty/absent |
| warn | `insertion.forbidden_prop` | `authoring_hints.must_not_set` lists a prop that's present |
| warn | `creation.kind_null_with_dependencies` | new component declares CDN deps but `kind=NULL` → invisible to marketplace_search |
| warn | `creation.global_empty_agent_meta` | new global component with empty `agent_meta` |
| info | `insertion.preferred_path_hint` | surfaces `authoring_hints.preferred_path` so you learn the canonical tool |
| info | `creation.empty_authoring_hints` | global component shipped with no hints — agents inserting it lose guidance |

**The `audit_level` toggle** (`off | errors | warnings | all`):

- `content_get_page` — default `warnings` (errors + warnings on the `_page_audit` block)
- `page_insert_section` — default `all` (every finding on the `_audit` block)
- `off` is the escape hatch for tight-loop scripts that bulk-insert and audit later via `content_export_page`

**Component-author write surface** — `authoring_hints` on `content_create_component` / `content_update_component`:

```js
content_create_component({
  slug: "my-component",
  // ... other args ...
  authoring_hints: {
    preferred_path: "Use my_helper_tool, not manual insert.",  // info on dry_run
    common_mistakes: ["Forgetting props.thank_you_url"],        // visible to inserting agents
    must_set:        ["headline", "submit_endpoint"],           // missing → warn
    must_not_set:    ["_internalKey"]                           // present → warn
  }
})
```

Empty `{}` (the column default) = no hints; component degrades cleanly to intrinsic-only rules. PATCH semantics on update: passing `{}` REPLACES stored hints with empty; omit the field to leave them untouched.

**Backwards compatible** — agents that ignore `_rules` / `_audit` / `_page_audit` aren't broken. Components with empty `authoring_hints` (the default) still get intrinsic-only rules. Versions: `@spideriq/mcp-publish@1.12.0+`, `@spideriq/mcp@1.12.0+`, `@spideriq/core@1.12.0+`.

Recipe walkthrough: [`shared/recipes/audit-driven-edit/SKILL.md`](../recipes/audit-driven-edit/SKILL.md). Sibling recipes: [`audit-and-fix`](../recipes/audit-and-fix/SKILL.md) (P2 — walks an existing page through the auditor), [`lock-during-review`](../recipes/lock-during-review/SKILL.md) (P4 — pair with this recipe to lock during the audit-edit cycle).

### PAT Auth Errors (2026-04-24)

Distinguishable from the confirm-token errors above. Body is `{"detail": {"error": "<code>", "message": "...", "expires_at"?: "..."}}`.

| Status | `error` code | What it means |
|---|---|---|
| `401` | `token_expired` | Your PAT passed `expires_at`. Body includes `expires_at` + a link to regenerate. Run `spideriq auth request --email <admin>` or visit `https://app.spideriq.ai/settings/tokens`. |
| `401` | `token_invalid` | PAT is unknown/malformed. Check `~/.spideriq/credentials.json` or re-auth. |
| `401` | (no `error` field) | Legacy path — still supported but agents should treat as `token_invalid`. |

### `whoami` — check your binding (2026-04-24)

Before a destructive deploy, confirm which project your PAT is bound to:

```bash
curl -H "Authorization: Bearer $SPIDERIQ_PAT" https://spideriq.ai/api/v1/auth/whoami
# → {authenticated, auth_type, client_id, project_name, email, role, scopes, token_expires_at, token_id, session_binding}
# Or via CLI:
npx @spideriq/cli auth whoami
```

Returns the resolved project_name (company_name on the client record) — no more trial-and-error API calls to figure out which workspace a token belongs to.

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

### Duplicate page / post / doc / block (2026-04-24)

Cheap primitive that unblocks every "starter content" workflow — fork an existing page as a draft, deep-copy a block in place, re-use a blog post template. The duplicate gets `status='draft'`, fresh UUIDs on every block, and an auto-generated `{slug}-copy[-N]` slug (lowest unused suffix) unless you pass `new_slug`.

```bash
# MCP
content_duplicate_page(page_id="...", new_slug="...")     # optional new_slug
content_duplicate_block(page_id="...", block_id="...", position="after"|"before"|N)
content_duplicate_post(post_id="...", new_slug="...")
content_duplicate_doc(doc_id="...", new_slug="...")

# CLI
spideriq content pages:duplicate <page_id> [--slug <new>]
spideriq content blocks:duplicate <page_id> <block_id> [--position before|after|N]
spideriq content posts duplicate <post_id> [--slug <new>]
spideriq content docs:duplicate <doc_id> [--slug <new>]

# REST
POST /dashboard/projects/{pid}/content/pages/{page_id}/duplicate
POST /dashboard/projects/{pid}/content/pages/{page_id}/blocks/{block_id}/duplicate
POST /dashboard/projects/{pid}/content/posts/{post_id}/duplicate
POST /dashboard/projects/{pid}/content/docs/{doc_id}/duplicate
```

**Not gated by `dry_run`/`confirm_token`** — these are net-additive (new draft row), not destructive overwrites. 409 on slug collision when `new_slug` is provided; 404 if the source isn't owned by the caller's tenant. Title gets " (Copy)" appended so the dashboard shows it distinctly.

Runnable example: [examples/duplicate-page.sh](./examples/duplicate-page.sh).

### Block Types
`hero`, `features_grid`, `cta_section`, `testimonials`, `pricing_table`, `faq`, `stats_bar`, `rich_text`, `image`, `video_embed`, `code_example`, `logo_cloud`, `comparison_table`, `spacer`, `component`

### Block Payload Schema (strict since 2026-04-24)

Every block in `content_pages.blocks[]` has this canonical shape:

```json
{
  "id": "required unique string (UUID recommended)",
  "type": "one of the BlockType values above",
  "data": { /* type-specific; see below */ },
  "component_slug": "REQUIRED when type='component' (top-level, NOT data.slug)",
  "component_version": "optional pinned version; omit for latest published",
  "props": { /* optional dict passed to the component template */ }
}
```

**Type-specific `data` requirements:**

- `type: "component"` → MUST set `component_slug` at the block's top level.
  Reference JSON: [components/block-component.json](components/block-component.json).
- `type: "rich_text"` → MUST set `data.html` (raw HTML string) OR `data.content` (Tiptap JSON).
  Reference JSON: [components/block-rich-text.json](components/block-rich-text.json).
- Native-typed blocks (`hero`, `features_grid`, etc.) → `data` carries the block's own fields.

**Anti-patterns now rejected with 422** (used to silently 200 OK + render blank):

- `{type: "component", data: {slug: "...", props: {}}}` — move `slug` to the top-level `component_slug` field. The error message names `data.slug` and points to the fix.
- `{type: "rich_text", data: {text: "..."}}` — use `data.html` or `data.content`.
- Unknown fields on `POST/PATCH /components` (like `css_styles` instead of `css`) — the response returns 200 with a `warnings[]` array listing each ignored field + a "Did you mean X?" hint. Check the response body.
- Slug with `/` (e.g. `product/xyz`) — rejected at creation; use flat slugs like `product-xyz`. Nested doc paths use `parent_id` chains.

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

### Upload Images / PDFs / Video (from a URL)
```bash
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }
# Deterministic keys (no YYYYMMDD_HHMMSS_ prefix): pass preserve_filename
{ "url": "...", "filename": "logo.png", "preserve_filename": true, "folder": "brand" }
```

### Upload from your local filesystem — preferred for bulk (v0.9.4+)

One MCP/CLI call uploads a file or a whole directory. Scroll-sequence folders auto-optimize (Sharp → WebP q75, max 1920px) before upload, so a 120 × 1.6 MB input doesn't become a 192 MB CDN bill.

```
# MCP
upload_local_file(local_path="./logo.webp", folder="brand")
upload_local_directory(local_dir="./frames/", folder="scroll-sequences/hero")
# → auto-enables auto_optimize=true + preserve_filename=true when folder starts with "scroll-sequences/"

# CLI
spideriq media upload ./logo.webp --folder brand
spideriq media upload ./frames/ --folder scroll-sequences/hero
```

Server enforces weight policy and returns 400 with `suggested_action` if you bust it:

| Target folder | Per-file hard | Batch total hard |
|---|---|---|
| `scroll-sequences/*` | 500 KB | 20 MB |
| general | 20 MB | 500 MB |
| `video/*` MIME | 500 MB | 500 MB (single-file cap is per-file limit) |

Full recipe: **[skills/recipes/bulk-media-upload/](./skills/recipes/bulk-media-upload/SKILL.md)**

### Directory Pages (programmatic SEO, v2.89.0+)

Build a per-category + per-city + per-listing directory with SEO title/description templates that auto-interpolate `{category}`, `{city}`, `{listing}`. Every URL auto-lands in `/sitemap.xml`.

```
# 1. Create the category
directory_create_category(
  name = "Plumbers",
  seo_title_template = "Best {category} in {city} | Your Brand"
)

# 2. Drop in an IDAP dump or SpiderMaps result set (up to 5000 per call)
directory_bulk_upsert_listings(
  category_slug = "plumbers",
  listings = [{name, city, state, phone, website, rating, ...}, ...]
)
# → /directory/plumbers, /directory/plumbers/miami-beach-florida,
#   /directory/plumbers/miami-beach-florida/aqua-fix all live, sitemap updated.
```

No publish step. No deploy step. `city_slug` computed automatically from `city + state`. Full recipe: **[skills/recipes/directory/](./skills/recipes/directory/SKILL.md)** · Example: **[examples/directory-bulk-import.sh](./examples/directory-bulk-import.sh)**.

### Custom Collections (define your own content type, v2.10.0+)

When pages, posts, and docs don't fit, define your **own** content type — case studies, team, FAQs, products. You declare the schema, author the rows, and every published record renders as a first-class page (its own slug, SEO, pretty URL `/{route_base}/{slug}`, and a multi-format body: blocks / Tiptap / Markdown / HTML). The flow is **define → fill → publish → expose → render → deploy**.

```
# 1. Define the collection (schema you declare; 9 field types incl. relationship + blocks)
createCollection(slug="case-studies", label="Case Studies",
  schema_json={ fields: { title:{type:"text"}, client:{type:"text"}, summary:{type:"richtext"} } })

# 2. Bulk-fill rows — 1–100 in ONE transaction (a bad row rejects the whole batch)
bulkCreateCollectionRecords(collection="case-studies", records=[
  { slug:"acme",  data:{ title:"Acme",  client:"Acme Co",   summary:"..." } },
  { slug:"globex", data:{ title:"Globex", client:"Globex LLC", summary:"..." } }
])

# 3. Publish a row — a status change is the GATED transition (dry_run → confirm_token)
updateCollectionRecord(collection="case-studies", record_id=<id>, status="published", dry_run=true)
updateCollectionRecord(collection="case-studies", record_id=<id>, status="published", confirm_token="cft_...")

# 4. Expose it, then render with a kind="dynamic" component (source_id = the collection slug)
updateCollection(slug="case-studies", is_public=true)
# → records live at /case-studies/acme; the full list reads at
#   GET /api/v1/content/data-sources/case-studies/items
```

**Records link to each other** (or to `posts`/`authors`) with simple relationship fields; a `depth` knob hydrates one level, batched (no N+1). **Gotchas:** slugs use hyphens not underscores (`case-studies`); unknown `data` fields are **rejected (422)**, not dropped; **reads use the record slug, writes use the record id**; publishing ≠ deploying; collection/record creates enforce your plan's `max_collections` / `max_records` caps (403). Render with **[skills/recipes/build-a-dynamic-component/](./skills/recipes/build-a-dynamic-component/SKILL.md)**. Full recipe: **[skills/recipes/define-a-custom-collection/](./skills/recipes/define-a-custom-collection/SKILL.md)** · Docs: https://publish.spideriq.ai/docs/ai-agents/custom-collections.

### Dynamic Landing Pages
URL: `/lp/{page_slug}/{google_place_id}` or `/lp/{page_slug}/{salesperson}/{google_place_id}`

**Use flat email-marketing merge tags** (Mailchimp/HubSpot/ActiveCampaign style — every LLM already knows them):
`{{ firstname }}`, `{{ company_name }}`, `{{ city }}`, `{{ industry }}`, `{{ rating }}`, `{{ email }}`, `{{ phone }}`, `{{ logo }}`, `{{ team_size }}`, `{{ founded }}`, `{{ revenue }}`, plus `{% for %}` arrays for `emails`, `phones`, `contacts`, `officers`, `pain_points`, `categories`. ~40 tags total.

**Full reference (read first):** [MERGE-TAGS.md](./MERGE-TAGS.md) · live at https://docs.spideriq.ai/site-builder/merge-tags/ · API: `GET /api/v1/content/variables?format=yaml` · MCP: `content_get_variables` (in `@spideriq/mcp-publish@1.0.0+` and `@spideriq/mcp@1.0.0+`).

**Preview without real data:** `/lp/{slug}/demo` — serves the built-in Mario's Pizzeria fixture with every tag populated.

Power-user: the raw `lead.*` nested shape is still in scope for fields not surfaced as merge tags. `{{ salesperson.* }}` also available when the URL includes a salesperson slug.

Ready-to-run end-to-end: [`examples/personalized-landing.sh`](./examples/personalized-landing.sh).

### Booking / Appointments (SpiderBook — cal.com-powered, v1.0.0+)

Customer-facing booking widget, standalone `/book/{flow_id}` route, and a `{% booking %}` Liquid tag for page templates. Flows are authored from the official archetype library (nail-salon, haircut, therapy, consultation, ...).

```
booking_template_list(category="nail-salon")
booking_template_clone(template_id="nail-salon-default", business_id="<uuid>", name="Downtown Bookings")
booking_flow_update(flow_id=<id>, theme={primary_color: "#e8556f"}, translations={"es": {...}})
booking_flow_publish(flow_id=<id>, dry_run=true)   → confirm_token
booking_flow_publish(flow_id=<id>, confirm_token=...) → live (provisions cal.com event type)
booking_flow_preview(flow_id=<id>)                 → /book/{flow_id}
content_deploy_site(...)                            # redeploy so /book + {% booking %} pick up the flow
```

Embed inside a page template:
```liquid
{% booking flow_id: business.booking_flow_id %}
```

Customer self-service (uses the signed `manage_token` from the confirmation email, NOT gated server-side):
```
booking_reschedule(manage_token="bkm_...", new_slot_start="2026-04-20T14:00:00Z")
booking_cancel(manage_token="bkm_...", reason="...")
```

Reads: `booking_list(business_id, status?, since?)`, `booking_get(booking_id)`. Services (what can be booked): `service_create` / `service_update` / `service_delete` (gated). All tools live in the kitchen-sink `@spideriq/mcp@1.0.0`.

**Full guide:** [skills/booking/](./skills/booking/) · **End-to-end example:** [`examples/booking-flow.sh`](./examples/booking-flow.sh).

### Forms (SpiderFlow — developer/agent preview, v1.13.0+)

Typeform-class multi-step forms — lead capture, NPS / CSAT surveys, intake forms, signup wizards. Reuses the same `booking_flows` table that powers SpiderBook, discriminated by `kind='form'`. Customer fills via the SpiderFlow embed loader (`embed.spideriq.ai/v1/loader.js`, 3 KB gzip ESM, inline + popup modes) or the standalone `/book/<flow_id>` route. **Status: developer / agent preview** — business-user dashboard ships in the next wave.

> **MCP package caveat:** the 20 `form_*` tools are in **kitchen-sink `@spideriq/mcp@1.13.0`** (144 tools) — **not** in `@spideriq/mcp-publish@1.12.1` (124 tools, the starter-kit default). The split exists because Antigravity / Claude Desktop / Codex-on-Responses silently drop MCP servers that report >128 tools. To use the form tools: edit `.mcp.json` to point at `@spideriq/mcp@1.13.0`, OR add it as a second MCP server entry alongside `mcp-publish`.

```
form_create(name="Free trial signup", business_id="<uuid>", fields=[
  {id:"q1", type:"email", label:"Your work email", required:true},
  {id:"q2", type:"text", label:"Company name", required:true}
])                                                                  → flow_id
form_add_field(flow_id, field={id:"q3", type:"select", label:"Team size",
  options:[{label:"1-10", value:"small"}, {label:"11-50", value:"medium"}, {label:"51+", value:"large"}]})
form_add_logic_rule(flow_id, rule={
  when:{field_id:"q3", op:"equals", value:"large"},
  then:{action:"jump_to", field_id:"q_enterprise"}
})
form_validate(flow={...})                                            → client-side; no API call
form_test_submit(flow_id, answers={q1:"test@ex.com", q2:"Acme", q3:"small"})
form_publish(flow_id, title="Trial Signup", length_minutes=1, team_id=0, dry_run=true)  → confirm_token
form_publish(flow_id, confirm_token=...)                             → status: active
form_get_embed_snippet(flow_id, mode="popup", button_text="Get Free Trial")
                                                                     → <script> + <button> snippet
```

Embed on any third-party page (Webflow / Shopify / WordPress / plain HTML):
```html
<button data-spiderflow-flow="<flow_id>" data-spiderflow-mode="popup"
        data-spiderflow-trigger-text="Get Free Trial">Get Free Trial</button>
<script async src="https://embed.spideriq.ai/v1/loader.js"></script>
```

25 field types: `text` / `textarea` / `email` / `phone` / `tel` / `number` / `select` / `checkbox` / `consent` / `date` / `time` / `rating` / `nps` / `opinion_scale` / `picture_choice` / `file_upload` / `statement` / `url` / `country` / `region` / `postal_code` / `address` / `datetime` / `currency` / `place`. The last eight are IDAP-anchored and emit structured, typed values. Picture-choice options carry `image_url`; file-upload requires `accept[]`; opinion-scale `steps` in 5-11 range; rating requires `shape`.

Conditional logic: `form_add_logic_rule` (jump-to / show / hide / set-variable / end-flow), `form_declare_variable` (string / number / boolean with type-checked defaults), `form_add_hidden_field` (URL-param capture: utm_source, ref, etc).

Validation: `form_validate` runs whole-flow structural validation client-side — 14 rule classes (R0–R14) catching JSON shape, kind/schema_version, per-field-type invariants, hidden-field key uniqueness, logic rule cross-references. `form_validate_logic` validates rule shape only.

**Backend caveats (current state, will resolve in next wave):**
- `form_create` requires `business_id` (FK constraint) — pass any business UUID owned by the brand
- `form_publish` requires Cal.com `title` / `length_minutes` / `team_id` — for form-kind, pass any non-empty title, `length_minutes=1`, `team_id=0`
- `form_test_submit ?test=true` honoured for `LOAD_TEST_CLIENT_ID` only — for other clients, use a real flow with a unique answer payload + clean up manually

**SpiderPublish VSCode extension 0.2.0+** treats `kind='form'` rows the same as pages: `Pull Content` writes each to `./forms/<flow_id>.json`; inline form validator catches 14 rule classes with red squiggles; `Push Content` includes form rows; `SpiderPublish: Preview Form` opens `/book/<flow_id>` in the browser.

**`spideriq form` CLI** ships in `@spideriq/cli@1.13.0+` with 7 verbs (`create` / `get` / `update` / `publish` / `embed-snippet` / `responses list` / `responses get`). Mirrors `spideriq booking` 2-phase preview/confirm with `--yolo` / `--confirm <token>` / `--json`.

**Full guide:** [shared/core-skills/forms/](./core-skills/forms/) (kit-internal path; degit users see this under their project's `core-skills/forms/`).

### Commerce Funnels — sell a product (Flow primitive, 2026-06-24)

Pages, forms, funnels, booking widgets, and **commerce funnels** are all the **same primitive** — a
**Flow** (a graph of page *nodes* + event *edges*). `kind` (`page` / `form` / `funnel` / `booking` /
`commerce`) is a label, not a separate product. A **commerce funnel** carries `checkout` + one-time-
offer (`oto`) nodes, takes real Stripe payments, and lands a canonical order.

**Create by forking a template — never hand-build the graph** (the server validates commerce graph
invariants):

```bash
funnel_template_list { kind: "commerce" }     # → single-product-checkout · tripwire-oto · subscription-checkout
funnel_template_apply { slug: "tripwire-oto", name: "..." }   # → a NEW DRAFT funnel; capture flow_id
# customise node copy with flow_update_node; publish with live_mode=true
```

**Read orders** (read-only — orders are written automatically on a succeeded payment):

```bash
commerce_order_list { status: "succeeded" }   # spideriq commerce orders list
commerce_order_get { order_id }                # spideriq commerce orders get <id>
commerce_order_stats { window: "30d" }         # revenue, orders, success rate, AOV
commerce_order_export_csv { ... }              # spideriq commerce orders export
```

Rules that trip agents up:
- **Edge operators are long-form** — `op: "equal"`, never `"eq"` (no alias; `"eq"` silently never matches).
- **Publish with `live_mode=true`**, not a `status` flip.
- **`total_amount_cents` is minor-units (cents)** — divide by 100; don't mix with Medusa major-unit `unit_price`.
- **Stripe TEST card `4242 4242 4242 4242`** while building. OTO accept charges off-session; decline is a no-op; both route to thank-you.
- **You can author the whole funnel EXCEPT creating the product** — product creation uses the Medusa Admin UI today; the agent-native product surface is coming soon.

**Full recipe:** [shared/recipes/tripwire-oto/](./recipes/tripwire-oto/) + the runnable [examples/build-tripwire-funnel.sh](./examples/build-tripwire-funnel.sh).

### IDAP (CRM Data)
```bash
GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml
GET /api/v1/idap/businesses/resolve?place_id=0x47e66fdad6f1cc73:0x341211b3fccd79e1
```

### Chrome auto-skip (2026-04-24)

When a page has a block that resolves to a component with `category='header'` OR `category='footer'`, the renderer now **automatically suppresses the native `{% section 'header' %}` / `'footer'`** so you don't get double chrome. Replaces three workarounds:

- Polling `nukeUI()` JS that hid native elements on setInterval
- Forcing every page to `template='blank'` and losing the layout wrapper
- Per-page conditional `copyright_text` scripts

**How to opt in:** mark your custom header/footer components with `category: "header"` or `category: "footer"` on create/update. The auto-detect fires on every page render — no settings toggle needed.

**Manual override** via the existing `custom_fields` JSONB on `content_pages` (no migration needed):

```json
{"custom_fields": {"hide_native_chrome": true}}
// granular:
{"custom_fields": {"hide_native_header": true, "hide_native_footer": false}}
```

Reference JSON: [components/page-with-custom-header.json](components/page-with-custom-header.json).

### Empty-string props now suppress defaults (2026-04-24)

Page block `props.image = ""` now correctly overrides a component's `default_props.image = "/placeholder.jpg"`. Before: LiquidJS treated `""` as truthy for `{% if props.image %}` checks, so the placeholder kept rendering. Fix: the renderer's `{% component %}` tag deletes empty-string / null props after the merge, so the Liquid template sees `props.image == nil` (falsy) and correctly falls through. Falsy-but-meaningful values (`0`, `false`) are preserved.

### Preview a single component in isolation (2026-04-24)

Before a full-site deploy, iframe-render one component to check Shadow DOM styling:

```bash
POST /api/v1/dashboard/projects/{pid}/content/components/{component_id}/preview
{ "props": { "headline": "Hello" }, "viewport": "desktop" }
# → { html, css, js, custom_element_tag, merged_props, framework?, bundle_url? }
```

The `html` is the full `<spideriq-cmp data-slug="...">` block with a declarative `<template shadowrootmode="open">` inside — drop it into `<iframe srcdoc="...">` and you have a pixel-accurate preview in ~100–300 ms instead of a 60–90 s site deploy. Full-fidelity preview still ships via `content_deploy_site_preview`.

Runnable example: [examples/preview-component.sh](examples/preview-component.sh).

### Audit internal links before deploy (2026-04-24)

One call validates every `/path` in every page's blocks + all navigation menus against the published-page roster + active redirects:

```bash
GET /api/v1/dashboard/projects/{pid}/content/audit/links
# → { valid_count, broken: [{path, source, reason}], proposed_redirects, known_redirects }
```

`source` strings describe the exact tree position (`page:home/block[2].cta_primary.url`, `navigation:header[3].url`) so you can navigate straight to the fix. `proposed_redirects` offers a 301 when a broken path's suffix matches an existing slug.

Runnable example: [examples/audit-links.sh](examples/audit-links.sh) · Full recipe: [skills/recipes/link-audit/](skills/recipes/link-audit/).

### Tilda / Webflow import — `auto_extract_css` escape hatch (2026-04-24)

By default the server rejects `<style>` blocks inside `html_template` (loud error — Shadow DOM ignores them). For Tilda/Webflow imports whose HTML is saturated with inline styles, pass `auto_extract_css: true` on `component_create` / `component_update` and the server will move every `<style>...</style>` block into the `css` field before validation.

```bash
POST /api/v1/dashboard/projects/{pid}/content/components
{
  "slug": "legacy-section",
  "name": "Ported Section",
  "html_template": "<style>.foo{color:red}</style><section>...",
  "auto_extract_css": true
}
# → server returns the normal ComponentResponse; html_template is clean, css has the rules.
```

Off by default — the explicit-over-magical contract for hand-authored components stays. Runnable example: [examples/tilda-migrate-css.sh](examples/tilda-migrate-css.sh) · Full recipe: [skills/recipes/tilda-migration/](skills/recipes/tilda-migration/).

---

## Folder-driven navigation + folder landing pages (July 2026)

A navigation item can be **bound to a page folder** instead of carrying a hand-typed `url`. The bound item is expanded server-side into the folder's **published, non-folder** descendants in `sort_order` — so the menu tracks the page tree instead of drifting from it, and a draft page can never appear in a public menu.

### Three item modes

Each item in a menu is independently one of three modes; they mix freely in the same menu.

| Mode | Shape | Behaviour |
|---|---|---|
| Hand-authored | `{ "label": "Pricing", "url": "/pricing" }` | The original behaviour, still the default. Unchanged. |
| Folder-bound | `{ "label": "Handbook", "source": { "kind": "folder", "folder_id": "<uuid>", "depth": 2 } }` | Expands to that folder's published pages. |
| Site-bound | `{ "label": "Explore", "source": { "kind": "site", "depth": 2 } }` | Expands from the top-level page tree. |

`depth` is 1–3 and counts levels **below** the bound root. `folder_id` is required when `kind` is `folder`.

### ⚠️ The read returns the BINDING, not its expansion

This is the one part agents get wrong.

- `content_get_navigation` (the authenticated read) returns bound items with `source` set and `children` **empty**. That is correct.
- The public site read is the one that expands. What a visitor sees is generated per request.

If you read the live site, notice the authenticated response looks "empty", and write the expanded pages back as `children` — you have replaced the rule with a snapshot of today's page tree, and the menu **permanently stops tracking pages**. Edit `source`; never write the expansion back.

### Creating and filling a folder

A folder is a page row with `is_folder: true`. It is dashboard-only: it has no URL, never renders on the live site, and cannot be published (publishing one is refused deliberately).

```
content_create_page   { "title": "Handbook", "slug": "handbook", "is_folder": true }
content_update_page   { "page_id": "<child>",  "parent_id": "<folder-id>" }    # move a page in (null moves it out)
content_update_page   { "page_id": "<folder>", "index_page_id": "<child>" }    # pin a landing page (null clears)
content_list_pages    → returns is_folder + parent_id — this is how you discover the folder_id to bind
```

`parent_id` and `index_page_id` are forwarded when **present**, so an explicit `null` is meaningful and is how you detach a page or clear an override.

### The folder's landing page

A bound folder node needs somewhere to point. Resolution is **position-first, override-optional**:

1. `index_page_id` when set, published, and still a direct child of that folder;
2. otherwise the first published child by `sort_order`;
3. otherwise **no `url` at all** — render the node label-only, never `href=""`.

Step 1 is re-checked on every read, which is what makes the override self-healing: delete or unpublish the pinned page and the folder silently falls back to step 2 rather than pointing at nothing.

### `folder.children` — rendering a real index page

When a page **is** its folder's resolved landing page, its response carries a `folder` object and the renderer lifts it to the top of the Liquid scope. Use it to build an index instead of hand-listing links:

```liquid
{% if folder %}
  <h2>{{ folder.title }}</h2>
  {% for child in folder.children %}
    <a href="{{ child.url }}">{{ child.title }} — {{ child.seo_description }}</a>
  {% endfor %}
{% endif %}
```

`folder` is **absent** on ordinary pages — the key's presence is the signal, so guard with `{% if folder %}` and the same template stays safe everywhere. It is also reachable inside a component, because the component scope inherits the page scope.

CLI equivalents: `npx @spideriq/cli content navigation get [location]` and `... navigation set <location> --items <json>|--file <path>`. The output of `get` pipes straight back into `set`.

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

### Site-wide component changes — use the one-shots (v2.88.0+)

When a component is used on multiple pages and you want to update it site-wide, do NOT run `component_update` + N × `content_update_page` calls. Use the one-shot:

```
component_update_and_propagate(slug="hero", css=<new css>, dry_run=true)
# → returns confirm_token + affected_pages list
component_update_and_propagate(slug="hero", css=<new css>, confirm_token="cft_...")
# → bumps component version, repoints every consuming page's block pin, all in one transaction
```

Add `pages: ["home"]` to stage the rollout (other pages keep their old pin). Block-level page content renders live via the content API on next request — NO tenant deploy needed.

If something breaks, undo is also one call:

```
component_rollback(slug="hero", target_version="1.4.0", dry_run=true)
# → preview; then re-run with confirm_token
```

Rollback creates a new forward version with the target version's content (immutable history). Full recipes: [skills/recipes/component-update-and-propagate/](skills/recipes/component-update-and-propagate/) + [skills/recipes/component-rollback/](skills/recipes/component-rollback/).

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

### Scroll-Linked Hero (image sequence) — use `sys-scroll-sequence`

**Do NOT build your own scroll-sequence component.** The global `sys-scroll-sequence` (Tier 3, is_global=true, already published) handles canvas setup, GSAP wiring, and progressive preloading. Feed it frames from a SpiderVideo `extract_frames` job:

```
1. Upload source video → https://media.cdn.spideriq.ai/.../source.mp4
2. Submit spiderVideo extract_frames job with target_frames=120, output_format=webp
3. Poll until completed → grab {base_url, pattern, count} from the manifest
4. Add block to a page:
   { type: "component",
     component_slug: "sys-scroll-sequence",
     props: { base_url, pattern, count,
              scroll_distance_vh: 400,
              preload_strategy: "progressive" } }
5. content_deploy_site_preview → content_deploy_site_production(confirm_token)
```

Runnable script: **[examples/scroll-sequence.sh](examples/scroll-sequence.sh)**
Block config reference: **[components/scroll-sequence.json](components/scroll-sequence.json)**
Full recipe skill (Tier 1/2/3): **[skills/recipes/scroll-sequence/](skills/recipes/scroll-sequence/)**

Anti-patterns that waste 12 hours of agent time:
- Hardcoding 100+ frame URLs → CDN rate-limits → "flashlight strobe" of black frames
- Tunneling local frames through pinggy/serveo into `/media/files/import-url` → tunnels inject HTML interstitials saved as `.webp`
- Rolling your own scroll component with GSAP when `sys-scroll-sequence` already does it

### Upload Many Local Files

One MCP/CLI call handles files or directories — see the **"Upload from your local filesystem"** section above. Scroll-sequence folders auto-optimize to WebP so a 120-frame × 1.6 MB input (192 MB, doomed) becomes ~8 MB that first-paints fast.

Recipe: **[skills/recipes/bulk-media-upload/](skills/recipes/bulk-media-upload/SKILL.md)** · Example: **[examples/bulk-media-upload.sh](examples/bulk-media-upload.sh)**

Do NOT use `/media/files/import-url` with a localhost tunnel — it's the #1 cause of silent-failure deploys (tunnels inject HTML interstitials that land as `.webp`).

### Component Examples
Ready-to-POST examples in `components/`:
- `hero-gradient.json` — Tier 1: gradient hero
- `pricing-cards.json` — Tier 1: 3-tier pricing
- `faq-accordion.json` — Tier 2: interactive FAQ accordion
- `stats-animated.json` — Tier 3: GSAP animated stats counter
- `pricing-toggle.json` — Tier 4: React pricing with monthly/annual toggle
- `scroll-sequence.json` — **reference**: page-block config for the global `sys-scroll-sequence` component (not a create body — feed it from `extract_frames`)
- `auth-login.json` — **reference**: page-block config for the global `spideriq/auth-login` component (Authentication category — see below)

---

### Live data in components — `kind="dynamic"` (Live Data Everywhere)

Components aren't limited to static markup. A **`kind="dynamic"`** component binds live CMS collections — `posts`, `authors`, `categories`, `tags`, `changelog` — and the server fetches + filters them **before render**, exposing the rows to your template as `items`. Build it once, drop it on any page, and it always shows current content. This is how an agent puts real data anywhere: recent posts on the homepage, the team on a contact page, a changelog feed in a footer, a filtered card grid.

**The chain:**
```
1. list_data_sources                     → discover source IDs + each source's filterable/sortable fields
2. list_data_source_items(source_id="posts", filter={tag:"news"}, sort="-published_at", limit=3)
                                          → (optional) preview the exact rows before wiring anything
3. content_create_component(             → a dynamic component MUST set all three: block_type + js_runtime + sources
     slug:"latest-news", name:"Latest News",
     kind:"dynamic", block_type:"list", js_runtime:"none",
     sources:[{ source_id:"posts", default_filter:{tag:"news"},
                default_sort:"-published_at", default_limit:3 }],
     html_template:'{% for item in items %}<a href="/blog/{{ item.slug }}">{{ item.title }}</a>{% endfor %}')
4. page_insert_section(page_id, component_slug:"latest-news")   → renderer fetches the binding, rows arrive as items
5. content_deploy_site_preview → content_deploy_site_production(confirm_token)
```

`items` is your declared, filtered binding. The global `{{ posts }}` / `{{ authors }}` / `{{ categories }}` / `{{ tags }}` / `{{ changelog }}` collections are **also** available in every component and page template (unfiltered) — use those for a quick list, `items` for the component's own binding.

**Pitfalls:**
- `kind="dynamic"` **requires** `block_type` + `js_runtime` + a non-empty `sources[]` together — omit any and the create is rejected (422). Use `js_runtime:"none"` for a pure-Liquid (server-rendered) component.
- **Filters run server-side.** `default_filter` (or the `list_data_source_items` `filter`) narrows the query; a `{% if %}` in your template only hides rows already fetched — it doesn't re-query.
- The landing-page `lead` is a **singleton**, not a list — use it directly on a `/lp/` page, not as a list binding.
- Directory sources (countries / cities / streets / businesses) aren't bindable yet; the blog collections above are live today.

Full recipe: **[skills/recipes/build-a-dynamic-component/](skills/recipes/build-a-dynamic-component/)**

---

### Authentication components (login / signup / forgot-password / reset-password)

The **`authentication`** marketplace category provides designable sign-in bricks — `spideriq/auth-login`, `spideriq/auth-forgot-password`, `spideriq/auth-reset-password` — each rendering ONE `<spideriq-auth>` custom element with a **closed** shadow DOM (the password field is never readable from the host page). The same brick also supports **`mode="signup"`** for self-serve account creation.

Discover them with `content_list_marketplace_components(category="authentication")` (CLI: `spideriq content marketplace:components --category authentication`), then insert one with `page_insert_section`.

**The hinge — `auth_target` (REQUIRED on every auth component):**

| `auth_target` | Signs into |
|---|---|
| `dashboard` | the SpiderIQ dashboard |
| `site_members` | the site's **own** members area |

The two never share a user store or session — ask the user which one before inserting. Verify a placed form by checking the page's `dom.shadow_hosts` include `spideriq-auth` (NEVER assert on `body_text_preview` — the closed shadow root is opaque).

> **Status:** live end to end. `auth_target=dashboard` signs into the SpiderIQ dashboard (one-time code → host-only handoff → first-party session; no shared cross-domain cookies); `auth_target=site_members` signs into the site's own members. A placed brick renders, themes, *and* signs in. Design the page freely and embed the brick where the form goes — don't hand-roll a custom auth form.

**Self-serve signup — `mode="signup"` (`auth_target=dashboard`):**

Embed `<spideriq-auth mode="signup" auth-target="dashboard">` on a `/signup` page and a visitor can create a **brand-new free SpiderIQ account from your own domain** — email + password, then a verification email. The account lands in **its own fresh workspace** (not yours — your domain is just the entry point), on the free tier, with **no charge at signup**.

- **No session is minted at signup.** On submit the brick shows a neutral *"Check your email…"* state and does **not** navigate or set a cookie — don't expect a redirect. The dashboard session exists only after the visitor clicks the verification link (`→ /login?verified=1`) and logs in.
- Set `login-link="/login"` for the "Already have an account? Sign in" affordance; on the login brick, set `signup-link="/signup"` to turn the "Create one" link real.
- Duplicate email returns the same neutral response — no enumeration, no second account.

Full flow: [recipes/build-a-login-page/](../recipes/build-a-login-page/) • [examples/build-login-page.sh](../examples/build-login-page.sh) • [examples/build-signup-page.sh](../examples/build-signup-page.sh) • [components/auth-login.json](../components/auth-login.json).

### Site Members — gate pages behind a member login wall

A site can put its **own** pages behind a login wall for its **own** members (the Softr-Users model). Every page has an **access level**:

| `access` | Who sees the page |
|---|---|
| `public` (default) | everyone — no gating, no overhead |
| `logged_in` | any signed-in member of **this** site |
| `group-restricted` | only members whose group is in the page's `allowed_groups` |

Set it with `page_set_access(page_id, access, allowed_groups)`. The level is enforced at the **Cloudflare edge** and only takes effect after you **publish the page and deploy the site**. New pages are `public` by default, so adding members never changes a page you didn't explicitly gate.

A members-gated site needs a **login page on the same site** built with the Authentication brick `auth_target="site_members"`. The member session cookie is **host-only** — it lives on the site's own domain — so the login form must be **same-host** as the gated pages (leave `members_base` unset and the renderer wires it to the page's own origin).

> **Member administration** — invitations, groups, SSO providers (Google / GitHub / OIDC), and record-level Data Restrictions — is done in the dashboard **Content → Users** area. The per-member management API is session-scoped today (not the public PAT surface); agents set page access via `page_set_access` and hand member admin to the site owner. Agent member-management tooling is on the roadmap.

Members are isolated per site: a member of one site cannot access another.

Full flow: [recipes/members-gated-page/](../recipes/members-gated-page/) • [examples/members-gated-page.sh](../examples/members-gated-page.sh).

---

### Rate Limits
- API: 100 requests/minute
- Jobs: 10 submissions/minute
- Always use `?format=yaml` (saves 40-76% tokens)

## Marketplace V2 — find sections by intent (May 2026)

**The shipped pivot.** The classic `content_list_marketplace_components` filters by `category` (hero, features, pricing, …). Six new tools turn the same catalog into something you search by **what an agent actually wants** — "calm cinematic for a luxury hotel," "energetic conversion-focused for ecommerce" — across all 3 marketplace tables (bg-videos / components / site-templates) in one query.

```
marketplace_search(
  mood = ["calm"],
  asset_types = ["bg_video"],
  limit = 5
)
# → results: [{slug, asset_type, mood, scene_type, video_url|preview_thumbnail_url, ...}]
```

| Tool | Auth | Use case |
|---|---|---|
| `marketplace_search` | public | Cross-table search by mood / palette / brand_fit_tags / scene_type / agent_meta / asset_types |
| `list_data_sources` | public | Discover available source IDs for binding `kind="dynamic"` blocks (posts, authors, categories, tags, changelog; IDAP×4 + idap.lead are Phase 2) |
| `list_data_source_items` | public | Fetch filtered/sorted/paginated rows from one source (the same door a dynamic component binds to) — preview rows before wiring a component. Server-side filters. |
| `marketplace_suggest_agent_meta` | super_admin | **NEW (1.7.0)** Suggest mood/palette/brand_fit/scene_type/agent_meta for one asset via the SpiderGate inference engine. Pure read — no DB write. Then review + apply via `set_*_agent_meta`. |
| `set_component_kind` | gated | Promote a custom component into the 4-class taxonomy (`static / interactive / dynamic / extension`) |
| `set_component_agent_meta` | gated | Curate axes + ComponentAgentMeta on a component so other agents can find it |
| `set_bg_video_agent_meta` | super_admin, gated | Curate bg-video discoverability (pace, time_of_day, weather, aspect_ratio, …) |
| `set_site_template_agent_meta` | super_admin, gated | Curate site-template discoverability (page_count, has_blog, style_aesthetic, …) |

**Two-step suggest → apply flow (NEW in 1.7.0):**

```
1. marketplace_suggest_agent_meta(asset_type="bg_video", slug="alpine-wildflowers")
   → SuggestEnvelope: { proposed_universal_axes, proposed_agent_meta,
                         confidence_per_key (action: auto_apply | review | drop),
                         dropped_keys (off-vocab), reasoning, usage }

2. Review the envelope — for values you trust:
   set_bg_video_agent_meta(slug="alpine-wildflowers",
                            mood=["calm","dreamy"], scene_type="nature-landscape",
                            agent_meta={pace: "slow", time_of_day: "day", ...})
   → gated: dry_run=true default; second call with confirm_token to apply
```

The engine validates against locked Pydantic enums BEFORE returning — off-vocab values are dropped (not stored). Confidence thresholds: ≥0.75 = auto_apply, ≥0.55 = review, else drop. Apply tools mark the row `agent_meta_source='llm_inferred'` so future bulk re-runs distinguish machine suggestions from human curation.

**CLI mirrors:** `npx @spideriq/cli marketplace search`, `... marketplace help`, `... marketplace suggest <type> <slug>`, `... sources list`, `... bg-videos set-meta`, `... content components set-kind`, `... content components set-meta`.

**Vocabulary (subset):**

| Axis | Values |
|---|---|
| `mood` | calm, energetic, bold, confident, dreamy, futuristic, urban, minimal, warm, sensory, editorial, professional, friendly, clear, technical, credible |
| `brand_fit_tags` | saas, agency, ecommerce, fintech, hospitality, restaurant, wellness, healthcare, blog, publication, real-estate, … |
| `scene_type` | hero-bold, conversion-cta, social-proof (components); city-aerial, nature-landscape (bg-videos); marketing-site, docs-site (site-templates) |

Full vocab + per-asset `agent_meta` keys (BgVideoAgentMeta / ComponentAgentMeta / SiteTemplateAgentMeta): [skills/content-platform/schema.yaml](skills/content-platform/schema.yaml) under `marketplace_v2_axes:`. Or call `template_get_help` (returns the canonical YAML reference).

**Recipes:**
- [skills/recipes/marketplace-search-and-insert/](skills/recipes/marketplace-search-and-insert/) — Find a marketplace asset by intent, insert it into a page (May 2026)
- [skills/recipes/marketplace-suggest-agent-meta/](skills/recipes/marketplace-suggest-agent-meta/) — **NEW (1.7.0)** Suggest metadata for a newly uploaded asset, then apply via `set_*_agent_meta`

## AI Agent components (June 2026)

The marketplace has an **AI Agents** category: brandable listings that mount a live AI agent onto a
page in one of four **form-factors**. Browse them under **Marketplace → AI Agents** in the
dashboard, or over the public content API at
`GET /content/marketplace/components?category=agent`.

| `form_factor` | How it mounts | Use for |
|---|---|---|
| `section` | A full page section | a "talk to sales" band |
| `widget` | An inline in-flow block | an agent inside a card |
| `concierge` | A floating launcher + slide-out panel | a site-wide support bubble |
| `headless` | Transport + state only — you build the UI | a fully custom chat experience |

**Author one with `content_create_agent_component`** (in `@spideriq/mcp-publish`). Give it a slug,
a name, and a form-factor; it bakes the whole component — markup + your brand skin — so it mounts
consistently the first time:

```
content_create_agent_component({
  slug: "acme-sdr-widget",
  name: "Acme SDR",
  form_factor: "widget",          // section | widget | concierge | headless
  role: "sdr",                    // optional
  skin: { primary: "#5b2be7" }     // baked INLINE into the listing's template
})
```

Four ready-to-use starter agents ship seeded — clone one as a starting point, or author your own.
The live **conversation** activates when you hire an agent from a partner agent platform and bind
it to your site; browsing, authoring, and mounting the surface is available now.

**Filter by form-factor — the parameter differs by surface.** On the **public** content API use
the dotted JSONB path `?agent_meta.form_factor=widget`; in the **dashboard** API use the scalar
`?agent_form_factor=widget`. The wrong one for an endpoint is silently ignored (you get all agents
back). The `content_list_marketplace_components` tool's `agent_form_factor` argument maps to the
public dotted form for you.

## Skills — Curated Recipes

Multi-step workflows that compose MCP tools. Live at **[skills/](skills/)** in this starter kit.

**Core building blocks** (exposed via `@spideriq/mcp-publish` — these SKILL.md files are the human/agent reference):
- [content-platform](skills/content-platform/) — Pages, posts (with authors/tags/categories), docs, nav, settings, components, **directory pages**, component site-wide propagation, section overrides
- [booking](skills/booking/) — **Appointments / bookings** powered by cal.com. Flow authoring, services, bookings, template library. Ships a `/book/{flow_id}` route + `{% booking %}` Liquid tag (in `@spideriq/mcp@1.0.0` kitchen-sink)
- [templates-engine](skills/templates-engine/) — Liquid templates, themes, deploy to edge
- [upload-host-media](skills/upload-host-media/) — Media upload to CDN (including local-filesystem `upload_local_file` / `_directory`)
- [agentdocs](skills/agentdocs/) — Versioned docs projects

**Recipes** (Tier 1 YAML doc + Tier 2 MCP-call schema + Tier 3 TypeScript impl that runs anywhere):
- [recipes/scroll-sequence](skills/recipes/scroll-sequence/) — Video → frames → `sys-scroll-sequence` → deploy
- [recipes/preview-iteration](skills/recipes/preview-iteration/) — Edit → preview → browser-check → confirm_token → production
- [recipes/bulk-media-upload](skills/recipes/bulk-media-upload/) — Local directory → R2 (no tunnels needed)
- [recipes/directory](skills/recipes/directory/) — Category → bulk-upsert listings (or IDAP import) → deploy → programmatic SEO pages live
- [recipes/component-update-and-propagate](skills/recipes/component-update-and-propagate/) — Safe site-wide component change in one call
- [recipes/component-rollback](skills/recipes/component-rollback/) — Unroll a bad component change
- [recipes/link-audit](skills/recipes/link-audit/) — Find broken internal links across pages + nav before deploy (2026-04-24)
- [recipes/tilda-migration](skills/recipes/tilda-migration/) — Port a Tilda site with `auto_extract_css` + flat slugs + `category='header'|'footer'` components (2026-04-24)
- [recipes/marketplace-search-and-insert](skills/recipes/marketplace-search-and-insert/) — Find a marketplace asset by intent (mood/palette/brand-fit/scene), insert it into a page (2026-05-05)
- [recipes/marketplace-suggest-agent-meta](skills/recipes/marketplace-suggest-agent-meta/) — Suggest metadata for a freshly uploaded asset via the SpiderGate inference engine, then apply via the gated `set_*_agent_meta` tools (2026-05-06)
- [recipes/build-a-dynamic-component](skills/recipes/build-a-dynamic-component/) — Discover a data source → preview rows → create a `kind="dynamic"` component → place → deploy. Live, server-filtered collections in any component (2026-06-09)

Tier 3 `impl.ts` files use only Node 18+ stdlib (`fetch`, `fs`, `path`) — zero npm dependencies. Copy-paste them into your agent's sandbox and run with `npx tsx impl.ts`. No extra runtime required.

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

---

## Skills bundled with this kit

### Recipes (multi-step workflows)

- [Build a Scroll-Linked Hero from a Video](.claude/skills/recipes/scroll-sequence/SKILL.md) — Build a cinematic scroll-scrubbed hero from a video file using ffmpeg frame extraction and the sys-scroll-sequence component.
- [Search the SpiderIQ Component Marketplace](.claude/skills/recipes/marketplace-search-and-insert/SKILL.md) — Search the curated SpiderIQ component marketplace by kind / mood / palette / brand_fit_tags / scene_type, then insert a result into a page.
- [Suggest agent_meta for Marketplace Assets (LLM-Inferred)](.claude/skills/recipes/marketplace-suggest-agent-meta/SKILL.md) — Use the SpiderGate-powered marketplace_suggest_agent_meta tool to infer mood / palette / brand_fit_tags / scene_type / agent_meta for a marketplace asset (component, bg-video, site template).
- [Update a Shared Component and Propagate Across All Pages](.claude/skills/recipes/component-update-and-propagate/SKILL.md) — Update a shared component AND repoint every consuming page's block pin in one MCP call + one confirm_token (v2.
- [Roll Back a Shared Component to an Earlier Version](.claude/skills/recipes/component-rollback/SKILL.md) — Restore a component to an earlier version's content.
- [Safe Edit Loop with Preview → Confirm](.claude/skills/recipes/preview-iteration/SKILL.md) — Iterate on a page or template safely: template_preview (no state mutation) → browser-check → publish (dry_run → confirm_token).
- [Upload a Local Directory of Files via Multipart POST](.claude/skills/recipes/bulk-media-upload/SKILL.md) — Upload a local directory of files directly via multipart POST.
- [Build a Programmatic Directory (Category / City / Listing)](.claude/skills/recipes/directory/SKILL.md) — Build /directory/{category}/{city}/{listing} pages programmatically: create category → bulk-upsert listings (or import from IDAP) → deploy.
- [Audit Internal Links Before Deploy](.claude/skills/recipes/link-audit/SKILL.md) — Scan the tenant's published surface for broken internal links (404s, redirects, mistyped slugs) before deploy.
- [Migrate a Tilda / Webflow / Lovable Site to SpiderPublish](.claude/skills/recipes/tilda-migration/SKILL.md) — End-to-end migration from a Tilda export (or Webflow / Lovable export): section → component → page → publish, with auto_extract_css for one-file imports.
- [Build a Multi-Step Lead-Gen Form (end-to-end)](.claude/skills/recipes/build-lead-gen-form/SKILL.md) — Author a multi-step lead-capture Form with the form_* MCP surface: create with initial fields + theme → add follow-up fields + hidden UTM captures → client-side validate → 2-phase publish → fetch the copy-paste embed snippet for any third-party page.
- [Design a Form — Presets, Token Overrides, Per-Question Media](.claude/skills/recipes/design-a-form/SKILL.md) — Give a Form a visual identity.
- [Fill the CRM from a Form — IDAP Field Types + crm_target](.claude/skills/recipes/idap-fill-from-form/SKILL.md) — Make a Form populate the tenant CRM on submit.
- [Build a Login Page — Authentication Components + auth_target](.claude/skills/recipes/build-a-login-page/SKILL.md) — Add a sign-in / forgot-password / reset-password page using the designable Authentication components (spideriq/auth-login, auth-forgot-password, auth-reset-password).
- [Build a Dynamic Component — Live, Server-Filtered Collections](.claude/skills/recipes/build-a-dynamic-component/SKILL.md) — Build a kind='dynamic' component that binds a live CMS collection (posts / authors / categories / tags / changelog) with server-side filtering, then place it on a page and deploy.
- [Members-Gated Page — Site Members + per-page access](.claude/skills/recipes/members-gated-page/SKILL.md) — Put a page behind a members login wall (Site Members — the site's OWN members, not the SpiderIQ dashboard).
- [Tripwire + OTO Commerce Funnel](.claude/skills/recipes/tripwire-oto/SKILL.md) — Build a commerce funnel that sells a product — a tripwire checkout, a one-time-offer (OTO) upsell, then thank-you — taking real Stripe payments and landing a canonical order.

### Core MCP-namespace skills

- [SpiderPublish Content Platform — Full MCP Surface](.claude/skills/core/content-platform/SKILL.md) — Full content_* / directory_* / playbook_* MCP namespace overview: pages, posts, docs, navigation, settings, components, domains, directory pages, component site-wide propagation, section overrides.
- [SpiderBook — Appointment-Booking MCP Surface](.claude/skills/core/booking/SKILL.md) — Full booking_* MCP namespace: cal.
- [SpiderFlow — Multi-Step Form Authoring MCP Surface](.claude/skills/core/forms/SKILL.md) — Full form_* MCP namespace (20 tools): Typeform-class multi-step forms, lead capture, NPS / CSAT surveys, intake forms.
- [Liquid Templates + Themes + Edge Deploy](.claude/skills/core/templates-engine/SKILL.md) — template_* / content_deploy_site_* MCP surface for Liquid templates, themes, and Cloudflare edge deploy.
- [SpiderMedia — Image / File / Video Upload](.claude/skills/core/upload-host-media/SKILL.md) — media_* MCP namespace: upload images, files, videos to the SpiderMedia CDN.
- [AgentDocs — Versioned Documentation Projects](.claude/skills/core/agentdocs/SKILL.md) — agentdocs_* MCP namespace: build versioned documentation projects (Mintlify-style) with sidebar config, MDX pages, full-text search, and edge deploy.

### Guides (onboarding + decision aids)

- [Create a SpiderIQ Tenant Page](.claude/skills/guides/create-page/SKILL.md) — Create a new published page on a SpiderIQ tenant via the @spideriq/mcp-publish MCP server.
- [Build a SpiderIQ Personalized Landing Page](.claude/skills/guides/personalized-landing/SKILL.md) — Build a personalized landing page via /lp/{slug}/{place_id} with merge tags fed by IDAP.
- [Pick the Right @spideriq/mcp-* Package](.claude/skills/guides/pick-mcp-package/SKILL.md) — Decide which @spideriq/mcp-* npm package to install.
- [@spideriq/cli Quick Reference](.claude/skills/guides/cli-quick-reference/SKILL.md) — Run SpiderIQ from the terminal via @spideriq/cli — auth flow, project binding, pages CRUD, marketplace search, deploy, output formats.
- [Install + Set Up the SpiderPublish IDE Extension](.claude/skills/guides/ide-extension-setup/SKILL.md) — Install + bind the SpiderPublish IDE extension (SpiderIQ.
