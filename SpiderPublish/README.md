# SpiderPublish

> AI-native headless CMS and site builder where pages pull live scraped data via IDAP — build, deploy, and personalize at scale through API, CLI, MCP and Native Skills in token-efficient YAML/MD format.

Build websites, blogs, landing pages, and personalized outreach pages — entirely through AI agents. No browser needed. Deploy to Cloudflare's edge in 2-5 seconds.

## Quick Start (2 minutes)

### 1. Copy files into your project

```bash
# Option A: Clone just this directory
npx degit martinshein/SpideriQ-ai/SpiderPublish my-site
cd my-site

# Option B: Copy manually
# Download .mcp.json + CLAUDE.md from this directory into your project root
```

### 2. Authenticate

```bash
npx @spideriq/cli auth request --email admin@company.com --registry https://npm.spideriq.ai
```

### 3. Ask your AI agent to build

Open your project in Claude Code, Cursor, VS Code, Windsurf, or Google Antigravity. The MCP server connects automatically. Ask:

> "Build me a landing page for a SaaS product with hero, features grid, testimonials, and pricing table. Then deploy it."

Your agent has 146+ tools available and full context from CLAUDE.md.

---

## What's in This Directory

```
SpiderPublish/
├── .mcp.json                          # MCP server config (drop into project root)
├── CLAUDE.md                          # AI agent context (drop into project root)
├── AGENTS.md                          # Complete integration guide
├── .env.example                       # Environment variables
├── templates/                         # Ready-to-submit page payloads
│   ├── homepage.json                  # Company homepage (hero + features + CTA)
│   ├── blog-setup.json                # Blog setup (author + tags + 2 posts)
│   └── dynamic-landing.json           # Personalized outreach page
├── components/                        # Shadow DOM components (CSS-isolated)
│   ├── hero-gradient.json             # Gradient hero with CTA
│   └── pricing-cards.json             # 3-tier pricing table
└── examples/                          # Full workflow examples
    ├── build-and-deploy.sh            # cURL-based site build
    └── personalized-outreach.sh       # Dynamic landing page setup
```

## How It Works

```
Your AI Agent (Claude Code, Cursor, Windsurf, Antigravity...)
    │
    │  MCP / CLI / API
    ▼
SpiderPublish API ─────────── SpiderIQ IDAP (CRM data)
    │                              │
    │  POST /deploy               │  Lead name, city, rating,
    ▼                              │  emails, phones, contacts
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
| **Block-based pages** | 14 block types (hero, features, pricing, FAQ, testimonials, etc.) |
| **Blog system** | Posts, authors, tags, categories, featured posts, full-text search |
| **Dynamic landing pages** | Personalize per lead using Google Place ID — `{{ lead.name }}`, `{{ lead.city }}` |
| **Shadow DOM components** | CSS-isolated reusable components with JSON Schema props |
| **Liquid templates** | LiquidJS at Cloudflare's edge — 14 filters, 4 custom tags |
| **IDAP data access** | Read your CRM data (businesses, emails, contacts, phones) |
| **Multi-tenant** | Each client gets isolated content, custom domain, own Worker |
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
| Tutorial: Homepage | [docs.spideriq.ai/site-builder/tutorial-homepage](https://docs.spideriq.ai/site-builder/tutorial-homepage) |
| Tutorial: Blog | [docs.spideriq.ai/site-builder/tutorial-blog](https://docs.spideriq.ai/site-builder/tutorial-blog) |
| Tutorial: Dynamic Landing | [docs.spideriq.ai/site-builder/tutorial-dynamic-landing](https://docs.spideriq.ai/site-builder/tutorial-dynamic-landing) |
| Gotchas & Best Practices | [docs.spideriq.ai/site-builder/learnings](https://docs.spideriq.ai/site-builder/learnings) |
| Deploy Guide | [docs.spideriq.ai/site-builder/deployment](https://docs.spideriq.ai/site-builder/deployment) |
| API Reference | [docs.spideriq.ai/api-reference](https://docs.spideriq.ai/api-reference/introduction) |
| Content Reference | `GET /api/v1/content/help` (YAML, ~2,867 tokens) |

## API Base

```
Production: https://spideriq.ai/api/v1
Docs:       https://docs.spideriq.ai
Health:     https://spideriq.ai/api/v1/system/health
```

## License

This repository contains documentation and starter templates, not source code.
SpiderIQ is a commercial platform — [contact us](mailto:admin@spideriq.ai) for API access.
