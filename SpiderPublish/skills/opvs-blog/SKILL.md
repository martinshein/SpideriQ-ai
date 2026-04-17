# opvs-blog

Blog authoring workflow: authors, tags, categories, posts, related posts, featured posts, full-text search, changelog.

**Exposed via:** `@spideriq/mcp-publish`. Most blog tools live under the `content_*` namespace (posts, tags, categories, authors). This skill is a task-oriented lens on top of those.

## When to use

- Publishing a blog post with an author, tags, and categories
- Setting featured posts for the homepage
- Wiring related-posts sections
- Bulk-updating post metadata
- Publishing product changelog entries

## When NOT to use

- Versioned developer docs → [agentdocs](../agentdocs/)
- Landing pages and marketing pages → [content-platform](../content-platform/) → pages (not posts)

## Common tool chains

### First-time blog setup

```
content_create_author(name, slug, role, bio, avatar_url)
content_create_category(name, slug, parent_slug?)
content_create_tag(name, slug)
content_create_post(author_id, category_id, tag_ids, title, slug, body, ...)
content_publish_post(post_id)   # dry_run → confirm_token
```

### Featured posts section

```
content_list_featured_posts(limit=3)        # read current state
content_set_post_status(post_id, status="featured")
```

### Related posts

```
content_set_post_related(post_id, related_ids=[id1, id2, id3])
```

### Full-text search

```
content_search_posts(query, limit?)
```

## Key rules

1. Post `body` is Tiptap JSON — not HTML, not Markdown. The renderer converts at request time.
2. `view_count` auto-increments on public reads (`GET /content/posts/{slug}`). Use it for "trending" queries.
3. Authors are soft-deleted (`deleted_at` column). Listing tools filter out soft-deleted by default; pass `include_deleted=true` to see them.
4. Tags and categories are separate vocabularies — tags are flat, categories are hierarchical (nested via `parent_id`).

## See also

- [content-platform](../content-platform/) — the underlying tool surface (posts/tags/categories/authors all live there)
- [templates-engine](../templates-engine/) — the Liquid templates that render blog pages

## Upstream

Full opvsHUB source: [spideragent/skills/opvsHUB/skills/opvs-blog/](https://github.com/martinshein/SpiderIQ/tree/main/spideragent/skills/opvsHUB/skills/opvs-blog) (internal)
