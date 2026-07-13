# recipes/define-a-custom-collection

Define your **own** content type — case studies, team members, FAQs, products, testimonials —
declare its schema, fill it with rows, and render each row as a first-class page. Unlike the
built-in pages/posts/docs, you invent the shape: you author the `schema_json` *and* the records,
in one session. Shipped 2026-07-12 (Custom Collections, SpiderPublish Phase 1).

**Read when:** the built-in types don't fit — you need structured, repeatable content with its
own fields, authored in bulk and rendered as a list + detail.

## Model

- A **collection** is the definition: `slug`, `label`, `schema_json` (the fields), `route_base`
  (detail-page URL base, defaults to the slug), `is_public` (expose via the public door).
- A **record** is one row: `slug`, `data` (values validated against `schema_json`), `seo_title`,
  `seo_description`, `og_image_url`, `sort`, `publish_at`, `status` (`draft`|`published`|`archived`).
- Field types: `text`, `number`, `bool`, `select`, `date`, `richtext`, `media`, `relationship`,
  `blocks`. Every record is a page: slug + SEO + pretty URL + a multi-format body.

## Quick ask: "add a Case Studies section and fill it"

```
# 1. Define the collection (non-destructive; enforces your max_collections cap)
createCollection(
  slug = "case-studies",
  label = "Case Studies",
  schema_json = { fields: {
    title:   { type: "text" },
    client:  { type: "text" },
    summary: { type: "richtext" },
    logo:    { type: "media" }
  } }
)

# 2. Bulk-fill the rows — 1–100 in ONE transaction. Any bad row rejects the WHOLE batch,
#    and any field not in the schema 422s with {errors, warnings} (nothing is silently dropped).
bulkCreateCollectionRecords(collection = "case-studies", records = [
  { slug: "acme",   data: { title: "Acme",   client: "Acme Co",    summary: "..." } },
  { slug: "globex", data: { title: "Globex", client: "Globex LLC", summary: "..." } }
])
# For a single row use createCollectionRecord. Both save as drafts.

# 3. Publish a row — a status change is the GATED transition (two-phase, like every mutation)
updateCollectionRecord(collection = "case-studies", record_id = <id>, status = "published", dry_run = true)
# → preview + confirm_token (cft_...); repeat with it:
updateCollectionRecord(collection = "case-studies", record_id = <id>, status = "published", confirm_token = "cft_...")

# 4. Expose the collection through the public door
updateCollection(slug = "case-studies", is_public = true)

# 5. Render it — a kind="dynamic" component whose source_id is the collection slug.
#    See recipes/build-a-dynamic-component. Individual records also render at their pretty URL.
#    → /case-studies/acme  ·  list door: GET /api/v1/content/data-sources/case-studies/items

# 6. Deploy — publishing flips a store flag; only a deploy makes it live.
deploySite()
```

## Relationships

Add a `relationship` field to the schema to link a record to another collection or to your
`posts`/`authors`. Set the target on the row's `data`. On read, pass `depth=1` to fill in the
linked record one level (batched — a hundred related rows stay fast); `depth=0` returns just the
ids.

## Gotchas

- **Slugs use hyphens, not underscores** — `case-studies`, not `case_studies`.
- **Unknown fields are rejected, not ignored** — `data` is validated against `schema_json`; a
  typo'd field 422s with `{errors, warnings}`. Read the collection first if unsure.
- **Reads use the record slug; writes use the record id.** `getCollectionRecord` takes a
  `record_slug`; `updateCollectionRecord` / `deleteCollectionRecord` take a `record_id`.
- **Publishing ≠ deploying.** A published row is live in the store; the site reflects it after a deploy.
- **Private until you say so** — `is_public=true` is required before the door / dynamic binding
  sees the collection, and only **published** rows are served.
- **Delete cascades and is gated.** `deleteCollection` removes the collection and all its rows;
  `deleteCollectionRecord` removes one — both behind `dry_run → confirm_token`.
- **Quotas.** Collection + record creates enforce your plan's `max_collections` / `max_records`
  caps (403 with `rule_id=max_collections_exceeded` / `max_records_exceeded`); a bulk is checked
  against the full batch size.

## Full reference

https://docs.spideriq.ai/site-builder/custom-collections/ · render with
[recipes/build-a-dynamic-component](../build-a-dynamic-component/SKILL.md) · the machine-readable
schema is in `GET /api/v1/content/help` → the `custom_collections` stanza.
