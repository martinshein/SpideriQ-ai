# SpiderPublish — AI Agent Context

This project uses SpiderPublish (SpiderIQ's content platform) to build, manage, and deploy websites.

## MCP Setup

The `.mcp.json` in this project connects to SpiderIQ. After IDE restart, you have 146+ tools.

## Authentication

Run `npx @spideriq/cli auth whoami --registry https://npm.spideriq.ai` to check auth status.
If not authenticated: `npx @spideriq/cli auth request --email admin@company.com --registry https://npm.spideriq.ai`

## Build a Site

1. **Read the reference first:** Use `template_get_help` MCP tool (or `GET /api/v1/content/help?format=yaml`)
2. **Settings:** `PATCH /api/v1/dashboard/content/settings` — site_name, primary_color, logo
3. **Navigation:** `PUT /api/v1/dashboard/content/navigation/header` — menu items
4. **Pages:** `POST /api/v1/dashboard/content/pages` — create with blocks
5. **Publish:** `POST /api/v1/dashboard/content/pages/{id}/publish`
6. **Theme:** `POST /api/v1/dashboard/templates/apply-theme` — apply "default"
7. **Deploy:** `POST /api/v1/dashboard/content/deploy` — live in ~2-5 seconds

## Key Rules

- **Always read `/content/help` first** — it has every block type, Liquid filter, and template variable
- **Use `format=yaml`** on GET requests — saves 40-76% tokens
- **Block types:** hero, features_grid, cta_section, testimonials, pricing_table, faq, stats_bar, rich_text, image, video_embed, code_example, logo_cloud, comparison_table, spacer, component
- **Page templates:** default, landing, feature, legal, dynamic_landing
- **Components use Shadow DOM** — CSS is automatically isolated, use `var(--primary)` for theme colors, never Tailwind
- **Public endpoints** (GET /content/*) need no auth — use `X-Content-Domain` header
- **Dashboard endpoints** (POST/PATCH /dashboard/content/*) need Bearer auth

## Dynamic Landing Pages

For personalized outreach pages:
- Template: `dynamic_landing`
- URL: `/lp/{page_slug}/{salesperson}/{google_place_id}`
- Variables: `{{ lead.name }}`, `{{ lead.city }}`, `{{ salesperson.name }}`
- Lead data fetched automatically from IDAP by Place ID

## Uploading Images

```bash
# Import from URL (recommended)
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }

# Returns: { "url": "https://media.cdn.spideriq.ai/..." }
# Use in blocks: { "type": "image", "data": { "url": "https://media.cdn.spideriq.ai/..." } }
```

## IDAP Data Access

Read CRM data (businesses, emails, contacts, phones):
- `GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml`
- `GET /api/v1/idap/businesses/{id}?include=emails,phones,domains,contacts`
- `GET /api/v1/idap/businesses/resolve?place_id={google_place_id}`
- `POST /api/v1/idap/businesses/{id}/flags` — flag leads as qualified/contacted

## Templates

Ready-to-submit payloads are in the `templates/` directory:
- `templates/homepage.json` — company homepage
- `templates/blog-setup.json` — blog with author + posts
- `templates/dynamic-landing.json` — personalized outreach page

Submit any template: read the JSON, then `POST /api/v1/dashboard/content/pages` with the payload.

## API Base

- Production: `https://spideriq.ai/api/v1`
- Docs: `https://docs.spideriq.ai`
- Site Builder Docs: `https://docs.spideriq.ai/site-builder/overview`
- Health: `GET /api/v1/system/health`
- Full Reference: `GET /api/v1/content/help` (~2,867 tokens YAML)

## GitHub

- Public repo: https://github.com/martinshein/SpideriQ-ai/tree/main/SpiderPublish
