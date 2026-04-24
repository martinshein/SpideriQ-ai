#!/bin/bash
# SpiderPublish — check your PAT + project binding (2026-04-24)
#
# Run this FIRST on any new session, before any destructive operation. Tells you
# which tenant your PAT is bound to, which scopes it carries, and when it expires.
# Distinguishes expired PATs from invalid ones via the structured 401 response.
#
# Usage:
#   TOKEN="$SPIDERIQ_PAT" bash check-auth.sh
#   # or
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" bash check-auth.sh
#
# Equivalent CLI path (cleaner for humans):
#   npx @spideriq/cli auth whoami

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
API_BASE="${API_BASE:-https://spideriq.ai}"

if [[ -z "$TOKEN" ]]; then
  echo "Set TOKEN or SPIDERIQ_PAT env var."
  echo "  - For a PAT: export SPIDERIQ_PAT=\"spideriq_pat_xxx\""
  echo "  - For legacy bearer: export TOKEN=\"cli_xxx:sk_xxx:secret_xxx\""
  exit 1
fi

# Capture status + body separately so we can branch on error codes cleanly.
response=$(curl -s -w "\n__STATUS__%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  "$API_BASE/api/v1/auth/whoami")

status="${response##*__STATUS__}"
body="${response%__STATUS__*}"

case "$status" in
  200)
    echo "✓ Authenticated"
    echo "$body" | python3 -m json.tool
    ;;
  401)
    error_code=$(echo "$body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('detail',{}).get('error','unknown'))" 2>/dev/null || echo "unknown")
    if [[ "$error_code" == "token_expired" ]]; then
      echo "✗ Your PAT has expired."
      echo "$body" | python3 -m json.tool
      echo ""
      echo "Regenerate:  npx @spideriq/cli auth request --email <admin-email>"
      echo "Or visit:    https://app.spideriq.ai/settings/tokens"
    elif [[ "$error_code" == "token_invalid" ]]; then
      echo "✗ Your PAT is unknown or malformed."
      echo "$body" | python3 -m json.tool
      echo ""
      echo "Check ~/.spideriq/credentials.json, or re-run: npx @spideriq/cli auth whoami"
    else
      echo "✗ Authentication failed (status=$status)"
      echo "$body"
    fi
    exit 1
    ;;
  *)
    echo "✗ Unexpected response (status=$status)"
    echo "$body"
    exit 1
    ;;
esac
