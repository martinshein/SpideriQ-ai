# recipes/section-library

Browse the SpiderIQ section library and insert a ready-made section into an existing page.

The 30-section library lives on the SpiderIQ source tenant. Every section is `is_global=true`, so engineering fixes propagate to every site that uses them.

## Two-step path

```
# 1. Browse the catalog (public read, no auth)
content_list_marketplace_components(category="hero", is_featured=true)

# 2. Insert one into a page (Phase 11+12 gated)
page_insert_section(
  page_id      = "<page uuid>",
  component_slug = "hero-video-bg",
  props        = { headline: "...", cta_text: "...", cta_path: "/signup" },
  position     = "end",            # or "start" / "before" / "after" / <int>
  dry_run      = true              # → returns confirm_token + preview
)
```

The first `page_insert_section` call returns:

```json
{
  "dry_run": true,
  "preview": {
    "action": "insert_section",
    "page_id": "...",
    "component_slug": "hero-video-bg",
    "insertion_index": 2,
    "new_block_id": "...",
    "blocks_count_before": 2,
    "blocks_count_after": 3
  },
  "confirm_token": "tok_...",
  "expires_at": "2026-05-03T..."
}
```

A second call with `confirm_token=<token>` actually inserts the block.

## When to use

- Filling out an existing page that needs a hero / pricing / FAQ / logo cloud
- Adding a CTA banner to the bottom of every page in a tenant
- Programmatic page assembly: list → preview → insert → publish

## When NOT to use

- **Composing a brand-new template from scratch** → use `recipes/apply-template` and pick a starter, OR write a `templates/<slug>/template.json` manifest per `CONTRIBUTING-TEMPLATES.md`. Section-library inserts are for *modifying existing pages*, not building from blank.
- **You need a section that's not in the palette** → open an issue titled `component: <name>` first; engineering ships the global component before your insert lands.

## Position semantics

| Position | Effect |
|---|---|
| `"end"` (default) | Append at the end of `blocks[]`. |
| `"start"` | Prepend (block 0). |
| `"before"` + `anchor_block_id` | Insert directly before the anchor. |
| `"after"` + `anchor_block_id` | Insert directly after the anchor. |
| `<integer>` | Explicit 0-based index, clamped to `[0, len(blocks)]`. |

## After the insert

The page is **not** automatically republished. The new block sits as part of the page row. Either:
- `content_publish_page(page_id)` to push the new block live
- `content_deploy_site` to re-render the whole site

## Background videos

`hero-video-bg` and `sys-bg-video` accept a `video_slug` from the curated catalog. Browse via:

```
content_list_marketplace_bg_videos(category="nature", is_featured=true)
content_get_marketplace_bg_video(slug="nature-coastal-waves")
```

The renderer resolves `video_slug` → `r2_url` + `poster_url` at request time.

## See also

- [examples/insert-section.sh](../../examples/insert-section.sh) — runnable bash example
- [templates/COMPONENT-PALETTE.md](../../templates/COMPONENT-PALETTE.md) — canonical 30-section reference
- [recipes/apply-template/](../apply-template/) — the "start from a curated starter site" path
