# content-platform

Multi-tenant content management: pages, blog posts, docs, navigation, site settings, custom domains, and reusable UI components with 4-tier Shadow-DOM isolation.

**Exposed via:** `@spideriq/mcp-publish@1.0.0` (105 tools). This skill is the agent-readable reference — see `schema.yaml` for the tool list, the full JSON Schema lives in the MCP.

## When to use

- Building or editing a website (pages, posts, docs)
- Managing navigation menus and site settings
- Creating reusable UI components (static HTML, scoped JS, CDN-driven, framework builds)
- Managing custom domains for a tenant site
- Building programmatic directory pages (`/directory/{category}/{city}/{listing}`)
- Rolling a component change out across every page that references it in one call

## When NOT to use

- Uploading media files → use [upload-host-media](../upload-host-media/)
- Customizing Liquid templates / themes → use [templates-engine](../templates-engine/)
- Versioned documentation projects → use [agentdocs](../agentdocs/)
- Booking / appointments / service-slot pickers → use [booking](../booking/)

## Common tool chains

| Goal | Chain |
|---|---|
| Create + publish a page | `content_create_page` → `content_publish_page` (dry_run → confirm_token) |
| Create a blog post with taxonomy | `content_create_author` → `content_create_category` → `content_create_tag` → `content_create_post` → `content_publish_post` |
| Custom component (Tier 1) | `content_create_component` → `content_publish_component` (dry_run → confirm) → reference from page block |
| Custom component (Tier 3 with CDN deps) | `content_list_cdn_allowlist` → `content_create_component(dependencies=[...])` → `content_publish_component` |
| Framework component (Tier 4) | `content_create_component(framework="react", source_code="...")` → `content_publish_component` → poll `get_build_status` until success |
| Custom domain | `content_add_domain` → `content_verify_domain` → `content_set_primary_domain` → deploy |
| Change a shared component everywhere | `component_update_and_propagate(slug, html_template=..., bump="patch", dry_run=true)` → confirm_token → same call with `confirm_token` → deploy |
| Unroll a bad component change | `component_rollback(slug, version=<previous>)` → deploy |
| Override a single section for one tenant | `content_get_section_source("footer")` → `content_override_section("footer", liquid_source=...)` |
| Strip the theme chrome on a landing page | `content_apply_layout_preset("blank")` or `"minimal"` |
| Scroll-linked image-sequence hero | `video_to_scroll_sequence(page_slug, video_url=...)` (one call — extracts frames, uploads, inserts block) |
| Programmatic directory pages | `directory_create_category` → `directory_bulk_upsert_listings` (or `directory_import_from_idap`) → deploy |
| Upload local files without a public URL | `upload_local_file(path)` or `upload_local_directory(dir)` — the MCP reads the filesystem directly |
| "What tool do I reach for?" | `content_get_playbook(intent)` — returns the canonical tool-call sequence for 30+ common intents |
| Confirm which project my PAT is bound to | `get_whoami()` — returns `{client_id, project_name, email, scopes, token_expires_at, ...}` |
| Find broken internal links before deploy | `content_audit_links()` — returns `broken[{path, source, reason}]` + `proposed_redirects` |
| Preview a single component without deploying | `component_preview(component_id, props, viewport?)` — returns Shadow-DOM-wrapped HTML ready for `<iframe srcdoc>` |
| Port a Tilda/Webflow HTML section with inline `<style>` blocks | `content_create_component(..., auto_extract_css=true)` — server moves `<style>` into `css` field automatically |
| Page with a custom header component (avoid double-chrome) | Mark the component with `category="header"` — renderer auto-suppresses the native section |

## Apr 2026 additions (v2.1.0)

| Tool | Purpose |
|---|---|
| `get_whoami` | Returns current PAT's resolved identity (`client_id`, `project_name`, scopes, expiry). Run before any destructive op to confirm you're in the right tenant. |
| `content_audit_links` | Walks every published page's blocks + all nav menus. Flags `/path` references that don't resolve to a published page/post or an active redirect. Returns exact tree-position sources (`page:home/block[2].cta_primary.url`) for targeted fixes. |
| `component_preview` | `POST /dashboard/projects/{pid}/content/components/{id}/preview` with `{props, viewport?}` returns Shadow-DOM-wrapped `html` + `css` + `js` + `merged_props` for iframe-srcdoc rendering. ~100–300ms vs 60–90s full-site deploy. |
| `auto_extract_css` (flag on `content_create_component` / `content_update_component`) | Moves every inline `<style>...</style>` block from `html_template` into `css` before the loud-error validator fires. Off by default — opt-in for bulk Tilda/Webflow ports. |
| Chrome auto-skip (behavior change) | Components tagged `category="header"` or `"footer"` auto-suppress the matching native `{% section %}`. No more double-chrome workarounds. |
| Empty-string prop override (behavior change) | `{% component %}` tag now drops empty-string/null values after the `default_props ← blockProps` merge, so `props.image=""` correctly suppresses a default placeholder. |

Additional 401 error codes for PATs: `token_expired` (distinguishable from generic `token_invalid`), with `expires_at` + regen URL in the response body. See [LEARNINGS.md](../../LEARNINGS.md) "Apr 2026 Triage" section.

## Blog authoring workflow

Blog posts share the same underlying `content_*` tool surface as pages — the difference is the vocabulary (authors, tags, categories, featured, related) and that post bodies are Tiptap JSON, not block arrays.

### First-time setup

```
content_create_author(name, slug, role, bio, avatar_url)
content_create_category(name, slug, parent_slug?)
content_create_tag(name, slug)
content_create_post(author_id, category_id, tag_ids, title, slug, body, ...)
content_publish_post(post_id)     # dry_run → confirm_token
```

### Featured posts for the homepage

```
content_list_featured_posts(limit=3)                      # read current state
content_set_post_status(post_id, status="featured")       # mark a post featured
```

### Related posts

```
content_set_post_related(post_id, related_ids=[id1, id2, id3])
```

### Full-text search

```
content_search_posts(query, limit?)
```

### Blog-specific rules

1. Post `body` is Tiptap JSON — not HTML, not Markdown. The Liquid renderer converts at request time via the `tiptap_html` filter.
2. `view_count` auto-increments on public reads (`GET /content/posts/{slug}`). Use it for "trending" queries.
3. Authors are soft-deleted (`deleted_at` column). List tools filter them out by default; pass `include_deleted=true` to see them.
4. Tags and categories are **separate vocabularies** — tags are flat, categories are hierarchical (nested via `parent_id`).

## Directory pages

Directory pages are SEO-friendly category → city → listing hierarchies served at `/directory`, `/directory/{category}`, `/directory/{category}/{city}`, `/directory/{category}/{city}/{listing}`. The Liquid renderer ships `directory-category.liquid`, `directory-city.liquid`, and `directory-listing.liquid` by default — you do not need to write templates.

```
directory_create_category(name, slug, description)
directory_bulk_upsert_listings(category_slug, listings=[{name, city, state, ...}])
# OR pull from an IDAP bundle:
directory_import_from_idap(category_slug, idap_bundle_id)
content_deploy_site(dry_run=true) → confirm_token → confirm
```

Listings are automatically added to `/sitemap.xml` on publish. Override the three default templates via `content_override_section("templates/directory-listing", ...)` if you want a custom layout.

## Component propagation

`component_update_and_propagate` collapses the old "update component → loop through pages → patch every block → save drafts → publish component → re-save pages" workflow into a single call. It auto-bumps the component version, walks every page whose blocks reference that component slug, updates each page's block version, and returns `affected_pages` + a `confirm_token`.

```
# 1. Preview the blast radius
component_update_and_propagate(
  slug="hero", css="...new rules...", bump="patch",
  dry_run=true
)
# → returns affected_pages=[...], confirm_token="cft_..."

# 2. Commit
component_update_and_propagate(
  slug="hero", css="...new rules...", bump="patch",
  confirm_token="cft_..."
)

# 3. If something breaks
component_rollback(slug="hero", version="1.4.2")
```

Pair this with `preview-iteration` (see `skills/recipes/preview-iteration/`) for the safe edit loop.

## Key rules

1. Every destructive tool (`publish_*`, `delete_*`, `update_settings`, `component_update_and_propagate`, `component_rollback`, `directory_delete_*`) defaults to `dry_run=true`. The first call returns a `confirm_token`; call again with that token to mutate.
2. Component slugs must be unique per version. Bumping the version creates a new row; same slug+version returns 400.
3. Page block references to components are by `component_slug` — not by component id. Slugs resolve at render time.
4. Components live in a per-client registry (scoped by `client_id`) plus a global registry (`is_global=true`). Global components like `sys-scroll-sequence` don't need to be created per client.
5. Every dashboard call flows through a project-scoped URL (`/dashboard/projects/{project_id}/...`) — bind your working directory with `spideriq use <project>` once, and the core SDK handles the rewrite automatically.

## See also

- [templates-engine](../templates-engine/) — Liquid templates and themes that render these pages/posts
- [upload-host-media](../upload-host-media/) — upload images, videos, PDFs to SpiderMedia
- [booking](../booking/) — appointment / service-slot bookings powered by cal.com
- [recipes/scroll-sequence](../recipes/scroll-sequence/) — uses content-platform + SpiderVideo to ship a scroll-sequence hero
- [recipes/directory](../recipes/directory/) — programmatic directory pages end-to-end
- [recipes/component-update-and-propagate](../recipes/component-update-and-propagate/) — safe site-wide component change
- [recipes/component-rollback](../recipes/component-rollback/) — unroll a bad component change
- [recipes/preview-iteration](../recipes/preview-iteration/) — safe edit loop for components
