# SpiderPublish

> **AI-Native Agency OS for the agent-driven web.** CMS · CRM · workflows · booking · CRO · personalization · scraping · media — one runtime, MCP-native, every published tenant page dual-rendered for humans and LLMs.

The public Starter Kit for SpiderIQ. Drop into any project with `npx degit SpiderIQ/SpiderPublish/designer-kit` — your resident LLM agent reads the kit cold and learns to drive the platform. Build websites, blogs, landing pages, and personalized outreach pages entirely through agents. No browser needed. Deploy to Cloudflare's edge in 2–5 seconds.

## What this actually is, in 30 seconds

- **Content + extension slice of an AI-Native Agency OS.** Other slices (lead-gen, mail, gate, super-admin) ship from separate kits or via the dashboard.
- **Multi-tenant runtime.** Each tenant gets its own custom domain, isolated content, and a per-client Worker on Cloudflare Workers for Platforms.
- **IDAP-backed personalization.** `/lp/{slug}/{place_id}` URL pattern with merge tags fed by the scraping pipeline (~44k cities, business profiles, contacts).
- **4-class component model.** `static` / `interactive` / `dynamic` / `extension` — drives renderer + editor + agent surface. See [CAPABILITIES.md](./CAPABILITIES.md).
- **GEO-ready.** Every published tenant page can ship `/llms.txt` · `/feed.xml` · `/sitemap.xml` · schema.org JSON-LD · contextual menu · human/agent toggle. See [GEO.md](./GEO.md).
- **Four ways to drive the runtime.** Extension · MCP · CLI · API. Same engine; pick by ergonomic fit. See [SURFACES.md](./SURFACES.md) and [Four ways to drive](#four-ways-to-drive-the-runtime) below.

## Four ways to drive the runtime

Same engine; same MCP server; same auth; four front doors. Pick by ergonomic fit, not by feature — anything you can do with one, you can do with the others.

| Surface | Best for | What you get | How to install |
|---|---|---|---|
| **IDE extension** (`SpiderIQ.spideriq-publish`) | Authoring multi-section pages where you want to *see* what changes before pushing | Pages/posts/components/templates as files on disk · native VSCode diff editor · git-style stage view · pre-push link audit · one-keystroke deploy · bundles `@spideriq/mcp-publish` so AI agents in the same IDE share the surface | [Open VSX](https://open-vsx.org/extension/SpiderIQ/spideriq-publish) (Cursor / Antigravity / Windsurf) or [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=SpiderIQ.spideriq-publish) (VS Code 1.85+) |
| **MCP server** (`@spideriq/mcp-publish`) | LLM agents in chat (Claude Code, Cursor chat, Antigravity chat, Claude Desktop) | 87 tools registered as Language Model Tools · `dry_run`-defaulted destructive ops · YAML response format opt-in · same auth as the CLI | `.mcp.json` config (see [Quick Start](#quick-start-2-minutes)) |
| **CLI** (`@spideriq/cli`) | Scripts, CI, terminal-first workflows, agency loops over many tenants | Same primitives as MCP/extension, plus `auth request --email`, `use --list`, batch ops · machine-readable `--format yaml\|json\|md` | `npx @spideriq/cli --help` (one-shot) or `npm i -g @spideriq/cli --registry=https://npm.spideriq.ai` |
| **HTTP API** | Bespoke integrations, CRMs, server-side automation, anything outside an LLM/IDE | Raw REST under `/api/v1/dashboard/projects/{project_id}/...` · same Phase 11+12 dry_run/confirm_token gating · OpenAPI spec at `/api/v1/docs` | Bearer token + `curl` — see [examples/build-and-deploy.sh](./examples/build-and-deploy.sh) |

> **The IDE extension is a thin UX layer on top of the MCP server.** When you install it, it spawns `@spideriq/mcp-publish` as a child process. So an AI agent operating in the same IDE is reading the *exact same* tools the human is clicking — there's no second code path. Anything one can do, both can. See [docs.spideriq.ai/extension](https://docs.spideriq.ai/extension) for the install guide and command reference.

If you only learn one surface, learn the MCP server (it's the foundation). If you're authoring multiple sections in one session, layer the extension on top — native diffs catch mistakes the agent doesn't.

---

## The 4-class component taxonomy

| Kind | Renders where? | Examples |
|---|---|---|
| `static` | component HTML | hero-gradient, pricing-cards, faq-accordion |
| `interactive` | HTML + JS in Shadow DOM | sys-timer-fixed-date, sys-popup-exit-intent |
| `dynamic` | HTML + server-aggregated fetch | dynamic-form, dynamic-table, dynamic-chart, dynamic-map, list, item_details |
| `extension` | renderer hook / page-injection / endpoint | sys-rss-feed, sys-geo-schema-injector, sys-sitemap-robots |

Full taxonomy + per-kind rules in [CAPABILITIES.md](./CAPABILITIES.md#the-4-class-component-taxonomy).

## What this kit replaces (typical agency stack)

| Layer | Stack agencies cobble today | What this kit ships |
|---|---|---|
| CMS + page builder | Webflow, Framer, Squarespace + plugins | Multi-tenant Liquid templates on Cloudflare Workers for Platforms |
| Personalized landing pages | Mutiny, Optimizely, Adobe Target | `/lp/{slug}/{place_id}` with IDAP merge tags |
| Booking | Calendly, Acuity | SpiderBook (cal.com-backed) + `{% booking %}` Liquid tag |
| CRO components | Privy, OptinMonster | `interactive` class — timer · exit-intent · social-proof · stock bar · sticky bar · pricing toggle |
| Programmatic SEO directories | Webflow CMS hacks | `directory_*` tools + `/directory/{cat}/{city}/{listing}` |
| Forms | Typeform, Tally | `dynamic-form` with phone-validated + address-autocomplete |
| AI-search SEO | (no real product yet) | W6+W7 GEO family — `/llms.txt`, schema-injector, contextual menu, human/agent toggle |
| Multi-tenant white-label | Webflow Workspaces | Workers-for-Platforms — real per-tenant isolation, 2–5s deploys |

## For LLM agents reading this repo

In order, shortest to deepest:

1. [llms.txt](./llms.txt) — 56-line entry index
2. [CAPABILITIES.md](./CAPABILITIES.md) — 11-surface index + 4-class taxonomy + what's in this kit vs elsewhere
3. [SURFACES.md](./SURFACES.md) — pick CLI vs MCP vs IDE extension vs Skills (same engine, four rendering surfaces)
4. [AGENTS.md](./AGENTS.md) — full tool catalog with payload schemas, error tables, common mistakes
5. [CLAUDE.md](./CLAUDE.md) — Claude-Code-specific session-binding + Phase 11+12 multi-tenant safety contract
6. [GEO.md](./GEO.md) — Generative Engine Optimization extension family
7. [MERGE-TAGS.md](./MERGE-TAGS.md) — personalization vocabulary
8. [skills/recipes/](./skills/recipes/) — 10 multi-step workflows (marketplace-search, scroll-sequence, tilda-migration, link-audit, directory, …)
9. [LEARNINGS.md](./LEARNINGS.md) — gotchas + anti-patterns

**Current versions:** `@spideriq/cli@1.7.0`, `@spideriq/mcp-publish@1.7.0` (87 tools — the atomic content + extension slice), `@spideriq/core@1.6.0`, `SpiderIQ.spideriq-publish@0.1.1` (IDE extension on Open VSX + VSCode Marketplace). Prefer `mcp-publish` over the kitchen-sink `@spideriq/mcp@1.7.0` (126 tools) — under the ~128-tool injection limit some IDE/LLM stacks enforce, and less context burn per turn.

Continue reading for full architecture, tool catalog, and recipes →

## Quick Start (2 minutes)

### 1. Copy files into your project — pick the runtime that matches your IDE

The Starter Kit ships per-runtime trees under [`runtimes/`](./runtimes/). Pull only the one your IDE expects:

```bash
# Claude Code (CLI / VSCode / JetBrains plugin / Windsurf / VSCode-with-Claude-Code-extension)
npx degit SpiderIQ/SpiderPublish/designer-kit/runtimes/claude-code my-site

# Google Antigravity
npx degit SpiderIQ/SpiderPublish/designer-kit/runtimes/antigravity my-site
bash my-site/install-knowledge-items.sh   # copies KIs to ~/.gemini/antigravity/knowledge/

# Cursor
npx degit SpiderIQ/SpiderPublish/designer-kit/runtimes/cursor my-site

# Claude Desktop (manual setup, no auto-bootstrap)
npx degit SpiderIQ/SpiderPublish/designer-kit/runtimes/claude-desktop my-site
# then read my-site/README.md for the manual claude_desktop_config.json edit

cd my-site
```

> **Don't know which one you are?** Paste [SETUP-PROMPT.md](./SETUP-PROMPT.md) into your agent — it self-detects and runs the right block.

The canonical content lives in [`shared/`](./shared/) and is regenerated into each runtime via `npm run build`. Edit `shared/`, regenerate, commit. Never edit `runtimes/` directly.

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
npx @spideriq/cli use <workspace>   # short id cli_xxx, brand slug, or company name (a workspace = your account). Add --project <proj_…> to bind a specific site
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
├── README.md                          # this file (repo landing)
├── SETUP-PROMPT.md                    # paste this into your agent — branches by runtime
├── manifest.json                      # runtime + skill registry (consumed by build.ts)
├── package.json + tsconfig.json       # build dependencies (tsx + zod, ~10 packages)
│
├── shared/                            # CANONICAL source of truth — edit here
│   ├── content/                       # top-level concept docs (CAPABILITIES / SURFACES / GEO / MERGE-TAGS / LEARNINGS), Claude binding, AGENTS catalog
│   ├── recipes/                       # 10 multi-step task recipes (scroll-sequence, marketplace-search-and-insert, …)
│   ├── core-skills/                   # 5 MCP-namespace overviews (content-platform, booking, templates-engine, upload-host-media, agentdocs)
│   ├── guides/                        # 5 onboarding + decision guides (create-page, personalized-landing, pick-mcp-package, cli-quick-reference, ide-extension-setup)
│   ├── components/                    # 21 component / block JSON exemplars
│   ├── examples/                      # 14 runnable shell scripts
│   └── templates/                     # 3 ready-to-submit page payloads
│
├── runtimes/                          # EMITTED per-runtime trees — regenerated by `npm run build`
│   ├── claude-code/                   # CLAUDE.md + .claude/skills/{recipes,core,guides}/<id>/SKILL.md (with YAML frontmatter) + .mcp.json
│   ├── antigravity/                   # AGENTS.md + knowledge-items/<NN>-spideriq-<id>/{metadata.json,artifacts/} + install-knowledge-items.sh
│   ├── cursor/                        # AGENTS.md + .cursor/rules/<id>.mdc (description-matched auto-load) + .mcp.json
│   └── claude-desktop/                # README.md (manual setup, no auto-bootstrap)
│
├── scripts/
│   └── build.ts                       # ~280 LOC TypeScript — reads manifest.json + shared/, emits runtimes/
│
└── CLAUDE.md, AGENTS.md               # legacy redirects (retiring ~2026-06-09 — one release cycle)
```

### Editing the kit

```bash
# 1. Edit canonical content
$EDITOR shared/recipes/scroll-sequence/SKILL.md
$EDITOR shared/content/agents-catalog.md
$EDITOR manifest.json   # if adding a new skill or runtime

# 2. Regenerate runtimes
npm run build

# 3. Commit (degit pulls from `runtimes/` so the trees must be checked in)
git add shared/ runtimes/ manifest.json
git commit -m "feat(scroll-sequence): clarify GSAP fallback path"
```

## Where to Start

| If you want to… | Read |
|---|---|
| Build a site from scratch | [AGENTS.md → Build a Site](./AGENTS.md#build-a-site-follow-all-steps) |
| Port a Tilda / Webflow / Lovable site | [skills/recipes/tilda-migration/](./skills/recipes/tilda-migration/) · [examples/tilda-migrate.sh](./examples/tilda-migrate.sh) |
| Verify your PAT + which project it's bound to | [examples/check-auth.sh](./examples/check-auth.sh) · `npx @spideriq/cli auth whoami` |
| Find broken internal links before deploy | [skills/recipes/link-audit/](./skills/recipes/link-audit/) · [examples/audit-links.sh](./examples/audit-links.sh) |
| Preview a single component without a full deploy | [examples/preview-component.sh](./examples/preview-component.sh) |
| Avoid double headers when shipping custom chrome | Mark your header component `category: "header"` — see [components/page-with-custom-header.json](./components/page-with-custom-header.json) |
| Understand why `{type:'component', data:{slug}}` fails | [components/block-component.json](./components/block-component.json) · [LEARNINGS.md → Apr 2026 Triage](./LEARNINGS.md#apr-2026-triage) |
| Roll out a shared-component change in one call | [skills/recipes/component-update-and-propagate/](./skills/recipes/component-update-and-propagate/) |
| Undo a bad component change | [skills/recipes/component-rollback/](./skills/recipes/component-rollback/) |
| Ship a scroll-linked hero from a video | [skills/recipes/scroll-sequence/](./skills/recipes/scroll-sequence/) |
| Build a programmatic directory (category / city / listing) | [skills/recipes/directory/](./skills/recipes/directory/) |

## How It Works

```
Your AI Agent (Claude Code, Cursor, Windsurf, Antigravity...)
    │
    │  loads ./spideriq.json → injects workspace_id (+ project_id)
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
| **Token-efficient** | `?format=yaml` saves 40-76% tokens vs JSON. Every read endpoint also takes `json`, `md` and `llm` |
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
