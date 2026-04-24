# SpiderPublish — AI Agent Context

This project uses SpiderPublish (SpiderIQ's content platform) to build, manage, and deploy websites.

**Current package versions (1.0.0, 2026-04-18):** `@spideriq/cli@1.0.0`, `@spideriq/mcp-publish@1.0.0`, `@spideriq/core@1.0.0` — **105 tools** (atomic SpiderPublish slice: pages, posts, docs, templates, components, domains, media, directory, playbook, scroll-sequence + section-override + component-propagation + local-upload one-shots). The `.mcp.json` in this starter kit pins `@spideriq/mcp-publish` instead of the kitchen-sink `@spideriq/mcp@1.0.0` (which also includes SpiderBook booking tools) — some IDE/LLM stacks silently drop tool injections above ~128 tools, and every tool schema re-injects into LLM context on every turn. If you need mail / leads / gate / admin / booking tools too, add a second MCP server entry for `@spideriq/mcp-mail` / `-leads` / `-gate` / `-admin`, or fall back to `@spideriq/mcp` for the whole surface.

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
4. **Pages:** `POST /dashboard/projects/{pid}/content/pages` — create with blocks (slug `home` for homepage; `template` picks the layout — see Page Templates below) (not gated)
5. **Publish:** `POST /dashboard/projects/{pid}/content/pages/{id}/publish` — REQUIRED: at least 1 published page. Gated.
6. **Theme:** `POST /dashboard/projects/{pid}/templates/apply-theme` — REQUIRED: apply `default`. Gated.
7. **Check readiness:** `content_deploy_readiness` MCP tool — verify all blocking checks pass.
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

## GitHub

- Public repo: https://github.com/martinshein/SpideriQ-ai/tree/main/SpiderPublish
