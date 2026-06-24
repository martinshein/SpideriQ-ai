#!/bin/bash
# SpiderPublish — build a tripwire + one-time-offer (OTO) commerce funnel end-to-end via the public REST API.
#
# Mirrors the tripwire-oto recipe (shared/recipes/tripwire-oto/SKILL.md).
# Hits the same endpoints the funnel_template_* + commerce_order_* MCP tools wrap, so you can
# run this in CI, inside a degraded MCP session, or anywhere bash + curl + jq are available.
#
# Usage:
#   TOKEN="<your PAT>" bash build-tripwire-funnel.sh
#
# Optional env overrides:
#   API_BASE      default: https://spideriq.ai
#   FUNNEL_NAME   default: "Tripwire funnel <timestamp>"
#
# Output: the new funnel's flow_id + public /f/ URL, then the current order count.
#
# NOTE: this builds a DRAFT funnel from a template and reads orders — it does NOT walk a real
# purchase (that needs a browser + Stripe test card 4242 4242 4242 4242 at the checkout page).
# Product creation is NOT covered: products are created in the Medusa Admin UI today; the
# agent-native product surface is coming soon.

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
API_BASE="${API_BASE:-https://spideriq.ai}"
FUNNEL_NAME="${FUNNEL_NAME:-Tripwire funnel $(date +%Y%m%d-%H%M%S)}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT — see https://docs.spideriq.ai/quickstart}"

# ─── 1. List the commerce starters ───────────────────────────────────────────
echo "1. Listing commerce funnel templates..."
TEMPLATES=$(curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "$API_BASE/api/v1/dashboard/content/funnels/templates?kind=commerce")
echo "   commerce starters: $(echo "$TEMPLATES" | jq -r '[.templates[]?.slug] | join(", ") // "(none)"')"

# ─── 2. Fork the tripwire-oto template into a new DRAFT funnel ────────────────
echo "2. Forking tripwire-oto → \"$FUNNEL_NAME\"..."
APPLY=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg name "$FUNNEL_NAME" '{ name: $name }')" \
  "$API_BASE/api/v1/dashboard/content/funnels/templates/tripwire-oto/apply")

FLOW_ID=$(echo "$APPLY" | jq -r '.flow_id // .id // empty')
[ -n "$FLOW_ID" ] || { echo "   apply failed: $APPLY" >&2; exit 1; }
echo "   flow_id: $FLOW_ID"
echo "   public URL: $API_BASE/f/$FLOW_ID  (DRAFT until you publish with live_mode=true)"

# ─── 3. Next steps (manual) ───────────────────────────────────────────────────
cat <<EOF

   Next (do these via the dashboard or MCP — not scripted here):
   - Customise the checkout + OTO node copy (flow_update_node). Edge conditions use op:"equal", never "eq".
   - Publish the funnel with live_mode=true (NOT a status flip).
   - content_visual_check the published $API_BASE/f/$FLOW_ID page.
   - Walk the buyer path in Stripe TEST mode (card 4242 4242 4242 4242). OTO accept charges the
     upsell off-session; decline is a no-op. Both route to thank-you.
EOF

# ─── 4. Read orders back (read-only) ──────────────────────────────────────────
echo
echo "4. Current succeeded-order count for this workspace..."
STATS=$(curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "$API_BASE/api/v1/commerce/orders/stats?window=30d")
echo "   30-day orders: $(echo "$STATS" | jq -r '.total_orders // 0'), revenue (cents): $(echo "$STATS" | jq -r '.revenue_cents // 0')"

echo
echo "Done."
echo "  Funnel: $API_BASE/f/$FLOW_ID (draft)"
echo "  Read orders any time: GET /api/v1/commerce/orders  (or: spideriq commerce orders list)"
