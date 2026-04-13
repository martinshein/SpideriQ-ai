# SpiderPublish — AGENTS.md

> Full version: [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents)

## Quick Reference

### Setup
1. Copy `.mcp.json` to your project root
2. Copy `CLAUDE.md` to your project root
3. Restart your IDE
4. Authenticate: `npx @spideriq/cli auth request --email admin@company.com --registry https://npm.spideriq.ai`

### Build a Site
```
template_get_help          → Read the full content reference
content_create_page        → Create pages with blocks
content_publish_page       → Publish pages
template_apply_theme       → Apply "default" theme
content_deploy_site        → Deploy to Cloudflare edge (2-5s)
```

### Block Types
`hero`, `features_grid`, `cta_section`, `testimonials`, `pricing_table`, `faq`, `stats_bar`, `rich_text`, `image`, `video_embed`, `code_example`, `logo_cloud`, `comparison_table`, `spacer`, `component`

### Page Templates
`default`, `landing`, `feature`, `legal`, `dynamic_landing`

### Upload Images
```bash
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }
```

### Dynamic Landing Pages
URL: `/lp/{page_slug}/{salesperson}/{google_place_id}`
Variables: `{{ lead.name }}`, `{{ lead.city }}`, `{{ lead.rating }}`, `{{ salesperson.name }}`

### IDAP (CRM Data)
```bash
GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml
GET /api/v1/idap/businesses/resolve?place_id=0x47e66fdad6f1cc73:0x341211b3fccd79e1
```

### Rate Limits
- API: 100 requests/minute
- Jobs: 10 submissions/minute
- Always use `?format=yaml` (saves 40-76% tokens)

## Tutorials
- [Build a Homepage](https://docs.spideriq.ai/site-builder/tutorial-homepage)
- [Build a Blog](https://docs.spideriq.ai/site-builder/tutorial-blog)
- [Personalized Landing Page](https://docs.spideriq.ai/site-builder/tutorial-dynamic-landing)

## Full Documentation
- [AI Agent Guide](https://docs.spideriq.ai/site-builder/agents)
- [Gotchas & Best Practices](https://docs.spideriq.ai/site-builder/learnings)
- [Deploy Guide](https://docs.spideriq.ai/site-builder/deployment)
- [API Reference](https://docs.spideriq.ai/api-reference/introduction)
