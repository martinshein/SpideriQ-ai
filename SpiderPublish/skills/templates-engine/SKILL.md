# templates-engine

Liquid template CRUD, theme management, and deploy-to-edge for tenant sites. The renderer reads templates from per-client KV and fetches content from the API at request time — no per-client npm builds.

**Exposed via:** `@spideriq/mcp-publish`. Tool namespace: `template_*` + `content_deploy_*`.

## When to use

- Applying a starter theme to a new tenant (`template_apply_theme`)
- Customizing individual theme files (header/footer/layout/hero) via `content_override_section`
- Previewing a rendered template without saving (`template_preview`)
- Deploying site changes to Cloudflare edge (`content_deploy_site_preview` → `content_deploy_site_production`)

## When NOT to use

- Creating pages / posts / components → [content-platform](../content-platform/)
- Uploading assets → [upload-host-media](../upload-host-media/)

## Common tool chains

| Goal | Chain |
|---|---|
| New tenant, default theme | `template_list_themes` → `template_apply_theme(theme="default")` (dry_run → confirm) |
| Customize footer only | `content_get_section_source(section="footer")` → edit Liquid in your context → `content_override_section(section="footer", liquid=modified)` |
| Test a component in isolation | `template_preview(component={html, css, js, props})` → visit returned sandbox URL |
| Deploy safely | `content_deploy_site_preview()` → open `preview_url` in browser → `content_deploy_site_production(confirm_token)` |
| Check what's deployed | `content_deploy_status` (latest) or `content_deploy_history` (last N) |

## Key rules

1. `template_preview` is the ONLY non-mutating tool in this skill — use it liberally during the edit/debug loop. It doesn't touch DB, KV, or Cloudflare.
2. `template_apply_theme` overwrites ALL current template files for the tenant. Use with care if the tenant has custom overrides.
3. Deploys are two-step: preview → confirm. The confirm_token expires in 10 minutes and is single-use.
4. `preview_url` looks like `preview-{hash}.sites.spideriq.ai` and lives in an isolated dispatch-namespace slot. It's the "dev environment" — use it to verify before promoting to production.

## Section names for `content_override_section`

- `header` — top navigation bar
- `footer` — site footer
- `layout` — the root theme.liquid wrapper (body class, head meta, etc.)
- `head` — per-page `<head>` snippet
- `hero` — default hero block (rendered when a page has no top-of-fold block)

## See also

- [content-platform](../content-platform/) — pages and components that these templates render
- [recipes/preview-iteration](../recipes/preview-iteration/) — full preview → confirm flow
- Docs: https://docs.spideriq.ai/site-builder/component-builder

## Upstream

Full opvsHUB source: [spideragent/skills/opvsHUB/skills/templates-engine/](https://github.com/martinshein/SpiderIQ/tree/main/spideragent/skills/opvsHUB/skills/templates-engine) (internal)
