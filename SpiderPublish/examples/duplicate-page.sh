#!/bin/bash
# SpiderPublish — duplicate a page, post, doc, or block (2026-04-24)
#
# Cheap primitive: fork an existing page as a draft to use as a starting point.
# Auto-generated `{slug}-copy[-N]` slug + " (Copy)" title suffix; fresh UUIDs
# on every block; status='draft'. Pass new_slug to override.
#
# NOT gated by dry_run/confirm_token — duplicates create new rows rather than
# overwriting state, so no preview step is required.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" SOURCE_PAGE_ID="<uuid>" bash duplicate-page.sh
#   # or with explicit slug:
#   TOKEN="..." PID="cli_xxx" SOURCE_PAGE_ID="<uuid>" NEW_SLUG="holiday-edition" bash duplicate-page.sh

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
SOURCE_PAGE_ID="${SOURCE_PAGE_ID:-}"
NEW_SLUG="${NEW_SLUG:-}"
API_BASE="${API_BASE:-https://spideriq.ai}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID (your project_id from spideriq.json)}"
: "${SOURCE_PAGE_ID:?Set SOURCE_PAGE_ID — get it from `spideriq content pages`}"

url="$API_BASE/api/v1/dashboard/projects/$PID/content/pages/$SOURCE_PAGE_ID/duplicate"

body='{}'
if [ -n "$NEW_SLUG" ]; then
  body=$(printf '{"new_slug":"%s"}' "$NEW_SLUG")
fi

echo "Duplicating page $SOURCE_PAGE_ID..."
response=$(curl -sw "\n__STATUS__%{http_code}" \
  -X POST "$url" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body")

status="${response##*__STATUS__}"
body_text="${response%__STATUS__*}"

case "$status" in
  201)
    echo "$body_text" | python3 <<'PY'
import json, sys
p = json.load(sys.stdin)
print(f"  ✓ Created page id={p['id']}  slug={p['slug']}  status={p['status']}")
print(f"    title:  {p['title']}")
print(f"    blocks: {len(p.get('blocks', []))}")
print()
print("  Edit it:  spideriq content pages:get " + p['id'])
print("  Publish:  spideriq content pages:publish " + p['id'])
PY
    ;;
  404)
    echo "✗ Source page not found (or not in your tenant). Verify SOURCE_PAGE_ID."
    echo "$body_text"
    exit 1
    ;;
  409)
    echo "✗ Slug collision: '$NEW_SLUG' already exists in this tenant."
    echo "  Omit NEW_SLUG to auto-generate ('{original-slug}-copy', '-copy-2', ...)."
    exit 1
    ;;
  *)
    echo "✗ Unexpected response (status=$status):"
    echo "$body_text"
    exit 1
    ;;
esac
