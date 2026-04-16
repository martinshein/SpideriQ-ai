# SpiderPublish

> AI-native headless CMS and site builder where pages pull live scraped data via IDAP — build, deploy, and personalize at scale through API, CLI, MCP and Native Skills in token-efficient YAML/MD format.

Build websites, blogs, landing pages, and personalized outreach pages — entirely through AI agents. No browser needed. Deploy to Cloudflare's edge in 2-5 seconds.

**Current versions:** `@spideriq/cli@0.8.3`, `@spideriq/mcp-publish@0.1.0`, `@spideriq/core@0.8.3` — **87 tools** (the atomic SpiderPublish slice: pages, posts, docs, templates, components, domains, media + shared auth/system). Prefer this over the 157-tool kitchen-sink `@spideriq/mcp` — some IDE/LLM stacks silently drop tool injections above ~128 tools, and every tool schema burns LLM context on every turn.

## Quick Start (2 minutes)

### 1. Copy files into your project

```bash
# Option A: Clone just this directory
npx degit martinshein/SpideriQ-ai/SpiderPublish my-site
cd my-site

# Option B: Copy manually
# Download .mcp.json + CLAUDE.md + spideriq.json.example from this directory into your project root
```

### 2. Authenticate

```bash
npx @spideriq/cli auth request --email admin@company.com
# wait for admin approval, then:
npx @spideriq/cli auth whoami
```

### 3. Bind this directory to a project (**MANDATORY** — Phase 11+12 Lock 3)

```bash
# See what's accessible
npx @spideriq/cli use --list

# Bind — writes ./spideriq.json (commit it!)
npx @spideriq/cli use <project>   # short id cli_xxx, brand slug, or company name
```

From this point every dashboard call the CLI/MCP makes auto-rewrites to `/api/v1/dashboard/projects/{project_id}/...` and destructive operations go through a preview → confirm flow. Skip this step and your calls fall back to legacy URLs stamped `Deprecation: true` / `Sunset: 2026-05-14` — they work for now but will stop after that date.

### 4. Ask your AI agent to build

Open your project in Claude Code, Cursor, VS Code, Windsurf, or Google Antigravity. The MCP server connects automatically. Ask:

> "Build me a landing page for a SaaS product with hero, features grid, testimonials, and pricing table. Then preview the deploy."

Your agent has 155 tools available and full context from CLAUDE.md. When it calls destructive tools (`content_publish_page`, `content_deploy_site_preview`, etc.) it gets a preview envelope first — review before confirming.

**Customizing site chrome?** v0.8.2 added 3 tools specifically for this:

```
content_get_section_source({section: "footer"})    # read current Liquid
content_override_section({section, liquid})         # upload a replacement
content_apply_layout_preset({preset: "blank"})      # strip chrome entirely
```

No JavaScript Shadow-DOM-escape hacks needed. See CLAUDE.md for the full workflow.

**Want to make the site light instead of dark?** One call:

```
content_update_settings({
  surface_color:          "#ffffff",
  surface_elevated_color: "#f5f5f5",
  subtle_color:           "#e5e5e5",
  body_text_color:        "#18181b",
  heading_color:          "#0a0a0a"
})
```

The default palette is dark ("Developer Noir"). `primary_color` is the ACCENT only — use the surface fields for the page palette.

---

## What's in This Directory

```
SpiderPublish/
├── .mcp.json                          # MCP server config (drop into project root)
├── CLAUDE.md                          # AI agent context (drop into project root)
├── AGENTS.md                          # Complete integration guide
├── LEARNINGS.md                       # Gotchas & best practices (including Phase 11+12)
├── spideriq.json.example              # Template for per-project binding file
├── .env.example                       # Environment variables
├── templates/                         # Ready-to-submit page payloads
│   ├── homepage.json                  # Company homepage (hero + features + CTA)
│   ├── blog-setup.json                # Blog setup (author + tags + 2 posts)
│   └── dynamic-landing.json           # Personalized outreach page
├── components/                        # Shadow DOM components (CSS-isolated)
│   ├── hero-gradient.json             # Tier 1: gradient hero with CTA
│   ├── pricing-cards.json             # Tier 1: 3-tier pricing table
│   ├── faq-accordion.json             # Tier 2: interactive FAQ
│   ├── stats-animated.json            # Tier 3: GSAP animated counters
│   └── pricing-toggle.json            # Tier 4: React monthly/annual toggle
└── examples/                          # Full workflow examples
    ├── build-and-deploy.sh            # cURL-based site build (project-scoped URLs + confirm_token flow)
    └── personalized-outreach.sh       # Dynamic landing page setup
```

## How It Works

```
Your AI Agent (Claude Code, Cursor, Windsurf, Antigravity...)
    │
    │  loads ./spideriq.json → injects project_id
    │  MCP / CLI / API
    ▼
SpiderPublish API  ─────────── SpiderIQ IDAP (CRM data)
  (five-lock tenant defense)       │
    │                              │  Lead name, city, rating,
    │  destructive ops are         │  emails, phones, contacts
    │  preview → confirm           │
    ▼                              │
Cloudflare Edge (2-5s) ◄──────────┘
    │
    ▼
https://yoursite.com
    /                     ← Homepage
    /blog                 ← Blog listing
    /blog/my-post         ← Blog post
    /lp/offer/alex/0x...  ← Personalized landing page
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Multi-tenant safety (Phase 11+12)** | Five-lock defense — `spideriq.json` session binding, project-scoped URLs, preview→confirm on destructive ops |
| **Block-based pages** | 15 block types (hero, features, pricing, FAQ, testimonials, component, etc.) |
| **Page templates** | `default`, `landing`, `blank`, `dynamic_landing` — `blank` gives a full-canvas hero with zero chrome |
| **Theme palette (v0.8.2)** | 6 settings fields — `primary_color`, `surface_color`, `surface_elevated_color`, `subtle_color`, `body_text_color`, `heading_color` — drives the whole site. Default is dark |
| **Chrome override (v0.8.2)** | `content_override_section` / `content_apply_layout_preset` let you customize header/footer/layout without hacks |
| **Blog system** | Posts, authors, tags, categories, featured posts, full-text search |
| **Dynamic landing pages** | Personalize per lead using Google Place ID — `{{ lead.name }}`, `{{ lead.city }}` |
| **Shadow DOM components** | 4 tiers (static → framework build) with CSS isolation, theme CSS variables, and CDN allowlist |
| **Scroll-linked heroes** | Canvas + `position: sticky` + GSAP ScrollTrigger pattern — see CLAUDE.md for the recipe |
| **Liquid templates** | LiquidJS at Cloudflare's edge — 14 filters, 4 custom tags |
| **IDAP data access** | Read your CRM data (businesses, emails, contacts, phones) |
| **Multi-tenant** | Each client gets isolated content, custom domain, own Worker |
| **Preview URLs** | `preview-{hash}.sites.spideriq.ai` serves the staging snapshot before you flip production |
| **Token-efficient** | `?format=yaml` saves 40-76% tokens vs JSON |
| **Edge deployment** | Deploy to Cloudflare Workers in 2-5 seconds |

## Supported IDEs

Works with any IDE that supports MCP (Model Context Protocol):

- **Claude Code** (CLI, VS Code extension, JetBrains plugin)
- **Cursor**
- **Windsurf**
- **Google Antigravity**
- **VS Code** with Claude Code extension
- Any MCP-compatible editor

## Documentation

| Resource | Link |
|----------|------|
| Full docs | [docs.spideriq.ai/site-builder](https://docs.spideriq.ai/site-builder/overview) |
| AI Agent Guide | [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents) |
| **Session Binding (Phase 11+12)** | [docs.spideriq.ai/site-builder/sessions](https://docs.spideriq.ai/site-builder/sessions) |
| **Deploy Safely (preview→confirm)** | [docs.spideriq.ai/site-builder/deploy-safely](https://docs.spideriq.ai/site-builder/deploy-safely) |
| Tutorial: Homepage | [docs.spideriq.ai/site-builder/tutorial-homepage](https://docs.spideriq.ai/site-builder/tutorial-homepage) |
| Tutorial: Blog | [docs.spideriq.ai/site-builder/tutorial-blog](https://docs.spideriq.ai/site-builder/tutorial-blog) |
| Tutorial: Dynamic Landing | [docs.spideriq.ai/site-builder/tutorial-dynamic-landing](https://docs.spideriq.ai/site-builder/tutorial-dynamic-landing) |
| Gotchas & Best Practices | [docs.spideriq.ai/site-builder/learnings](https://docs.spideriq.ai/site-builder/learnings) |
| Deploy Guide | [docs.spideriq.ai/site-builder/deployment](https://docs.spideriq.ai/site-builder/deployment) |
| API Reference | [docs.spideriq.ai/api-reference](https://docs.spideriq.ai/api-reference/introduction) |
| Content Reference | `GET /api/v1/content/help` (YAML — includes `tasks` index, `chrome_override`, `theme_palette`, `session_binding`, `deploy_workflow`) |

## API Base

```
Production: https://spideriq.ai/api/v1
Docs:       https://docs.spideriq.ai
Health:     https://spideriq.ai/api/v1/system/health
```

## License

This repository contains documentation and starter templates, not source code.
SpiderIQ is a commercial platform — [contact us](mailto:admin@spideriq.ai) for API access.
