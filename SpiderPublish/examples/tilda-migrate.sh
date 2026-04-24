#!/bin/bash
# SpiderPublish — end-to-end Tilda → SpiderPublish port (2026-04-24)
#
# Proven path: SMS-Chemicals, Di-Atomic, Onyx Radiance. Ships one HTML section
# as a SpiderPublish component, then a page that references it. For bulk ports
# loop this script over every section directory.
#
# What this does (no tunnels, no manual CSS-inlining):
#   1. POST the HTML section as a component with auto_extract_css=true
#      → server moves inline <style> blocks into the `css` field automatically.
#   2. Publish the component (dry_run → confirm_token flow).
#   3. POST a page that uses it via a component block (canonical shape).
#   4. Publish the page.
#   5. (NOT done here) content_deploy_site_preview → content_deploy_site_production
#      for the final edge push — run that once all sections are in.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" bash tilda-migrate.sh < section.html
#   # Or supply env:
#   TOKEN="..." PID="cli_xxx" HTML_FILE=./home-hero.html SLUG="home-hero" CATEGORY="hero" bash tilda-migrate.sh

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
HTML_FILE="${HTML_FILE:-/dev/stdin}"
SLUG="${SLUG:-tilda-section-$(date +%s)}"
NAME="${NAME:-Ported Section}"
CATEGORY="${CATEGORY:-custom}"
PAGE_SLUG="${PAGE_SLUG:-home}"
PAGE_TITLE="${PAGE_TITLE:-Home}"
API_BASE="${API_BASE:-https://spideriq.ai}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID}"

API="$API_BASE/api/v1/dashboard/projects/$PID/content"
AUTH=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")

echo "=== 1. Create component '$SLUG' with auto_extract_css=true ==="
comp_body=$(python3 -c "
import json, sys
html = open(sys.argv[1]).read() if sys.argv[1] != '/dev/stdin' else sys.stdin.read()
print(json.dumps({
    'slug': sys.argv[2], 'name': sys.argv[3], 'category': sys.argv[4],
    'html_template': html, 'auto_extract_css': True
}))
" "$HTML_FILE" "$SLUG" "$NAME" "$CATEGORY")
comp=$(curl -s -X POST "${AUTH[@]}" -d "$comp_body" "$API/components")
comp_id=$(echo "$comp" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
comp_version=$(echo "$comp" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])")
echo "   → component_id=$comp_id version=$comp_version"
warnings=$(echo "$comp" | python3 -c "import json,sys; d=json.load(sys.stdin); [print('   ⚠ '+w) for w in (d.get('warnings') or [])]")

echo "=== 2. Publish component (dry_run → confirm_token) ==="
dry=$(curl -s -X POST "${AUTH[@]}" "$API/components/$comp_id/publish?dry_run=true")
token=$(echo "$dry" | python3 -c "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
curl -s -X POST "${AUTH[@]}" "$API/components/$comp_id/publish?confirm_token=$token" > /dev/null
echo "   → published"

echo "=== 3. Create page '$PAGE_SLUG' that uses the component ==="
# Flat slug regex: ^[a-z0-9][a-z0-9-]*$ — no / in slugs; the renderer's router only matches flat slugs.
page_body=$(python3 -c "
import json, sys
print(json.dumps({
    'slug': sys.argv[1], 'title': sys.argv[2], 'template': 'default',
    'blocks': [{
        'id': 'b1-' + sys.argv[3],
        'type': 'component',
        'component_slug': sys.argv[3],
        'component_version': sys.argv[4],
        'props': {}
    }]
}))
" "$PAGE_SLUG" "$PAGE_TITLE" "$SLUG" "$comp_version")
page=$(curl -s -X POST "${AUTH[@]}" -d "$page_body" "$API/pages")
page_id=$(echo "$page" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "   → page_id=$page_id"

echo "=== 4. Publish page (dry_run → confirm_token) ==="
dry=$(curl -s -X POST "${AUTH[@]}" "$API/pages/$page_id/publish?dry_run=true")
token=$(echo "$dry" | python3 -c "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
curl -s -X POST "${AUTH[@]}" "$API/pages/$page_id/publish?confirm_token=$token" > /dev/null
echo "   → published"

echo ""
echo "Done. Next: when all sections are imported, run a site deploy:"
echo "  content_deploy_site_preview() → review preview_url"
echo "  content_deploy_site_production(confirm_token=<from preview>) → live"
echo ""
echo "Tip: if this is a header/footer section, set category='header'|'footer' on the"
echo "component (step 1) — the renderer auto-suppresses the native chrome."
