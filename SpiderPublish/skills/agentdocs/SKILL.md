# agentdocs

Versioned documentation projects — multi-page docs with tree hierarchy, full-text search, rollback, and per-page version history.

**Exposed via:** `@spideriq/mcp-publish`. Tool namespace: `agentdocs_*` and `docs_*`.

## When to use

- Building a `/docs/*` section with hierarchical nav
- Authoring API reference, tutorials, or developer guides that need versioning
- Bulk-creating or bulk-updating a doc tree
- Rolling back a page to a previous version
- Full-text search across a docs project

## When NOT to use

- Blog posts with tags / categories / authors → [opvs-blog](../opvs-blog/) (uses `content_posts`)
- Landing pages or marketing pages → [content-platform](../content-platform/) (uses `content_pages`)
- Single-page FAQ-style content → a component + page block

## Common tool chains

| Goal | Chain |
|---|---|
| New docs section | `agentdocs_create_project(name, slug)` → `agentdocs_bulk_create_pages([...])` |
| Add a page | `agentdocs_create_page(project, slug, title, body)` |
| Update + check diff | `agentdocs_update_page` → `agentdocs_page_diff(slug, version_a, version_b)` |
| Rollback | `agentdocs_page_history(slug)` → pick version → `agentdocs_page_rollback(slug, version)` |
| Move a page in the tree | `agentdocs_move_page(slug, new_parent_slug)` |
| Search | `agentdocs_search_docs(query, project?)` |

## Key rules

1. Docs are a separate subsystem from blog posts and marketing pages. Their tables are `content_docs`, not `content_posts` or `content_pages`. Mixing APIs causes 404s on the wrong lookup.
2. Every page edit creates a new version automatically. Rollback is non-destructive — it creates a new version with the rolled-back content.
3. The tree is stored via `parent_slug` — moving a parent moves all descendants.
4. Full-text search is FTS-indexed on body + title; updates are near-realtime.

## See also

- [content-platform](../content-platform/) — `content_get_docs_tree` at the public layer is what the Liquid renderer reads at request time

## Upstream

Full opvsHUB source: [spideragent/skills/opvsHUB/skills/agentdocs/](https://github.com/martinshein/SpiderIQ/tree/main/spideragent/skills/opvsHUB/skills/agentdocs) (internal)
