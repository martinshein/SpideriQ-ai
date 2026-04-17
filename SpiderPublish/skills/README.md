# SpiderPublish Skills

Curated SpiderPublish-scoped skill library. **Not** a full opvsHUB mirror — just what you need to build a client site.

These skills are designed to be used directly by AI coding agents (Claude Code, Cursor, Antigravity, Windsurf). The Tier 3 `impl.ts` files use only Node 18+ stdlib (`fetch`, `fs`, `path`) — zero external npm dependencies. Copy-paste them into your agent's sandbox and run with `npx tsx impl.ts` — no opvsHUB runtime, no installs.

## Core building blocks

Already exposed via `@spideriq/mcp-publish` as individual MCP tools. These SKILL.md files are the agent-readable reference.

| Skill | What it covers |
|---|---|
| [content-platform/](content-platform/) | Pages, blog posts, docs, navigation, settings, components, domains |
| [templates-engine/](templates-engine/) | Liquid templates, themes, deploy to Cloudflare edge |
| [upload-host-media/](upload-host-media/) | Image / file / video upload to CDN |
| [agentdocs/](agentdocs/) | Versioned documentation projects |
| [opvs-blog/](opvs-blog/) | Blog authors, tags, categories, post lifecycle |

## Recipes

Multi-step workflows composing multiple MCP tools. Each recipe has a full Tier 1 → Tier 3 ladder.

| Recipe | Problem it solves |
|---|---|
| [recipes/scroll-sequence/](recipes/scroll-sequence/) | Cinematic scroll-scrubbed heroes. Video → `extract_frames` → `sys-scroll-sequence` block → deploy. Replaces the 12-hour "roll your own" trap. |
| [recipes/preview-iteration/](recipes/preview-iteration/) | Safe edit loop: `template_preview` (no state mutation) → browser-check → publish (dry_run → confirm_token). |
| [recipes/bulk-media-upload/](recipes/bulk-media-upload/) | Upload a local directory of files directly via multipart POST. Kills the pinggy/catbox/serveo tunnel workaround. |

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
