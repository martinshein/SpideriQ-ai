#!/usr/bin/env bash
#
# Marketplace V2 — search by intent + insert into a page.
#
# Phase G (2026-05-05) shipped 6 new agent-discovery tools. This script
# walks the canonical "I want a calm cinematic background for the homepage
# hero" flow end-to-end:
#
#   1. marketplace_search → find a calm bg-video
#   2. content_list_pages → look up the homepage page_id
#   3. content_insert_section dry_run → preview the block insertion
#   4. content_insert_section confirm → commit
#
# Pairs with: skills/recipes/marketplace-search-and-insert/
#
# Auth: requires a PAT — run `npx @spideriq/cli@latest auth request -e <email>`
# first, then `spideriq use <project>` to bind this directory to a project.
#
# Usage:
#   ./marketplace-search-and-insert.sh                  # uses 'home' as the target page slug
#   ./marketplace-search-and-insert.sh about            # custom target slug
#
# All MCP tool calls in this script can be expressed identically via the
# CLI (`npx spideriq marketplace search --mood calm ...`) or via MCP from
# Cursor / Claude Desktop / Antigravity / Windsurf — see
# skills/recipes/marketplace-search-and-insert/SKILL.md for the MCP shape.

set -euo pipefail

API_URL="${SPIDERIQ_API_URL:-https://spideriq.ai}"
TARGET_SLUG="${1:-home}"

# ─── 0. Read PAT from ~/.spideriq/credentials.json ─────────────────────────
TOKEN_FILE="${HOME}/.spideriq/credentials.json"
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Not authenticated. Run: npx @spideriq/cli@latest auth request -e <admin-email>"
  exit 1
fi
TOKEN=$(python3 -c "import json,sys; d=json.load(open('${TOKEN_FILE}')); ws=d.get('default') or next(iter(d.values())); print(ws.get('token',''))")
if [ -z "$TOKEN" ]; then
  echo "No token found in ${TOKEN_FILE}"
  exit 1
fi
echo "✓ token loaded (${TOKEN:0:14}…${TOKEN: -4})"

# ─── 1. Search the marketplace by intent ───────────────────────────────────
echo
echo "1. marketplace_search: mood=calm, asset_types=[bg_video], limit=5"
SEARCH_JSON=$(curl -sS \
  "${API_URL}/api/v1/content/marketplace/search?mood=calm&asset_types=bg_video&limit=5" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$SEARCH_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'   total matches: {d.get(\"total\", 0)}')
for r in d.get('results', [])[:3]:
    print(f'   ✓ {r[\"asset_type\"]:14s} {r[\"slug\"]:30s} mood={r.get(\"mood\")}')
"

CHOSEN_SLUG=$(echo "$SEARCH_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
results = [r for r in d.get('results', []) if r.get('asset_type') == 'bg_video']
print(results[0]['slug'] if results else '')
")
if [ -z "$CHOSEN_SLUG" ]; then
  echo "No matching bg-videos. Loosen the filter."
  exit 1
fi
echo "   → chose: ${CHOSEN_SLUG}"

# ─── 2. Look up the target page ────────────────────────────────────────────
echo
echo "2. content_list_pages: find slug=${TARGET_SLUG}"
PAGE_ID=$(curl -sS "${API_URL}/api/v1/dashboard/content/pages" \
  -H "Authorization: Bearer ${TOKEN}" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
for p in d.get('pages', []) or d.get('items', []):
    if p.get('slug') == '${TARGET_SLUG}':
        print(p.get('id', ''))
        break
")
if [ -z "$PAGE_ID" ]; then
  echo "No page with slug='${TARGET_SLUG}' found. Create one first:"
  echo "   npx spideriq content pages new --slug ${TARGET_SLUG} --title '...'"
  exit 1
fi
echo "   → page_id: ${PAGE_ID}"

# ─── 3. Preview the insertion (dry_run) ────────────────────────────────────
echo
echo "3. content_insert_section dry_run=true"
PREVIEW_JSON=$(curl -sS -X POST \
  "${API_URL}/api/v1/dashboard/content/pages/${PAGE_ID}/insert-section?dry_run=true" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"component_slug\":\"sys-bg-video\",\"props\":{\"video_slug\":\"${CHOSEN_SLUG}\"},\"position\":\"start\"}")

CONFIRM_TOKEN=$(echo "$PREVIEW_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('confirm_token', ''))
")
if [ -z "$CONFIRM_TOKEN" ]; then
  echo "$PREVIEW_JSON"
  echo "Preview did not return a confirm_token — check the response above."
  exit 1
fi
echo "   → confirm_token: ${CONFIRM_TOKEN:0:18}…"

# ─── 4. Commit (confirm_token consumes preview) ────────────────────────────
echo
echo "4. content_insert_section confirm_token=…"
RESULT=$(curl -sS -X POST \
  "${API_URL}/api/v1/dashboard/content/pages/${PAGE_ID}/insert-section?confirm_token=${CONFIRM_TOKEN}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"component_slug\":\"sys-bg-video\",\"props\":{\"video_slug\":\"${CHOSEN_SLUG}\"},\"position\":\"start\"}")

echo "$RESULT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'   ✓ block inserted at index {d.get(\"insertion_index\")}, new_block_id={d.get(\"new_block_id\")[:8]}…')
print(f'   ✓ blocks_count: {d.get(\"blocks_count\")}')
"

echo
echo "Page is in DRAFT — call content_publish_page + content_deploy_site_production to push live."
