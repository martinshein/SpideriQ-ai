# recipes/tripwire-oto

Build a commerce funnel that sells a product: a low-priced **tripwire** checkout, a **one-time
offer** (OTO) upsell, then thank-you — taking real Stripe payments and landing an order.

## The hinge: fork a template, never hand-build the graph

A commerce funnel is a kind of Flow (a graph of page *nodes* + event *edges*) carrying `checkout`
and `oto` nodes. The graph has invariants the server validates, so you **create one by forking a
template** — never by assembling the graph yourself.

| Template slug | Shape |
|---|---|
| `single-product-checkout` | checkout → thank-you |
| `tripwire-oto` | checkout (tripwire) → one-time-offer upsell → thank-you |
| `subscription-checkout` | plan checkout → upgrade-OTO → thank-you |

## Quick ask: "build me a tripwire funnel with an upsell"

```
1. funnel_template_list { kind: "commerce" }          → see the 3 starters
2. funnel_template_apply { slug: "tripwire-oto", name: "..." }
                                                       → a NEW DRAFT funnel; capture flow_id
3. flow_update_node { flow_id, node_id, ... }          → customise checkout + OTO copy
4. (publish) live_mode=true                            → publish the funnel for real traffic
5. content_visual_check { page_url: "<funnel /f/ URL>", expected_no_text: ["couldn't load"] }
6. walk the buyer path in Stripe TEST mode (card 4242 4242 4242 4242)
7. commerce_order_list { status: "succeeded" }         → read the order back
```

The forked funnel uses the **products already in the template's catalog**. You cannot create a
commerce *product* through the agent tools yet — product creation uses the Medusa Admin UI today
(the agent-native product surface is coming soon).

## CLI equivalent

```bash
npx spideriq funnel-template list --kind commerce
npx spideriq funnel-template apply tripwire-oto --name "Spring tripwire"
# ... customise, then publish with live_mode=true ...
npx spideriq commerce orders list --status succeeded
npx spideriq commerce orders stats --window 30d
```

## Edge conditions — long-form operators only

When you add or edit an edge condition, use the **long-form** operator: `op: "equal"` (or
`not_equal`, `greater_than`, …). `op: "eq"` is **not** a recognised token — the edge will silently
never match and your buyer won't be routed.

## Publishing — `live_mode=true`, not a status flip

Publishing a funnel for real traffic is the `live_mode=true` switch, not a `status` change. After
publishing, verify the rendered page with `content_visual_check`.

## Stripe TEST mode

While building, keep Stripe in test mode and use card `4242 4242 4242 4242`, any future expiry, any
CVC. At the OTO step, **accept** charges the upsell off-session and routes to thank-you; **decline**
is a no-op that also routes to thank-you. Never test with a live card.

## Reading orders

A succeeded payment writes a canonical order (Stripe is the order of record). Orders are
**read-only** — there's no create/update/delete:

- `commerce_order_list { status?, contact_email?, since?, limit?, offset? }`
- `commerce_order_get { order_id }`
- `commerce_order_stats { window: "7d" | "30d" | "90d" | "all" }`
- `commerce_order_export_csv { ... }`

`total_amount_cents` is the authoritative minor-unit (cents) figure — divide by 100 for display.

## Anti-patterns

- ❌ Building a commerce graph with raw `flow_create` + `flow_add_node`. ✅ `funnel_template_apply`.
- ❌ `op: "eq"` on an edge → silent non-match. ✅ `op: "equal"`.
- ❌ Flipping a `status` field to publish. ✅ `live_mode=true`.
- ❌ Telling the user they can create a product through the agent tools. ✅ Product creation is the
  Medusa Admin UI today; the agent-native surface is coming soon.
- ❌ Testing with a live Stripe card. ✅ Test mode + card `4242…`.

Pairs with: [examples/build-tripwire-funnel.sh](../../examples/build-tripwire-funnel.sh)
