#!/bin/bash
# SpiderPublish — Bulk local → SpiderMedia upload (T2-D, v0.9.4+)
#
# What this does:
#   Uploads every file in a local directory to SpiderMedia in one HTTP call.
#   Scroll-sequence folders auto-enable preserve_filename so CDN keys match
#   your {base_url, pattern, count} exactly.
#
# Why use this instead of /media/files/import-url + pinggy tunnel:
#   - No public URL needed for local files → no tunnel → no HTML interstitials
#     silently saved as .webp → no black frames in your scroll-sequence hero
#   - Server enforces weight policy per-folder:
#       scroll-sequences/*     → 500 KB per file, 20 MB per batch (hard)
#       general                → 20 MB per file, 500 MB per batch
#       video/* MIME           → 500 MB per file (raw source for extract_frames)
#   - Returns 400 with suggested_action if you bust the ceiling — no silent
#     half-upload
#
# Preferred path — MCP/CLI (handles Sharp auto-optimize for scroll-sequences):
#   spideriq media upload ./frames/ --folder scroll-sequences/hero
#
# This shell script is the curl fallback for runtimes without Node. It does
# NOT run Sharp — if your frames are too big, pre-optimize them first with
# `cwebp -q 75 -resize 1920 0 -o frame.webp src.jpg` or similar.
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" PID="cli_xxx" \
#   DIR="./frames" FOLDER="scroll-sequences/hero" \
#   bash bulk-media-upload.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"
PID="${PID:?Set PID=cli_xxx (your short project id)}"
DIR="${DIR:?Set DIR to a local directory containing files to upload}"
FOLDER="${FOLDER:-uploads}"
PRESERVE="${PRESERVE_FILENAME:-auto}"   # auto | true | false

if [ ! -d "$DIR" ]; then
  echo "Error: $DIR is not a directory" >&2
  exit 1
fi

# Auto-enable preserve_filename for scroll-sequences/* (matches MCP default)
IS_SSEQ=false
case "$FOLDER" in
  scroll-sequences|scroll-sequences/*) IS_SSEQ=true ;;
esac
if [ "$PRESERVE" = "auto" ]; then
  [ "$IS_SSEQ" = true ] && PRESERVE=true || PRESERVE=false
fi

echo "=== Bulk upload: $DIR → $FOLDER (preserve_filename=$PRESERVE, scroll-sequence=$IS_SSEQ) ==="

# Build the multipart form: one -F files=@... per file in DIR.
# Find restricted to the SpiderMedia allowlist (webp/jpg/jpeg/png/gif/pdf/mp4/webm/mov).
FILES_ARGS=()
COUNT=0
TOTAL_BYTES=0
while IFS= read -r -d '' f; do
  FILES_ARGS+=("-F" "files=@${f}")
  COUNT=$((COUNT + 1))
  SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f")
  TOTAL_BYTES=$((TOTAL_BYTES + SIZE))
done < <(find "$DIR" -type f \( \
  -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
  -o -iname "*.gif" -o -iname "*.pdf" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mov" \
  \) -print0)

if [ $COUNT -eq 0 ]; then
  echo "No allowed-extension files found under $DIR" >&2
  exit 1
fi

echo "  Found $COUNT files (~$((TOTAL_BYTES / 1024)) KB total)"

# Soft preflight warning — server enforces the hard ceiling anyway.
if [ "$IS_SSEQ" = true ] && [ $TOTAL_BYTES -gt 10485760 ]; then
  echo "  ⚠ Batch is $((TOTAL_BYTES / 1048576)) MB — scroll-sequence soft warning is 10 MB."
  echo "  ⚠ If you hit the 20 MB hard ceiling, pre-optimize with cwebp or use the MCP tool's auto_optimize."
fi

echo "=== POST /dashboard/projects/$PID/content/media/upload-batch ==="
curl -sS -X POST "$API/dashboard/projects/$PID/content/media/upload-batch" \
  -H "$AUTH" \
  -F "folder=$FOLDER" \
  -F "preserve_filename=$PRESERVE" \
  -F "is_scroll_sequence=$IS_SSEQ" \
  "${FILES_ARGS[@]}" | python3 -m json.tool
