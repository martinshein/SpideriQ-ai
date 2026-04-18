#!/bin/bash
# SpiderPublish — Stand up a bookable appointment page from zero (v1.0.0+)
#
# What this does:
#   Takes a single business record, clones a global flow archetype into the
#   tenant's library, patches the theme to match the tenant brand, publishes
#   the flow (provisions a cal.com event type under the hood), and redeploys
#   the tenant site so the /book/{flow_id} route and {% booking %} Liquid
#   tag pick up the new flow.
#
# Use this for:
#   - Migrating a Tilda / Wix / Squarespace booking form to SpiderPublish
#   - Spinning up a service-booking page for a salon, clinic, studio, etc.
#   - Seeding a demo tenant with a working booking widget in under a minute
#
# Preferred path — MCP/CLI:
#   spideriq booking templates list --category nail-salon
#   spideriq booking templates clone nail-salon-default --business-id <uuid> --name "..."
#   spideriq booking flows update <flow_id> --theme '{"primary_color":"#e8556f"}'
#   spideriq booking flows publish <flow_id> --dry-run
#   spideriq booking flows publish <flow_id> --confirm <token>
#   spideriq content deploy
#
# This shell script is the curl fallback for runtimes without Node.
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" PID="cli_xxx" \
#   BUSINESS_ID="<business_uuid>" \
#   ARCHETYPE="nail-salon-default" \
#   BRAND_COLOR="#e8556f" \
#   bash booking-flow.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"
PID="${PID:?Set PID=cli_xxx (your short project id)}"
BUSINESS_ID="${BUSINESS_ID:?Set BUSINESS_ID=<uuid> (from your CRM)}"
ARCHETYPE="${ARCHETYPE:-nail-salon-default}"
BRAND_COLOR="${BRAND_COLOR:-#e8556f}"
FLOW_NAME="${FLOW_NAME:-Bookings}"

DASH="${API}/dashboard/projects/${PID}"

echo "== 1. Clone archetype '${ARCHETYPE}' into tenant library =="
CLONE_JSON=$(curl -sS -X POST "${DASH}/booking/templates/clone" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d "{\"template_id\":\"${ARCHETYPE}\",\"business_id\":\"${BUSINESS_ID}\",\"name\":\"${FLOW_NAME}\"}")
FLOW_ID=$(echo "$CLONE_JSON" | python3 -c "import json,sys;print(json.load(sys.stdin)['flow_id'])")
echo "   → flow_id=${FLOW_ID}"

echo "== 2. Patch theme to brand color ${BRAND_COLOR} =="
curl -sS -X PATCH "${DASH}/booking/flows/${FLOW_ID}" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d "{\"theme\":{\"primary_color\":\"${BRAND_COLOR}\",\"button_label\":\"Book now\"}}" \
  > /dev/null
echo "   → theme patched, flow version auto-bumped"

echo "== 3. Publish (dry_run) to get confirm_token =="
PREVIEW_JSON=$(curl -sS -X POST "${DASH}/booking/flows/${FLOW_ID}/publish" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d '{"dry_run":true}')
CFT=$(echo "$PREVIEW_JSON" | python3 -c "import json,sys;print(json.load(sys.stdin)['confirm_token'])")
echo "   → confirm_token=${CFT:0:16}..."

echo "== 4. Commit publish (provisions cal.com event type) =="
curl -sS -X POST "${DASH}/booking/flows/${FLOW_ID}/publish" \
  -H "${AUTH}" -H "Content-Type: application/json" \
  -d "{\"confirm_token\":\"${CFT}\"}" > /dev/null
echo "   → flow live"

echo "== 5. Fetch the public /book/{flow_id} URL =="
PREVIEW=$(curl -sS "${DASH}/booking/flows/${FLOW_ID}/preview" -H "${AUTH}")
echo "   → $(echo "$PREVIEW" | python3 -c "import json,sys;print(json.load(sys.stdin)['url'])")"

echo "== 6. Redeploy tenant site so /book + {% booking %} pick up the flow =="
DEPLOY_PREVIEW=$(curl -sS -X POST "${DASH}/content/deploy/preview" -H "${AUTH}")
DCFT=$(echo "$DEPLOY_PREVIEW" | python3 -c "import json,sys;print(json.load(sys.stdin)['confirm_token'])")
curl -sS -X POST "${DASH}/content/deploy/production?confirm_token=${DCFT}" -H "${AUTH}" > /dev/null
echo "   → tenant redeployed"

echo
echo "Done. Visit the preview URL above, or drop {% booking flow_id: business.booking_flow_id %} into any page template."
