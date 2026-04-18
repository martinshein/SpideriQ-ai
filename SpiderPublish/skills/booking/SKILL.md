# booking

SpiderBook — end-to-end appointment / service-slot booking for tenant sites. Backed by cal.com for the actual calendar engine; SpiderIQ owns the widget, the dashboard, the Liquid tag, and the storage.

**Exposed via:** `@spideriq/mcp@1.0.0` (kitchen-sink, 257 tools) — 15 booking tools. If you're running the slim `@spideriq/mcp-publish` (105 tools), add a second MCP server entry for the booking slice when it lands as a standalone package.

## What you ship with this

- A customer-facing widget (`apps/booking-component`) that collects step-by-step answers — service pick, slot pick, contact form, confirm
- A standalone route at `/book/{flow_id}` on the tenant's primary domain
- A `{% booking flow_id: biz.booking_flow_id %}` Liquid tag for embedding inside any page template
- A dashboard editor under `/dashboard/booking/*` for authoring flows, services, and translations
- Automatic cal.com event-type provisioning on publish
- A confirmation email with a signed manage token the customer uses to self-reschedule or cancel
- Per-locale label overrides (BCP-47 Accept-Language fallback)

## When to use

- A tenant needs customers to book an appointment, service, or consultation
- You're migrating a Tilda/Squarespace/Wix booking form to SpiderPublish
- You need i18n for booking labels (English default + any locale overrides)
- You want to embed the booking widget inside a page template using Liquid

## When NOT to use

- Generic content / CMS edits → use [content-platform](../content-platform/)
- Just want a custom HTML form that emails the submission → use a page with a `form` block
- Selling products / physical goods with inventory → booking flows don't ship an inventory model

## End-to-end: from zero to a live booking page

```
# 1. Find an archetype close to what you want (nail-salon, haircut, therapy, ...)
booking_template_list(category="nail-salon")

# 2. Clone it into the tenant's library
booking_template_clone(
  template_id="nail-salon-default",
  business_id="<business_uuid_from_crm>",
  name="Downtown Nail Salon — Booking"
)
# → returns { flow_id, version }

# 3. Adjust steps, labels, theme, or per-locale translations
booking_flow_update(
  flow_id=<flow_id>,
  flow={ ...step graph... },
  theme={ primary_color: "#e8556f", button_label: "Book now" },
  translations={ "es": { "steps.pick_service.label": "Elige un servicio" } }
)

# 4. Publish — dry_run preview first
booking_flow_publish(flow_id=<flow_id>, dry_run=true)
# → returns { confirm_token, preview_summary, cal_event_type_preview }

# 5. Commit
booking_flow_publish(flow_id=<flow_id>, confirm_token="cft_...")
# → provisions the cal.com event type, flips status to live

# 6. Get the public URL
booking_flow_preview(flow_id=<flow_id>)
# → { url: "https://<domain>/book/<flow_id>" }

# 7. Redeploy the tenant site so the /book route + Liquid tag pick up the new flow
content_deploy_site(dry_run=true) → confirm_token → content_deploy_site(confirm_token=...)
```

## Embedding the widget inside a page

The Liquid tag works in any page template or theme section. Example in a landing page's Liquid template:

```liquid
<section class="cta">
  <h2>Book your appointment</h2>
  {% booking flow_id: business.booking_flow_id %}
</section>
```

The tag expands to a `<spider-booking-widget flow-id="...">` custom element that fetches the flow from the public render endpoint at request time. The renderer honours `Accept-Language` for labels.

## Managing bookings

```
# List everything (paginated)
booking_list(business_id=<id>, status="confirmed", since="2026-04-01")

# Pull a single row
booking_get(booking_id=<id>)
```

Reschedule / cancel flow for a customer (the widget's confirmation email contains a signed `manage_token`):

```
booking_reschedule(manage_token="bkm_...", new_slot_start="2026-04-20T14:00:00Z")
booking_cancel(manage_token="bkm_...", reason="customer request")
```

These two tools hit cal.com directly — there is no server-side dry_run. Treat them as destructive and confirm with the human or customer before firing.

## Services (what can be booked)

Services are the bookable units ("30-minute haircut", "1-hour consultation"). Flows reference services by id.

```
service_create(business_id=<id>, name="30-min haircut", duration_minutes=30, price_cents=4500)
service_update(service_id=<id>, price_cents=5000)
service_delete(service_id=<id>, dry_run=true) → confirm_token → service_delete(confirm_token=...)
# (service_delete is soft-delete — the row is hidden, not dropped)
```

Staff assignment (which stylist can fulfil which service) lives in a separate junction table managed through the dashboard's staff tab — it is not exposed on the MCP surface yet.

## Key rules

1. `booking_flow_publish` and `service_delete` default to `dry_run=true`. The first call returns a `confirm_token` (7-day TTL, single-use); pass it back to actually mutate.
2. `booking_flow_publish` talks to cal.com as part of the commit — a publish failure means the cal event type didn't provision. Inspect the error and retry; the flow stays in `draft` until a successful publish.
3. `booking_flow_update` bumps the flow `version` automatically whenever the `flow` or `schema` fields change. Cached renders invalidate by version.
4. The public render endpoint returns `Vary: Accept-Language` so CDNs cache per-locale correctly.
5. The customer's `manage_token` is signed and short-lived. Agents should source it from the confirmation email, not from the database.
6. The widget bundle is served from `/api/v1/booking/bundle.js` with an in-container fallback so it keeps working even when a tenant hasn't been redeployed since the last widget change.
7. Every dashboard call is enforced across the same five project locks as the rest of SpiderPublish — bind your working directory with `spideriq use <project>` once and the SDK rewrites URLs for you.

## See also

- [content-platform](../content-platform/) — pages, posts, docs, components, directory pages
- [templates-engine](../templates-engine/) — Liquid templates and themes (the `{% booking %}` tag lives here)
- [upload-host-media](../upload-host-media/) — upload the business photo / logo the widget shows in its header
