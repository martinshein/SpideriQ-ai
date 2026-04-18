#!/bin/bash
# SpiderPublish — Bulk-import listings into a directory category (v0.9.5+)
#
# What this does:
#   Creates a directory category once, then bulk-imports a JSON array of
#   listings. Returns the number upserted, any per-row failures, and the
#   list of cities affected so you can verify the right URLs were created.
#
# Use this for:
#   - Turning a SpiderMaps / IDAP result set into a programmatic-SEO directory
#   - Migrating a Yellow Pages-style site to SpiderPublish
#   - Seeding a directory with a known asset (listings from a CSV export)
#
# Preferred path — MCP/CLI:
#   spideriq directory categories create --name "Plumbers" \
#     --seo-title "Best {category} in {city} | Your Brand"
#   spideriq directory listings import plumbers --file ./listings.json
#
# This shell script is the curl fallback for runtimes without Node.
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" PID="cli_xxx" \
#   CAT_SLUG="plumbers" CAT_NAME="Plumbers" \
#   LISTINGS_FILE="./listings.json" \
#   bash directory-bulk-import.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"
PID="${PID:?Set PID=cli_xxx (your short project id)}"
CAT_SLUG="${CAT_SLUG:?Set CAT_SLUG (e.g. plumbers)}"
CAT_NAME="${CAT_NAME:-$CAT_SLUG}"
LISTINGS_FILE="${LISTINGS_FILE:?Set LISTINGS_FILE=path/to/listings.json}"
SEO_TITLE="${SEO_TITLE:-Best {category} in {city} | Directory}"
SEO_DESC="${SEO_DESC:-Find top-rated {category} in {city}. Ratings, reviews, contact info.}"

if [ ! -f "$LISTINGS_FILE" ]; then
  echo "Error: $LISTINGS_FILE not found" >&2
  exit 1
fi

echo "=== Step 1: Create or get category '$CAT_SLUG' ==="
# Idempotent-ish: try to create; if it 409s, assume it exists already.
CREATE_RESP=$(curl -sS -w "\n%{http_code}" -X POST \
  "$API/dashboard/projects/$PID/content/directory/categories" \
  -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg n "$CAT_NAME" --arg s "$CAT_SLUG" \
    --arg t "$SEO_TITLE" --arg d "$SEO_DESC" \
    '{name: $n, slug: $s, seo_title_template: $t, seo_description_template: $d}')")
HTTP_CODE=$(echo "$CREATE_RESP" | tail -n1)
if [ "$HTTP_CODE" = "201" ]; then
  echo "  Created new category"
elif [ "$HTTP_CODE" = "409" ]; then
  echo "  Category already exists — continuing"
else
  echo "$CREATE_RESP" | head -n-1
  echo "  Unexpected HTTP $HTTP_CODE creating category" >&2
  exit 1
fi

echo "=== Step 2: Bulk-upsert listings ==="
LISTINGS_COUNT=$(jq 'length' "$LISTINGS_FILE")
if [ "$LISTINGS_COUNT" -gt 5000 ]; then
  echo "  ⚠ $LISTINGS_COUNT listings exceeds 5000 per-call cap. Split the file." >&2
  exit 1
fi
echo "  Uploading $LISTINGS_COUNT listings..."

BULK_RESP=$(curl -sS -X POST \
  "$API/dashboard/projects/$PID/content/directory/categories/$CAT_SLUG/listings/bulk" \
  -H "$AUTH" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --argjson l "$(cat "$LISTINGS_FILE")" '{listings: $l}')")

echo "$BULK_RESP" | python3 -m json.tool

UPSERTED=$(echo "$BULK_RESP" | jq '.upserted // 0')
FAILED=$(echo "$BULK_RESP" | jq '.failed // 0')
CITIES=$(echo "$BULK_RESP" | jq -r '.affected_cities // [] | length')

echo ""
echo "=== Summary ==="
echo "  Upserted: $UPSERTED"
echo "  Failed:   $FAILED"
echo "  Cities:   $CITIES"
echo ""
echo "  Category page:  /directory/$CAT_SLUG"
echo "  First city:     /directory/$CAT_SLUG/$(echo "$BULK_RESP" | jq -r '.affected_cities[0] // ""')"
echo ""
echo "  Verify: curl -s \"https://spideriq.ai/api/v1/content/directory/categories/$CAT_SLUG\" -H \"X-Content-Domain: <your-domain>\""
