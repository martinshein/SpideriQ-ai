#!/bin/bash
# SpiderPublish — Set up a personalized outreach landing page
# Usage: TOKEN="cli_xxx:sk_xxx:secret_xxx" bash personalized-outreach.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"

echo "=== Step 1: Check IDAP data (do you have leads?) ==="
curl -s "$API/idap/businesses?limit=3&format=yaml" \
  -H "$AUTH"

echo ""
echo "=== Step 2: Create personalized landing page ==="
PAGE_ID=$(curl -s -X POST "$API/dashboard/content/pages" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d @../templates/dynamic-landing.json | python3 -c "
import json, sys
# Extract the page payload from the template file
data = json.load(sys.stdin)
print(data.get('id', 'error'))
")
echo "Created page: $PAGE_ID"

echo "=== Step 3: Publish ==="
curl -s -X POST "$API/dashboard/content/pages/$PAGE_ID/publish" \
  -H "$AUTH" > /dev/null && echo "Published"

echo "=== Step 4: Configure salesperson ==="
curl -s -X PATCH "$API/dashboard/templates/config" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d '{
    "salespersons": {
      "alex": {
        "name": "Alex Chen",
        "title": "Account Executive",
        "location": "San Francisco, CA",
        "bio": "10 years in enterprise sales.",
        "calendar_url": "https://calendly.com/alex"
      }
    }
  }' > /dev/null && echo "Salesperson configured"

echo "=== Step 5: Deploy ==="
curl -s -X POST "$API/dashboard/content/deploy" \
  -H "$AUTH" > /dev/null && echo "Deploying..."

echo ""
echo "Done! Test with a real Google Place ID:"
echo "  https://yoursite.com/lp/proposal/alex/{google_place_id}"
echo ""
echo "Find Place IDs from your IDAP data:"
echo "  curl -s '$API/idap/businesses?limit=5&fields=name,google_place_id&format=yaml' -H '$AUTH'"
