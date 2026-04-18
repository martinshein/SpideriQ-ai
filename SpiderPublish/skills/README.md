# SpiderPublish Skills

Curated skill library for building SpiderPublish sites — just what you need to deploy a client site, nothing more.

These skills are designed to be used directly by AI coding agents (Claude Code, Cursor, Antigravity, Windsurf). The Tier 3 `impl.ts` files use only Node 18+ stdlib (`fetch`, `fs`, `path`) — zero external npm dependencies. Copy-paste them into your agent's sandbox and run with `npx tsx impl.ts` — no extra runtime, no installs.

## Core building blocks

Already exposed via `@spideriq/mcp-publish` as individual MCP tools. These SKILL.md files are the agent-readable reference.

| Skill | What it covers |
|---|---|
| [content-platform/](content-platform/) | Pages, blog posts (authors/tags/categories), docs, navigation, settings, components, domains, **directory pages** (`/directory/{cat}/{city}/{listing}`), component site-wide propagation, section overrides |
| [booking/](booking/) | **Appointments / bookings** (cal.com-powered). Flow authoring, services, bookings, template library. Ships a `/book/{flow_id}` route and a `{% booking %}` Liquid tag |
| [templates-engine/](templates-engine/) | Liquid templates, themes, deploy to Cloudflare edge |
| [upload-host-media/](upload-host-media/) | Image / file / video upload to CDN — plus `upload_local_file` / `upload_local_directory` for agents with filesystem access |
| [agentdocs/](agentdocs/) | Versioned documentation projects |

**Blog authoring** lives inside `content-platform/` — see its "Blog authoring workflow" section. The blog tools share the `content_*` namespace with pages, so they don't need a separate skill directory.

**Directory pages** are also under `content-platform/` (shared `directory_*` tool namespace) — see the "Directory pages" section.

## Recipes

Multi-step workflows composing multiple MCP tools. Each recipe has a full Tier 1 → Tier 3 ladder.

| Recipe | Problem it solves |
|---|---|
| [recipes/scroll-sequence/](recipes/scroll-sequence/) | Cinematic scroll-scrubbed heroes. Video → `extract_frames` → `sys-scroll-sequence` block → deploy. Replaces the 12-hour "roll your own" trap. v1.1.0+ also accepts `image_urls[]` for hand-picked frames. |
| [recipes/component-update-and-propagate/](recipes/component-update-and-propagate/) | Update a shared component AND repoint every consuming page's block pin — one MCP call + one confirm_token instead of the ~10-request choreography (v2.88.0+). |
| [recipes/component-rollback/](recipes/component-rollback/) | Restore a component to an earlier version's content. Creates a new forward version + repoints pages. Pairs with update-and-propagate for undo (v2.88.0+). |
| [recipes/preview-iteration/](recipes/preview-iteration/) | Safe edit loop: `template_preview` (no state mutation) → browser-check → publish (dry_run → confirm_token). |
| [recipes/bulk-media-upload/](recipes/bulk-media-upload/) | Upload a local directory of files directly via multipart POST. Kills the pinggy/catbox/serveo tunnel workaround. |
| [recipes/directory/](recipes/directory/) | Programmatic `/directory/{category}/{city}/{listing}` pages: create category → bulk-upsert listings (or import from IDAP) → deploy. |

## Examples

Copy-paste shell scripts under [examples/](../examples/). Each one uses only the public API + a PAT.

| Example | What it does |
|---|---|
| [`examples/booking-flow.sh`](../examples/booking-flow.sh) | Clone a booking archetype, theme it, publish, grab the `/book/{flow_id}` URL |
| [`examples/directory-bulk-import.sh`](../examples/directory-bulk-import.sh) | Seed a directory category with a JSON array of listings |
| [`examples/bulk-media-upload.sh`](../examples/bulk-media-upload.sh) | Upload a local directory of files — no tunnel required |
| [`examples/scroll-sequence.sh`](../examples/scroll-sequence.sh) | Video → scroll-scrubbed hero in one call |
| [`examples/personalized-landing.sh`](../examples/personalized-landing.sh) | Lead-resolved dynamic landing page with merge tags |
| [`examples/personalized-outreach.sh`](../examples/personalized-outreach.sh) | End-to-end lead → page → email outreach |
| [`examples/build-and-deploy.sh`](../examples/build-and-deploy.sh) | Minimal build + deploy scaffold |

## Tier legend

- **Tier 1** — YAML or markdown doc. Readable by any agent.
- **Tier 2** — `schema.yaml` describing an MCP-call sequence. Runnable in any MCP client.
- **Tier 3** — `impl.ts` with filesystem and HTTP access. Self-contained — Node 18+ stdlib only (`fetch`, `fs`, `path`). Run in your own sandbox (Claude Code, Cursor, Antigravity, Node CLI).

## How to use these in your agent

**Claude Code** — drop the `skills/` tree into your project root and reference individual SKILL.md files in your prompts:
> "Use `skills/recipes/scroll-sequence/` as the recipe for building this hero."

**Cursor / Antigravity** — link the github path in your project context:
```
https://github.com/martinshein/SpideriQ-ai/tree/main/SpiderPublish/skills/recipes/scroll-sequence
```

**Node CLI** — Tier 3 impl.ts files are self-contained scripts:
```bash
cd skills/recipes/bulk-media-upload
SPIDERIQ_TOKEN=... SPIDERIQ_API_URL=https://spideriq.ai npx tsx impl.ts ./my-frames/
```

## When to use MCP directly vs. a skill

- **MCP tool** — single-step typed CRUD (create page, publish component, apply theme). Call from any MCP client.
- **Skill** — multi-step workflow with branching, polling, filesystem I/O, or domain-specific sequencing. Use the recipe file as your reference.

## What's deliberately NOT here

- Lead-gen skills (scraping, enrichment) — use `@spideriq/mcp-leads` instead
- LLM routing / gate skills — use `@spideriq/mcp-gate`
- Mail skills — use `@spideriq/mcp-mail`
- Admin skills — use `@spideriq/mcp-admin`

If you need one of those, add a second MCP server entry in your `.mcp.json`. See [../README.md](../README.md) for the full atomic-package catalog.
