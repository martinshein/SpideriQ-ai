# SpiderPublish on Claude Desktop

Claude Desktop has no auto-bootstrap (no MCP discovery from a folder, no skill loading). Setup is manual.

## 1. Add MCP server

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or the Windows equivalent:

```json
{
  "mcpServers": {
    "spideriq-publish": {
      "command": "npx",
      "args": ["-y", "@spideriq/mcp-publish@latest"],
      "env": {
        "SPIDERIQ_TOKEN": "<your-PAT>",
        "SPIDERIQ_API_URL": "https://spideriq.ai"
      }
    }
  }
}
```

Then restart Claude Desktop.

## 2. Authenticate + bind project

In a terminal:

```bash
npx @spideriq/cli auth request --email admin@company.com
# wait for approval, then in your project root:
npx @spideriq/cli use <project>   # writes ./spideriq.json
```

## 3. Reference docs in your prompts

Claude Desktop has no skill auto-loading, so paste relevant context manually:

- [shared/content/claude-binding.md](../../shared/content/claude-binding.md) — Phase 11+12 safety contract
- [shared/content/agents-catalog.md](../../shared/content/agents-catalog.md) — full tool catalog with payload schemas

For task-specific recipes, paste the relevant skill body from [shared/recipes/](../../shared/recipes/):

- **Build a Scroll-Linked Hero from a Video** — `shared/recipes/scroll-sequence/SKILL.md`
- **Search the SpiderIQ Component Marketplace** — `shared/recipes/marketplace-search-and-insert/SKILL.md`
- **Suggest agent_meta for Marketplace Assets (LLM-Inferred)** — `shared/recipes/marketplace-suggest-agent-meta/SKILL.md`
- **Update a Shared Component and Propagate Across All Pages** — `shared/recipes/component-update-and-propagate/SKILL.md`
- **Roll Back a Shared Component to an Earlier Version** — `shared/recipes/component-rollback/SKILL.md`
- **Safe Edit Loop with Preview → Confirm** — `shared/recipes/preview-iteration/SKILL.md`
- **Upload a Local Directory of Files via Multipart POST** — `shared/recipes/bulk-media-upload/SKILL.md`
- **Build a Programmatic Directory (Category / City / Listing)** — `shared/recipes/directory/SKILL.md`
- **Audit Internal Links Before Deploy** — `shared/recipes/link-audit/SKILL.md`
- **Migrate a Tilda / Webflow / Lovable Site to SpiderPublish** — `shared/recipes/tilda-migration/SKILL.md`
- **Build a Multi-Step Lead-Gen Form (end-to-end)** — `shared/recipes/build-lead-gen-form/SKILL.md`
- **Design a Form — Presets, Token Overrides, Per-Question Media** — `shared/recipes/design-a-form/SKILL.md`
- **Fill the CRM from a Form — IDAP Field Types + crm_target** — `shared/recipes/idap-fill-from-form/SKILL.md`
- **Build a Login Page — Authentication Components + auth_target** — `shared/recipes/build-a-login-page/SKILL.md`
- **Build a Dynamic Component — Live, Server-Filtered Collections** — `shared/recipes/build-a-dynamic-component/SKILL.md`
- **Members-Gated Page — Site Members + per-page access** — `shared/recipes/members-gated-page/SKILL.md`
- **Tripwire + OTO Commerce Funnel** — `shared/recipes/tripwire-oto/SKILL.md`

## 4. Optional: build via the CLI

If you prefer terminal-only, [@spideriq/cli](../../shared/guides/cli-quick-reference/) has the same primitives as MCP without an IDE:

```bash
npx @spideriq/cli content list-pages --format yaml
npx @spideriq/cli content publish-page --page-id abc-123 --dry-run
```
