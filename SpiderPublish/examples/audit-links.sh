#!/bin/bash
# SpiderPublish — audit internal links across pages + nav (2026-04-24)
#
# CLI alternative (preferred — @spideriq/cli@1.6.0+):
#
#     npx @spideriq/cli content audit-links            # pretty-print
#     npx @spideriq/cli content audit-links --json     # raw envelope
#
#   The CLI exits non-zero when broken links are present, so it slots into
#   CI / pre-push hooks without extra plumbing. The MCP tool is named
#   `content_audit_links` — same response shape, no required args.
#
# Raw HTTP path (this script — fallback for shells without Node):
#
# One GET validates every `/path` reference in every published page's blocks
# and every navigation menu against the published-page roster + active redirects.
#
# Returns:
#   {
#     "valid_count": 42,
#     "broken": [
#       {"path": "/old-page", "source": "page:home/block[2].cta_primary.url", "reason": "target_not_found"},
#       {"path": "/en/about",  "source": "navigation:header[1].url",           "reason": "target_not_found"}
#     ],
#     "proposed_redirects": [{"from": "/en/about", "to": "/about", "status_code": 301}],
#     "known_redirects": [...]
#   }
#
# `source` strings describe the exact tree position so you navigate straight to the fix.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" bash audit-links.sh
#
# Follow-up: create redirects for each proposed_redirect via content_create_redirect,
# or fix the link at its `source` via content_update_page / content_update_navigation.

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
API_BASE="${API_BASE:-https://spideriq.ai}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID (your project_id from spideriq.json) or run 'npx @spideriq/cli use <project>' first}"

url="$API_BASE/api/v1/dashboard/projects/$PID/content/audit/links"

echo "Auditing internal links for project $PID..."
response=$(curl -s -H "Authorization: Bearer $TOKEN" "$url")

echo "$response" | python3 <<'PY'
import json, sys
data = json.load(sys.stdin)
print(f"  ✓ {data['valid_count']} valid internal links")
print(f"  ✗ {len(data['broken'])} broken")
print(f"  → {len(data['proposed_redirects'])} proposed redirects")
print(f"  ⇄ {len(data['known_redirects'])} active redirects already in place")
if data['broken']:
    print("\nBroken links:")
    for b in data['broken']:
        print(f"  [{b['reason']}]  {b['path']}")
        print(f"      at {b['source']}")
if data['proposed_redirects']:
    print("\nProposed redirects (heuristic):")
    for r in data['proposed_redirects']:
        print(f"  {r['from']}  →  {r['to']}  ({r['status_code']})")
PY
