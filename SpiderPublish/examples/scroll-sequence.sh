#!/bin/bash
# SpiderPublish — Scroll-sequence hero recipe (Phase 11+12 flow)
#
# What this does:
#   Takes a source video, extracts N frames via SpiderVideo, drops them into
#   a page using the global sys-scroll-sequence component, and deploys.
#
# Why use this instead of hardcoding frame URLs:
#   - sys-scroll-sequence handles canvas setup, GSAP wiring, and progressive
#     preloading — you don't build any of that yourself
#   - extract_frames produces predictable {base_url, pattern, count} output —
#     no need to tunnel local frames or manage 100+ URLs by hand
#   - Progressive preloader keeps the CDN happy — no rate-limit drops, no
#     "flashlight strobe" of black frames during scroll
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" PID="cli_xxx" \
#   VIDEO_URL="https://media.cdn.spideriq.ai/clients/.../source.mp4" \
#   bash scroll-sequence.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"
PID="${PID:?Set PID=cli_xxx (your short project id)}"
VIDEO_URL="${VIDEO_URL:?Set VIDEO_URL to a publicly-hosted mp4 (preferably on media.cdn.spideriq.ai)}"
FRAMES="${FRAMES:-120}"          # target frame count
SLUG="${SLUG:-scroll-hero}"      # page slug

json() { python3 -c "$1"; }

echo "=== Step 1: Submit extract_frames job ==="
JOB=$(curl -s -X POST "$API/jobs/spiderVideo/submit" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d "{
    \"payload\": {
      \"action\": \"extract_frames\",
      \"video_url\": \"$VIDEO_URL\",
      \"strategy\": \"target_frames\",
      \"target_frames\": $FRAMES,
      \"output_format\": \"webp\"
    }
  }")
JOB_ID=$(echo "$JOB" | json "import json,sys; print(json.load(sys.stdin)['job_id'])")
echo "  job: $JOB_ID"

echo "=== Step 2: Poll until completed (~30-90s for 120 frames) ==="
while true; do
  STATUS=$(curl -s "$API/jobs/$JOB_ID/status" -H "$AUTH" | json "import json,sys; print(json.load(sys.stdin)['status'])")
  echo "  status: $STATUS"
  [[ "$STATUS" == "completed" ]] && break
  [[ "$STATUS" == "failed" ]] && { echo "FAILED"; exit 1; }
  sleep 5
done

echo "=== Step 3: Extract manifest from job results ==="
RESULT=$(curl -s "$API/jobs/$JOB_ID/results" -H "$AUTH")
BASE_URL=$(echo "$RESULT" | json "import json,sys; print(json.load(sys.stdin)['data']['manifest']['base_url'])")
PATTERN=$(echo "$RESULT" | json "import json,sys; print(json.load(sys.stdin)['data']['manifest']['pattern'])")
COUNT=$(echo "$RESULT" | json "import json,sys; print(json.load(sys.stdin)['data']['manifest']['count'])")
echo "  base_url: $BASE_URL"
echo "  pattern:  $PATTERN"
echo "  count:    $COUNT"

echo "=== Step 4: Create page with sys-scroll-sequence block ==="
PAGE_ID=$(curl -s -X POST "$API/dashboard/projects/$PID/content/pages" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Scroll Hero\",
    \"slug\": \"$SLUG\",
    \"template\": \"default\",
    \"blocks\": [
      {
        \"type\": \"component\",
        \"component_slug\": \"sys-scroll-sequence\",
        \"props\": {
          \"base_url\": \"$BASE_URL\",
          \"pattern\": \"$PATTERN\",
          \"count\": $COUNT,
          \"scroll_distance_vh\": 400,
          \"preload_strategy\": \"progressive\"
        }
      }
    ]
  }" | json "import json,sys; print(json.load(sys.stdin)['id'])")
echo "  page: $PAGE_ID"

echo "=== Step 5: Publish page (preview + confirm) ==="
PREV=$(curl -s -X POST "$API/dashboard/projects/$PID/content/pages/$PAGE_ID/publish?dry_run=true" -H "$AUTH")
TOK=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
curl -s -X POST "$API/dashboard/projects/$PID/content/pages/$PAGE_ID/publish?confirm_token=$TOK" \
  -H "$AUTH" > /dev/null && echo "  published"

echo "=== Step 6: Deploy preview ==="
PREV=$(curl -s -X POST "$API/dashboard/projects/$PID/content/deploy/preview" -H "$AUTH")
PREVIEW_URL=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['preview_url'])")
DEPLOY_TOK=$(echo "$PREV" | json "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
echo "  preview: $PREVIEW_URL"
echo "  verify the scroll works, then press ENTER to promote to production (or Ctrl-C to abort)"
read -r

echo "=== Step 7: Deploy production ==="
curl -s -X POST "$API/dashboard/projects/$PID/content/deploy/production?confirm_token=$DEPLOY_TOK" \
  -H "$AUTH" | json "import json,sys; d=json.load(sys.stdin); print(f'  status: {d[\"status\"]}, version: {d.get(\"version_id\")}')"

echo
echo "Done. Visit /$SLUG on your primary domain."
