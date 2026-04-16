#!/usr/bin/env bash
# Personalized Landing Page — end-to-end example for SpiderPublish
#
# Creates a dynamic-landing page that uses ~15 flat email-marketing-style
# merge tags, publishes it, deploys it to Cloudflare's edge, previews it
# against the built-in Mario's Pizzeria fixture, then against a real lead.
#
# Prerequisites:
#   - Node 20+, npm, curl, jq
#   - A SpiderIQ PAT in ~/.spideriq/credentials.json
#     (obtain via: npx spideriq auth request --email admin@your-company.com)
#   - You ran `npx spideriq use <project_id>` in this directory
#     (writes spideriq.json — session binding for Phase 11+12 URL scoping)
#
# Usage:
#   bash examples/personalized-landing.sh
#
# Real URL pattern after deploy:
#   https://<your-domain>/lp/<slug>/<google-place-id>
#   e.g. https://mail.spideriq.ai/lp/proposal/ChIJd8BlQ2BZwokRAFUEcm_qrcA

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────
SLUG="proposal"                         # URL slug for /lp/${SLUG}/…
TITLE="Proposal for {{ company_name }}"  # shown in <title>
# Your primary domain (for the preview links printed at the end).
# If you leave this empty, the script reads content_domains via the API.
PRIMARY_DOMAIN="${PRIMARY_DOMAIN:-}"

# Optional: set a real Google Place ID to test the live personalization.
# Leave empty to just test the /demo fixture.
REAL_PLACE_ID="${REAL_PLACE_ID:-}"

# ─── 0. Pre-flight ────────────────────────────────────────────────────────
for cmd in npx curl jq; do
  command -v $cmd > /dev/null || { echo "missing: $cmd"; exit 1; }
done

if [ ! -f spideriq.json ]; then
  echo "❌ No spideriq.json in cwd. Run: npx spideriq use <project_id>"
  exit 1
fi

echo "==> Project binding:"
cat spideriq.json
echo

# ─── 1. Fetch the merge-tag vocabulary (optional, for reference) ─────────
echo "==> Fetching merge-tag vocabulary (3.8k tokens, no auth required)…"
npx -y @spideriq/cli@latest content variables --format md > /tmp/merge-tags-ref.md \
  2>/dev/null || true
[ -f /tmp/merge-tags-ref.md ] && \
  echo "    Reference saved to /tmp/merge-tags-ref.md ($(wc -l < /tmp/merge-tags-ref.md) lines)"
echo

# ─── 2. Build the page blocks ────────────────────────────────────────────
cat > /tmp/mt-page.json <<'PAGE_JSON'
{
  "slug": "__SLUG__",
  "title": "Proposal for {{ company_name }}",
  "description": "Personalized proposal — {{ company_name }} in {{ city }}",
  "template": "dynamic_landing",
  "blocks": [
    {
      "type": "rich_text",
      "props": {
        "html": "<header class='hero'><img src='{{ logo }}' alt='{{ company_name }} logo'><div><h1>Hey {{ firstname }} at {{ company_name }},</h1><p>{{ industry }} · {{ team_size }} people · founded {{ founded }}</p></div></header>"
      }
    },
    {
      "type": "rich_text",
      "props": {
        "html": "<section class='social-proof'><h2>{{ rating }}★ across {{ reviews_count }} reviews</h2><p>{{ company_name }} is already the top {{ industry | downcase }} in {{ city }}, {{ country_code }}.</p></section>"
      }
    },
    {
      "type": "rich_text",
      "props": {
        "html": "<section class='pains'><h3>Three things we noticed about how {{ company_name }} operates:</h3><ul>{% for pain in pain_points %}<li>{{ pain }}</li>{% endfor %}</ul></section>"
      }
    },
    {
      "type": "rich_text",
      "props": {
        "html": "<section class='team'><h3>People on record:</h3><ul>{% for contact in contacts %}<li>{% if contact.photo %}<img src='{{ contact.photo }}' width='32'>{% endif %}<strong>{{ contact.full_name }}</strong> — {{ contact.position }}{% if contact.linkedin_url %}&nbsp;· <a href='{{ contact.linkedin_url }}'>LinkedIn</a>{% endif %}</li>{% endfor %}</ul></section>"
      }
    },
    {
      "type": "cta_section",
      "props": {
        "headline": "Ready to talk, {{ firstname }}?",
        "cta_primary": {
          "label": "Email us",
          "url": "mailto:{{ email }}"
        }
      }
    }
  ]
}
PAGE_JSON

# Inject slug
sed -i "s/__SLUG__/${SLUG}/" /tmp/mt-page.json

# ─── 3. Create / update + publish via CLI ────────────────────────────────
echo "==> Creating page (slug=${SLUG}, template=dynamic_landing)…"
PAGE_JSON_CONTENT=$(cat /tmp/mt-page.json)
CREATE_OUTPUT=$(npx -y @spideriq/cli@latest content pages create \
  --slug "${SLUG}" \
  --template dynamic_landing \
  --title "${TITLE}" \
  --blocks "$(echo "${PAGE_JSON_CONTENT}" | jq -c .blocks)" \
  --format json 2>&1) || {
    echo "    page likely already exists — updating via API..."
    # If `pages create` fails (page exists), the CLI returns non-zero — continue anyway.
  }
echo "    created: ${CREATE_OUTPUT}" | head -3

echo "==> Publishing page…"
npx -y @spideriq/cli@latest content pages publish "${SLUG}" --yolo 2>&1 | tail -3

echo
echo "==> Deploying site to CF edge (preview → confirm flow)…"
# Use --yolo to skip the interactive preview prompt.
DEPLOY_OUTPUT=$(npx -y @spideriq/cli@latest content deploy --yolo 2>&1)
echo "${DEPLOY_OUTPUT}" | tail -5

# ─── 4. Print preview URLs ────────────────────────────────────────────────
if [ -z "${PRIMARY_DOMAIN}" ]; then
  # Try to discover from settings.
  PRIMARY_DOMAIN=$(npx -y @spideriq/cli@latest content settings --format json 2>/dev/null \
    | jq -r '.primary_domain // empty' || true)
fi

echo
echo "═══════════════════════════════════════════════════════════════════"
echo "✓ Deployed!"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "Preview with the built-in Mario's Pizzeria fixture (no scraping needed):"
echo "  https://${PRIMARY_DOMAIN:-<your-domain>}/lp/${SLUG}/demo"
echo
if [ -n "${REAL_PLACE_ID}" ]; then
  echo "Real URL against ${REAL_PLACE_ID}:"
  echo "  https://${PRIMARY_DOMAIN:-<your-domain>}/lp/${SLUG}/${REAL_PLACE_ID}"
else
  echo "Real URLs per lead — grab a Place ID from any SpiderMaps run:"
  echo "  https://${PRIMARY_DOMAIN:-<your-domain>}/lp/${SLUG}/<google-place-id>"
fi
echo
echo "Full merge-tag reference: https://docs.spideriq.ai/site-builder/merge-tags/"
