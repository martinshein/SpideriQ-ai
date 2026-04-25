# recipes/apply-template

Bootstrap a brand-new tenant from a SpiderIQ-curated starter site — pages, navigation, and a whitelisted slice of settings — in a single safe two-step call.

The gallery is a list of opinionated reference sites (saas-landing, agency-portfolio, restaurant, ...) authored by SpiderIQ on a shared "template-source" tenant. Applying one **clones** the published pages into your tenant as drafts, copies the header / footer navigation, and writes a curated set of theme settings keys. You review the drafts, publish what you like, and deploy.

## The 6-stage flow

```
content_list_site_templates       (browse the gallery)
            │
            ▼
content_get_site_template         (inspect one template's pages + tags + screenshot)
            │
            ▼
content_apply_site_template       (dry_run=true → preview + confirm_token)
            │
            ▼
review preview envelope           (pages_to_create, nav_locations, settings_keys)
            │
            ▼
content_apply_site_template       (confirm_token → actually clone)
            │
            ▼
review the new draft pages → content_publish_page each → content_deploy_site_*
```

## Step-by-step

### 1. List the gallery

```
content_list_site_templates({ industry: "saas", is_featured: true })
# → { templates: [{ slug, name, description, industry, use_case, tags,
#                   page_count, applied_count, screenshot_url }, ...],
#     total: 12 }
```

Filters available: `industry`, `use_case`, `tag`, `is_featured`, `limit`, `offset`. All optional — call with no args for the full gallery.

### 2. Inspect one

```
content_get_site_template({ slug: "saas-landing-default" })
# → { slug, name, description, industry, use_case, tags, page_count,
#     screenshot_url, source_pages: [{slug, title}], source_settings_keys: [...] }
```

`source_pages` is the list of pages that will be cloned. `source_settings_keys` is the curated subset of theme settings that will be copied (always a subset of the same allowlist that `content_update_settings` uses — agents cannot smuggle keys in).

### 3. Preview the apply (dry_run)

```
content_apply_site_template({ slug: "saas-landing-default", dry_run: true })
# → {
#     dry_run: true,
#     preview: {
#       pages_to_create: [{ slug, title }, ...],
#       nav_locations:    ["header", "footer"],
#       settings_keys_to_apply: ["site_name", "primary_color", ...],
#     },
#     confirm_token: "cft_…",
#     expires_at: "…",
#   }
```

No DB writes happen. Read the preview carefully — once `confirm_token` is consumed, every page is created and settings overwritten.

### 4. Confirm

```
content_apply_site_template({ slug: "saas-landing-default", confirm_token: "cft_…" })
# → {
#     pages_created: [{ id, slug, title, status: "draft" }, ...],
#     nav_updated:   ["header", "footer"],
#     settings_applied: ["site_name", "primary_color", "surface_color", ...],
#   }
```

Cloned pages land as **`status='draft'`** — they don't appear on the live site until you publish each one. Existing pages are NOT touched (a slug collision would 409).

### 5. Review the drafts

In the dashboard's pages list (or via `content_list_pages`), you'll see the new drafts. Edit copy, swap images, tweak block props — the template is a starting point, not a contract.

### 6. Publish + deploy

```
content_publish_page({ page_id: "<id-from-step-4>", dry_run: true })   → confirm_token
content_publish_page({ page_id: "<id>", confirm_token: "cft_…" })

# repeat for each page you want live, then:
content_deploy_site_preview()                       → preview_url + confirm_token
content_deploy_site_production({ confirm_token })   → live in 2-5s
```

## What gets cloned (and what doesn't)

| Source artifact | What lands in your tenant |
|---|---|
| Published pages on the template tenant | `status='draft'` rows in your tenant. Fresh UUIDs on every block. Same slug. Title preserved verbatim — the template is the canonical version, not a copy with " (Copy)" appended. |
| Navigation menus (header / footer) | Copied byte-for-byte to your tenant's `content_navigation` rows for the same locations. Existing menus at those locations are overwritten. |
| Whitelisted settings keys | Written into your `content_settings` row. Keys outside the allowlist are silently skipped (logged server-side). |
| Components referenced by the cloned pages | Resolved at render time via the global component registry — the source tenant publishes them with `is_global=true` so your pages render correctly without per-tenant component copies. |
| Media (images, video frames, hosted assets) | Referenced by URL only. If the template uses `media.cdn.spideriq.ai/...` URLs, those keep working in your tenant. If you want tenant-local copies, re-upload via `upload_local_file` after applying. |

## What NOT to do

- **Don't apply a second template on top of the first** without reviewing nav / settings overlap — the second apply will overwrite both.
- **Don't reuse a `confirm_token`.** They're single-use. Issue a fresh one with `dry_run=true` if the first one expired or was consumed.
- **Don't expect cloned pages to be live.** They're drafts. Publishing each page is a separate gated step.
- **Don't edit the template tenant.** It's read-only from your side — changes to `source_settings_keys` or page bodies happen via SpiderIQ-side curation, not via your dashboard.

## Common variants

### Browse only featured templates

```
content_list_site_templates({ is_featured: true })
```

### Find templates by industry + use_case

```
content_list_site_templates({ industry: "ecommerce", use_case: "marketing-site" })
```

### CLI

```bash
spideriq content templates:gallery --industry saas --featured
spideriq content templates:get saas-landing-default
spideriq content templates:apply saas-landing-default                       # interactive (dry_run → table → [y/N])
spideriq content templates:apply saas-landing-default --confirm-token cft_  # non-interactive
spideriq content templates:apply saas-landing-default --yes                 # auto-confirm (CI-friendly)
```

### REST

```bash
GET  /api/v1/content/site-templates?industry=saas&is_featured=true
GET  /api/v1/content/site-templates/saas-landing-default
POST /api/v1/dashboard/projects/{pid}/content/templates/apply-site-template/saas-landing-default?dry_run=true
POST /api/v1/dashboard/projects/{pid}/content/templates/apply-site-template/saas-landing-default?confirm_token=cft_...
```

## Files in this skill

- `SKILL.md` — this file
- `schema.yaml` — Tier 2 tool-sequence for MCP consumers

## See also

- [AGENTS.md → Site templates](../../../AGENTS.md)
- [examples/apply-template.sh](../../../examples/apply-template.sh) — runnable end-to-end script
- [recipes/preview-iteration](../preview-iteration/SKILL.md) — the safe-edit loop you'll use after applying
- [SpiderIQ `/content/help` → `apply_site_template`](https://spideriq.ai/api/v1/content/help?format=yaml)
