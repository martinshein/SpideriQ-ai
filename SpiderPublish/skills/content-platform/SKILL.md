# content-platform

Multi-tenant content management: pages, blog posts, docs, navigation, site settings, custom domains, and reusable UI components with 4-tier Shadow-DOM isolation.

**Exposed via:** `@spideriq/mcp-publish` (87 tools). This skill is the agent-readable reference — see `schema.yaml` for the tool list, the full JSON Schema lives in the MCP.

## When to use

- Building or editing a website (pages, posts, docs)
- Managing navigation menus and site settings
- Creating reusable UI components (static HTML, scoped JS, CDN-driven, framework builds)
- Managing custom domains for a tenant site

## When NOT to use

- Uploading media files → use [upload-host-media](../upload-host-media/)
- Customizing Liquid templates / themes → use [templates-engine](../templates-engine/)
- Versioned documentation projects → use [agentdocs](../agentdocs/)

## Common tool chains

| Goal | Chain |
|---|---|
| Create + publish a page | `content_create_page` → `content_publish_page` (dry_run → confirm_token) |
| Create a blog post with taxonomy | `content_create_author` → `content_create_category` → `content_create_tag` → `content_create_post` → `content_publish_post` |
| Custom component (Tier 1) | `content_create_component` → `content_publish_component` (dry_run → confirm) → reference from page block |
| Custom component (Tier 3 with CDN deps) | `content_list_cdn_allowlist` → `content_create_component(dependencies=[...])` → `content_publish_component` |
| Framework component (Tier 4) | `content_create_component(framework="react", source_code="...")` → `content_publish_component` → poll `get_build_status` until success |
| Custom domain | `content_add_domain` → `content_verify_domain` → `content_set_primary_domain` → deploy |

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

## Key rules

1. Every destructive tool (`publish_*`, `delete_*`, `update_settings`) defaults to `dry_run=true`. The first call returns a `confirm_token`; call again with that token to mutate.
2. Component slugs must be unique per version. Bumping the version creates a new row; same slug+version returns 400.
3. Page block references to components are by `component_slug` — not by component id. Slugs resolve at render time.
4. Components live in a per-client registry (scoped by `client_id`) plus a global registry (`is_global=true`). Global components like `sys-scroll-sequence` don't need to be created per client.

## See also

- [templates-engine](../templates-engine/) — Liquid templates and themes that render these pages/posts
- [recipes/scroll-sequence](../recipes/scroll-sequence/) — uses content-platform + SpiderVideo to ship a scroll-sequence hero
- [recipes/preview-iteration](../recipes/preview-iteration/) — safe edit loop for components
