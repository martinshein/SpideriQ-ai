# Build a SpiderIQ Personalized Landing Page

When the user asks for a personalized / outreach / per-lead landing page, execute these steps.

## Step 1: read the merge-tag vocabulary

Open [SpiderPublish/MERGE-TAGS.md](../../../MERGE-TAGS.md). It lists every merge tag the renderer resolves at request time. Common ones:

- `{{ lead.name }}` — business name
- `{{ lead.city }}` — city from IDAP geocoding
- `{{ lead.country }}` — ISO country code
- `{{ lead.email }}` — contact email
- `{{ lead.phone }}` — verified phone
- `{{ lead.rating }}` — Google Maps rating
- `{{ client.name }}` — your tenant brand name
- `{{ client.logo_url }}` — your logo

Pick the ones relevant to the user's outreach script. Don't invent tag names not in MERGE-TAGS.md.

## Step 2: create the page with the dynamic_landing template

```
content_create_page({
  slug: "offer",                        // becomes /lp/offer/{place_id}
  title: "Personalized Offer",
  template: "dynamic_landing",
  blocks: [
    { type: "hero", data: { headline: "Hi {{ lead.name }}, here's how we help {{ lead.city }} businesses" } },
    { type: "rich_text", data: { content: "We noticed {{ lead.name }} has a {{ lead.rating }}-star rating..." } },
    { type: "cta_section", data: { headline: "Book a call", button_text: "Schedule" } }
  ]
})
```

The `template: "dynamic_landing"` is what activates the `/lp/{slug}/{place_id}` URL pattern. Other templates serve a single static page at `/{slug}`.


## Step 2b: pick the identifier key you actually hold

The identifier at the end of a `/lp/` link is read as a Google place ID by default. If your list
carries something else, name the key with `?resolve_key=`:

```
/lp/{page-slug}/acme-plumbing.de?resolve_key=domain
/lp/{page-slug}/{rep}/DE123456789?resolve_key=vat
```

Ten keys resolve a business:

| Source | Keys |
|---|---|
| Maps / crawl | `place_id` (default), `domain` |
| VayaPin | `pin_name`, `pin_data_set_id`, `account_id`, `pin_subscription_id` |
| Company registry | `vat`, `lei`, `tax_id`, `registration_number` |

`email` is still accepted for backwards compatibility but does **not** identify a business — it
always returns 404. Use `domain`.

## Step 2c: decide what an unidentified visitor sees

Personalised links get forwarded and go stale. When the identifier does not resolve, `lead` is
null and the page still renders — the renderer runs with strict variables off, so `{{ lead.name }}`
comes out empty rather than throwing.

Set a fallback so an anonymous visit still reads like a finished page:

```json
{ "custom_fields": { "demo_business": "your business", "demo_city": "your city" } }
```

Without one the shipped template falls back to the words "Your Business".

**If you write a custom `dynamic_landing` template:** guard the blocks that need real data with
`{% if lead %}…{% endif %}` and leave your hero, blocks and CTA outside the guard. An unguarded
nested `lead.*` dereference is the one thing that turns a missing lead into a 500.

## Step 2d: rep-branded links (optional)

A second URL segment names a salesperson configured on the site, and the page gains their name,
title, photo and booking link:

```
/lp/{page-slug}/{salesperson-slug}/{identifier}
```

## Step 3: verify resolve_lead works for a sample place_id

Before publishing, sanity-check the lead lookup:

```
content_resolve_lead({ place_id: "<sample_google_place_id>" })
// returns { name, city, country, email, phone, rating, ... }
```

If the call returns 404, the lead isn't in IDAP yet — it needs to be scraped first via the lead-gen pipeline (separate kit / dashboard surface). For testing, ask for a place_id you know is already in the system.

## Step 4: publish + apply theme + deploy

Standard flow:

```
content_publish_page({ page_id, dry_run: true })
content_publish_page({ page_id, confirm_token })
template_apply_theme({ theme: "default" })       // if not already
content_deploy_site_preview
content_deploy_site_production({ confirm_token })
```

## Step 5: verify the live URL

```
GET https://<tenant-domain>/lp/offer/<place_id>
```

Check that:
- The hero says "Hi <real business name>, here's how we help <real city> businesses"
- The merge tags resolved (no literal `{{ lead.name }}` in the rendered HTML)
- The CTA block triggers the conversion path you intended

## Don't

- **Use a non-`dynamic_landing` template** — merge tags only resolve under that template's URL pattern.
- **Reference a tag not in MERGE-TAGS.md** — unresolved tags render as literal text on the live page.
- **Test against an unscraped place_id** — `resolve_lead` 404s; the page renders with empty merge values.
- **Forget `client.*` tags** — those resolve from your tenant's `content_settings`, not from the lead. Set `site_name` and `logo_url` first.
