#!/bin/bash
# SpiderPublish — Build and deploy a site via cURL
# Usage: TOKEN="cli_xxx:sk_xxx:secret_xxx" bash build-and-deploy.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"

echo "=== Step 1: Configure site settings ==="
curl -s -X PATCH "$API/dashboard/content/settings" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{
    "site_name": "My Site",
    "primary_color": "#2563eb",
    "site_tagline": "Built with SpiderPublish"
  }' | python3 -c "import json,sys; print(json.load(sys.stdin).get('site_name', 'OK'))"

echo "=== Step 2: Set up navigation ==="
curl -s -X PUT "$API/dashboard/content/navigation/header" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"label": "Home", "url": "/", "order": 0},
      {"label": "About", "url": "/about", "order": 1}
    ]
  }' > /dev/null && echo "Navigation set"

echo "=== Step 3: Create homepage ==="
PAGE_ID=$(curl -s -X POST "$API/dashboard/content/pages" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d @../templates/homepage.json | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "Created page: $PAGE_ID"

echo "=== Step 4: Publish ==="
curl -s -X POST "$API/dashboard/content/pages/$PAGE_ID/publish" \
  -H "$AUTH" > /dev/null && echo "Published"

echo "=== Step 5: Apply theme ==="
curl -s -X POST "$API/dashboard/templates/apply-theme" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"theme": "default"}' > /dev/null && echo "Theme applied"

echo "=== Step 6: Deploy ==="
curl -s -X POST "$API/dashboard/content/deploy" \
  -H "$AUTH" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Deploy: {d.get(\"status\", \"started\")}')"

echo ""
echo "Done! Check deploy status:"
echo "  curl -s $API/dashboard/content/deploy/status -H \"$AUTH\""
