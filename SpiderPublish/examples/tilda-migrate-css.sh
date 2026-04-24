#!/bin/bash
# SpiderPublish — opt-in auto-extract CSS for Tilda / Webflow / Lovable imports (2026-04-24)
#
# Tilda and Webflow exports embed <style> blocks inside every HTML section. The
# default SpiderPublish contract REJECTS inline <style> in `html_template` with a
# 400 (CSS must live in the `css` field — Shadow DOM ignores inline styles). For
# bulk imports of legacy HTML, pass `auto_extract_css: true` and the server will
# move every <style>...</style> block into the `css` field before validation.
#
# Off by default so hand-authored components can't accidentally double-include CSS.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" bash tilda-migrate-css.sh < section.html
#   # or supply via env:
#   TOKEN="..." PID="cli_xxx" HTML_FILE=./section.html bash tilda-migrate-css.sh

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
HTML_FILE="${HTML_FILE:-/dev/stdin}"
SLUG="${SLUG:-legacy-section-$(date +%s)}"
NAME="${NAME:-Legacy Section}"
CATEGORY="${CATEGORY:-custom}"
API_BASE="${API_BASE:-https://spideriq.ai}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID}"

url="$API_BASE/api/v1/dashboard/projects/$PID/content/components"

body=$(python3 -c "
import json, sys
html = open(sys.argv[1]).read() if sys.argv[1] != '/dev/stdin' else sys.stdin.read()
print(json.dumps({
    'slug': sys.argv[2],
    'name': sys.argv[3],
    'category': sys.argv[4],
    'html_template': html,
    'auto_extract_css': True
}))
" "$HTML_FILE" "$SLUG" "$NAME" "$CATEGORY")

echo "Creating component '$SLUG' with auto_extract_css=true..."
response=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$body" "$url")

echo "$response" | python3 <<'PY'
import json, sys
r = json.load(sys.stdin)
if 'id' in r:
    print(f"✓ Created: {r['slug']}@{r['version']} (id={r['id']})")
    print(f"  html_template length: {len(r.get('html_template', ''))} bytes")
    print(f"  css length:           {len(r.get('css', '') or '')} bytes")
    warnings = r.get('warnings') or []
    if warnings:
        print("  warnings:")
        for w in warnings:
            print(f"    - {w}")
    print()
    print("Next:  content_publish_component to take it off draft.")
else:
    print("✗ Error:")
    print(json.dumps(r, indent=2))
    sys.exit(1)
PY
