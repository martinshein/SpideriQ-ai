#!/bin/bash
# SpiderPublish — apply a starter site template to bootstrap a fresh tenant (Phase B, 2026-04-25)
#
# Walks the gated dry_run → confirm flow:
#   1. POST .../apply-site-template/{slug}?dry_run=true → grab confirm_token + preview
#   2. Show what will be cloned (pages, nav, settings keys)
#   3. POST .../apply-site-template/{slug}?confirm_token=cft_... → actually clone
#   4. Pretty-print pages_created / nav_updated / settings_applied
#
# Cloned pages land as status='draft'. Publishing each page + final deploy
# are separate steps — see CLAUDE.md "Build a Site" section.
#
# Usage:
#   TOKEN="..." PID="cli_xxx" SLUG="saas-landing-default" bash apply-template.sh
#
# Optional:
#   AUTO_CONFIRM=1   Skip the [y/N] prompt and apply immediately after dry_run
#   API_BASE         Override the API base URL (default: https://spideriq.ai)

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
PID="${PID:-${SPIDERIQ_PROJECT_ID:-}}"
SLUG="${SLUG:-}"
API_BASE="${API_BASE:-https://spideriq.ai}"
AUTO_CONFIRM="${AUTO_CONFIRM:-0}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${PID:?Set PID (your project_id from spideriq.json)}"
: "${SLUG:?Set SLUG — e.g. SLUG=saas-landing-default. Browse with: spideriq content templates:gallery}"

apply_url="$API_BASE/api/v1/dashboard/projects/$PID/content/templates/apply-site-template/$SLUG"

# ---------------------------------------------------------------------------
# Step 1 — dry_run preview
# ---------------------------------------------------------------------------
echo "→ Previewing apply for template '$SLUG'..."
preview_response=$(curl -sw "\n__STATUS__%{http_code}" \
  -X POST "$apply_url?dry_run=true" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

preview_status="${preview_response##*__STATUS__}"
preview_body="${preview_response%__STATUS__*}"

if [ "$preview_status" != "200" ]; then
  case "$preview_status" in
    404) echo "✗ Template '$SLUG' not found. Browse with: spideriq content templates:gallery" ;;
    401) echo "✗ Unauthorized — check your TOKEN / PAT (run: spideriq auth whoami)" ;;
    403) echo "✗ Forbidden — does PID match your spideriq.json project_id?" ;;
    *)   echo "✗ Unexpected response (status=$preview_status):"; echo "$preview_body" ;;
  esac
  exit 1
fi

# Parse the preview + extract the confirm_token.
confirm_token=$(printf '%s' "$preview_body" | python3 <<'PY'
import json, sys
p = json.load(sys.stdin)
prev = p.get("preview") or {}
print(f"\n  Template:           {p.get('template_slug') or p.get('slug') or '?'}")
pages = prev.get("pages_to_create") or []
print(f"  Pages to create:    {len(pages)}")
for pg in pages:
    print(f"    - {pg.get('slug', '?'):24s}  ({pg.get('title', '?')})")
locs = prev.get("nav_locations") or []
print(f"  Nav locations:      {', '.join(locs) if locs else '(none)'}")
keys = prev.get("settings_keys_to_apply") or []
print(f"  Settings keys:      {len(keys)}")
for k in keys:
    print(f"    - {k}")
print(f"  Confirm token:      {p.get('confirm_token', '?')}")
print(f"  Expires at:         {p.get('expires_at', '?')}", file=sys.stderr)
print()
# Stream the token to stdout so the shell can capture it.
print(f"__TOKEN__{p.get('confirm_token', '')}")
PY
)

token=$(printf '%s' "$confirm_token" | grep '^__TOKEN__' | sed 's/^__TOKEN__//')
if [ -z "$token" ]; then
  echo "✗ Failed to parse confirm_token from dry_run response."
  echo "$preview_body"
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 2 — confirm
# ---------------------------------------------------------------------------
if [ "$AUTO_CONFIRM" != "1" ]; then
  printf '\nApply this template? Cloned pages will land as status=draft. [y/N] '
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted (confirm_token will expire on its own)."; exit 0 ;;
  esac
fi

echo "→ Applying with confirm_token..."
apply_response=$(curl -sw "\n__STATUS__%{http_code}" \
  -X POST "$apply_url?confirm_token=$token" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

apply_status="${apply_response##*__STATUS__}"
apply_body="${apply_response%__STATUS__*}"

case "$apply_status" in
  200|201)
    printf '%s' "$apply_body" | python3 <<'PY'
import json, sys
r = json.load(sys.stdin)
created = r.get("pages_created") or []
nav     = r.get("nav_updated") or []
sett    = r.get("settings_applied") or []
print()
print("  ✓ Template applied")
print(f"    pages_created:    {len(created)}")
for p in created:
    print(f"      - {p.get('slug', '?'):24s}  status={p.get('status', '?')}  id={p.get('id', '?')}")
print(f"    nav_updated:      {', '.join(nav) if nav else '(none)'}")
print(f"    settings_applied: {len(sett)}")
for k in sett:
    print(f"      - {k}")
print()
print("  Next steps:")
print("    1. Review the new draft pages in the dashboard")
print("    2. Publish each one:  spideriq content pages:publish <page_id>")
print("    3. Deploy:            spideriq content deploy")
PY
    ;;
  409) echo "✗ Token already consumed (single-use). Re-run dry_run=true to issue a fresh one."; echo "$apply_body"; exit 1 ;;
  410) echo "✗ Token expired. Re-run dry_run=true to issue a fresh one."; echo "$apply_body"; exit 1 ;;
  *)   echo "✗ Apply failed (status=$apply_status):"; echo "$apply_body"; exit 1 ;;
esac
