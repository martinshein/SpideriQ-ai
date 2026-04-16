#!/bin/bash
# SpiderPublish — Build and deploy a site via cURL (Phase 11+12 flow)
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" PID="cli_xxx" bash build-and-deploy.sh
#
# TOKEN — your PAT in cli_id:api_key:api_secret form
# PID   — short project id (cli_xxx). Same value the token was issued for.
#
# Every destructive call uses the 2-phase dry_run → confirm_token flow.
# URLs use the project-scoped form (/api/v1/dashboard/projects/{pid}/...)
# so Lock 1↔2 fires server-side and the Deprecation header disappears.

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"
PID="${PID:?Set PID=cli_xxx (your short project id)}"

json() { python3 -c "$1"; }

echo "=== Step 1: Configure site settings (preview + confirm) ==="
PREV=$(curl -s -X PATCH "$API/dashboard/projects/$PID/content/settings?dry_run=true" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{
    "site_name": "My Site",
    "site_tagline": "Built with SpiderPublish",
    "primary_color": "#3b82f6"
  }')
TOK=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
curl -s -X PATCH "$API/dashboard/projects/$PID/content/settings?confirm_token=$TOK" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{
    "site_name": "My Site",
    "site_tagline": "Built with SpiderPublish",
    "primary_color": "#3b82f6"
  }' | json "import json,sys; d=json.load(sys.stdin); print(f'  settings: {d.get(\"site_name\",\"OK\")}')"

echo "=== Step 2: Set up navigation (not gated) ==="
curl -s -X PUT "$API/dashboard/projects/$PID/content/navigation/header" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"label": "Home", "url": "/"},
      {"label": "About", "url": "/about"}
    ]
  }' > /dev/null && echo "  navigation set"

echo "=== Step 3: Create homepage (not gated) ==="
PAGE_ID=$(curl -s -X POST "$API/dashboard/projects/$PID/content/pages" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d @../templates/homepage.json | json "import json,sys; print(json.load(sys.stdin)['id'])")
echo "  page: $PAGE_ID"

echo "=== Step 4: Publish homepage (preview + confirm) ==="
PREV=$(curl -s -X POST "$API/dashboard/projects/$PID/content/pages/$PAGE_ID/publish?dry_run=true" -H "$AUTH")
TOK=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
curl -s -X POST "$API/dashboard/projects/$PID/content/pages/$PAGE_ID/publish?confirm_token=$TOK" \
  -H "$AUTH" > /dev/null && echo "  published"

echo "=== Step 5: Apply theme (preview + confirm) ==="
PREV=$(curl -s -X POST "$API/dashboard/projects/$PID/templates/apply-theme?dry_run=true" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"theme": "default"}')
TOK=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
curl -s -X POST "$API/dashboard/projects/$PID/templates/apply-theme?confirm_token=$TOK" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"theme": "default"}' > /dev/null && echo "  theme applied"

echo "=== Step 6: Check readiness (not gated) ==="
READY=$(curl -s "$API/dashboard/projects/$PID/content/deploy/readiness" -H "$AUTH" \
  | json "import json,sys; d=json.load(sys.stdin); print('READY' if d.get('ready') else 'NOT READY: '+str(d.get('blockers',[])))")
echo "  $READY"

echo "=== Step 7: Deploy preview → production ==="
PREV=$(curl -s -X POST "$API/dashboard/projects/$PID/content/deploy/preview" -H "$AUTH")
TOK=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
PREVIEW_URL=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin).get('preview_url',''))")
echo "  preview: $PREVIEW_URL"

curl -s -X POST "$API/dashboard/projects/$PID/content/deploy/production?confirm_token=$TOK" -H "$AUTH" \
  | json "import json,sys; d=json.load(sys.stdin); print(f'  deploy: {d.get(\"status\",\"started\")} version={d.get(\"version_id\",\"?\")}')"

echo ""
echo "Done. Follow-up commands:"
echo "  curl -s $API/dashboard/projects/$PID/content/deploy/status -H \"$AUTH\"  # latest deploy"
echo "  curl -s $API/dashboard/projects/$PID/content/deploy/history -H \"$AUTH\" # recent history"
