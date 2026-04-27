#!/bin/bash
# SpiderPublish — insert a marketplace section into an existing page (2026-04-26, Phase C)
#
# Phase 11+12 gated: the script does the dry_run → preview → confirm round-trip
# in one call. The first request returns a confirm_token and a preview envelope;
# the second consumes the token and performs the mutation. Aborts cleanly on
# 4xx/5xx and never inserts on a partial response.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" PAGE_ID="<uuid>" \
#     COMPONENT_SLUG="logo-cloud" \
#     bash insert-section.sh
#
#   # Position before/after a specific block:
#   TOKEN="..." PID="cli_xxx" PAGE_ID="<uuid>" \
#     COMPONENT_SLUG="cta-banner" \
#     POSITION="after" ANCHOR_BLOCK_ID="<block-uuid>" \
#     bash insert-section.sh
#
#   # Pass props as JSON:
#   TOKEN="..." PID="cli_xxx" PAGE_ID="<uuid>" \
#     COMPONENT_SLUG="hero-headline" \
#     PROPS='{"headline":"Ship faster","cta_text":"Start free","cta_path":"/signup"}' \
#     bash insert-section.sh
#
# Discover available component slugs (no auth needed):
#   curl https://spideriq.ai/api/v1/content/marketplace/components | jq '.components[].slug'

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
PAGE_ID="${PAGE_ID:-}"
COMPONENT_SLUG="${COMPONENT_SLUG:-}"
COMPONENT_VERSION="${COMPONENT_VERSION:-}"
POSITION="${POSITION:-end}"
ANCHOR_BLOCK_ID="${ANCHOR_BLOCK_ID:-}"
PROPS="${PROPS:-{\}}"
API_BASE="${API_BASE:-https://spideriq.ai}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID (your project_id from spideriq.json)}"
: "${PAGE_ID:?Set PAGE_ID — list pages via 'spideriq content pages'}"
: "${COMPONENT_SLUG:?Set COMPONENT_SLUG — browse via /api/v1/content/marketplace/components}"

# ---- build request body ----
body=$(jq -nc \
  --arg slug "$COMPONENT_SLUG" \
  --arg version "$COMPONENT_VERSION" \
  --arg position "$POSITION" \
  --arg anchor "$ANCHOR_BLOCK_ID" \
  --argjson props "$PROPS" \
  '{
    component_slug: $slug,
    props: $props,
    position: ($position | if test("^[0-9]+$") then tonumber else . end)
  }
  + (if $version != ""     then {component_version: $version} else {} end)
  + (if $anchor != ""      then {anchor_block_id: $anchor}    else {} end)
  ')

url="$API_BASE/api/v1/dashboard/projects/$PID/content/pages/$PAGE_ID/insert-section"

echo "→ Step 1: dry-run preview"
preview=$(curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$url?dry_run=true" -d "$body")
echo "$preview" | jq .

token=$(echo "$preview" | jq -r '.confirm_token // empty')
if [ -z "$token" ]; then
  echo "❌ No confirm_token in preview — aborting." >&2
  exit 2
fi

echo ""
echo "→ Step 2: confirm + apply"
result=$(curl -fsS -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$url?confirm_token=$token" -d "$body")
echo "$result" | jq .
