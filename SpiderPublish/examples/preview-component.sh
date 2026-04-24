#!/bin/bash
# SpiderPublish — preview a single component in isolation (2026-04-24)
#
# Before a full-site deploy, render ONE component in an iframe for a pixel-accurate
# Shadow DOM / layout check. ~100-300ms vs 60-90s for content_deploy_site_preview.
#
# Returns the Shadow-DOM-wrapped HTML + CSS + JS + merged_props. Drop `html`
# into <iframe srcdoc="..."> and you have a standalone preview page.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" COMPONENT_ID="<uuid>" PROPS='{"headline":"Hi"}' bash preview-component.sh
#
# Tier 4 framework components (react/vue/svelte) return the custom element tag
# (e.g. `<spideriq-app-hero>`) + the bundle_url — load the bundle_url as a
# <script type="module"> in the iframe head to mount.

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
COMPONENT_ID="${COMPONENT_ID:-}"
PROPS="${PROPS:-{}}"
VIEWPORT="${VIEWPORT:-desktop}"  # desktop | tablet | mobile
API_BASE="${API_BASE:-https://spideriq.ai}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID}"
: "${COMPONENT_ID:?Set COMPONENT_ID (the component's UUID — see content_list_components)}"

url="$API_BASE/api/v1/dashboard/projects/$PID/content/components/$COMPONENT_ID/preview"

body=$(python3 -c "import json,sys; print(json.dumps({'props': json.loads(sys.argv[1]), 'viewport': sys.argv[2]}))" "$PROPS" "$VIEWPORT")

echo "Previewing component $COMPONENT_ID with viewport=$VIEWPORT..."
response=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body" "$url")

echo "$response" | python3 <<'PY'
import json, sys
r = json.load(sys.stdin)
print(f"slug:                {r['slug']}@{r['version']}")
print(f"custom_element_tag:  {r['custom_element_tag']}")
if r.get('framework'):
    print(f"framework:           {r['framework']}  (Tier 4)")
    print(f"bundle_url:          {r.get('bundle_url','(pending build)')}")
print(f"merged_props:        {json.dumps(r['merged_props'])}")
print(f"html (truncated):    {r['html'][:160]}...")
print()
print("To view in a browser, write the html/css/js into a local file:")
print("  <html><head><style>" + (r.get('css') or '').replace('<','&lt;') + "</style></head>")
print("  <body>" + r['html'][:80] + "... <script>" + (r.get('js') or 'null')[:80] + "</script></body></html>")
PY
