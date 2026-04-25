# Contributing a Site Template

How to design and submit a new template for the SpiderPublish gallery.

This guide is for **graphic designers and brand teams** working with [Antigravity](https://antigravity.dev). For the engineering side (REST endpoints, MCP tools, Phase 11+12 gating), see [AGENTS.md → Site templates](./AGENTS.md#site-templates-gallery--phase-b-2026-04-25).

---

## What you're building

A **site template** = a working starter site that any SpiderPublish tenant can clone in one click. Each template ships with:

- 1–4 pages (a homepage at minimum, often `/`, `/pricing`, `/about`)
- A header + footer in the navigation menu
- A small set of theme settings (primary color, body text color, social links)
- References to shared components from our [component palette](./templates/COMPONENT-PALETTE.md) — you compose, you don't reinvent

When a customer applies your template, every page gets cloned into their tenant as a **draft** with fresh UUIDs. They review, edit copy + images, and publish. Your design is the starting point — they own the final result.

---

## The five-step flow

```
1. Pick a brief         → docs/services/catalog/template-briefs/<slug>.md (engineering writes these)
2. Design in Antigravity → Figma Make site, our component palette, reference our visual tokens
3. Export + write a manifest → JSON describing pages, settings, nav
4. Open a PR            → templates/<slug>/ with the manifest + screenshots
5. Engineering imports  → registers in the gallery, assigns a preview URL, ships
```

You do steps 2–4. Engineering does 1 and 5.

---

## Step 1 — Pick a brief

Engineering ships one design brief per template before you start. Each brief lives at `docs/services/catalog/template-briefs/<slug>.md` (in the internal SpiderIQ repo, ask your engineering counterpart for a copy) and answers:

- **Target client** — who is this for? (e.g. "early-stage SaaS founder selling a developer tool, $10–50/mo plans")
- **Conversion goal** — what's the primary action? (book a demo, start free, buy now, signup, read)
- **Required pages** — what pages must exist? (e.g. `/`, `/pricing`, `/about`)
- **Section spec** — what each page must contain at minimum (hero + 3-feature grid + pricing + CTA + footer)
- **Tone** — voice and copy guidance
- **References** — 2–3 competitor sites you can riff on visually

If the brief is ambiguous, ask. Don't guess. A bad brief → a bad template.

---

## Step 2 — Design in Antigravity

Use Antigravity (Figma Make) to design every page in the brief. Constraints:

- **Use our component palette.** Every section should map to a component in [templates/COMPONENT-PALETTE.md](./templates/COMPONENT-PALETTE.md). If you need a section type that's not in the palette, flag it as a "designer follow-up" — engineering will add it before your template can ship. Do not invent novel sections that don't have a SpiderPublish equivalent.
- **Use our visual tokens.** SpiderPublish ships a Vercel-style premium black-and-white aesthetic across the dashboard and the rendered sites. Match it. Specifically: fg/bg/border tokens drive light + dark mode automatically. Don't hardcode colors that won't theme correctly.
- **Don't design auth, billing, or app UI.** Templates are for marketing/content surfaces only. If your design implies a logged-in app screen, stop — that's not a template.

Output from Antigravity:
- Visual mockups (PNG screenshots of each page, full-bleed at 1440×900)
- Optional: HTML/CSS export of any custom component (if you need a section the palette doesn't cover yet — see "follow-up" caveat above)

---

## Step 3 — Write the manifest

For each template, create one `template.json` that tells SpiderPublish what to clone. Use the skeleton at [templates/_template-skeleton.json](./templates/_template-skeleton.json):

```json
{
  "slug": "saas-developer-tool",
  "name": "SaaS — Developer Tool",
  "description": "One-line description shown on the gallery card.",
  "industry": "saas",
  "use_case": "marketing",
  "tags": ["dev-tool", "open-core", "freemium"],
  "is_featured": false,
  "pages": [
    {
      "slug": "home",
      "title": "Home",
      "blocks": [
        { "type": "component", "component_slug": "hero-headline", "props": { "headline": "...", "subheadline": "...", "cta_text": "..." } },
        { "type": "component", "component_slug": "features-3col", "props": { "title": "...", "items": [...] } }
      ]
    }
  ],
  "navigation": {
    "header": [{ "label": "Pricing", "path": "/pricing" }, ...],
    "footer": [...]
  },
  "settings": {
    "primary_color": "#0A0A0A",
    "body_text_color": "#1F1F23"
  }
}
```

Component props match the schema published in [COMPONENT-PALETTE.md](./templates/COMPONENT-PALETTE.md). If a prop you want to set isn't in the palette schema, you can't set it.

---

## Step 4 — Open a PR

Branch from `main` in this repo (`SpideriQ-ai/SpiderPublish`):

```bash
git checkout -b template/<slug>
mkdir -p templates/<slug>
```

Inside `templates/<slug>/`:

```
templates/saas-developer-tool/
├── template.json           # the manifest from Step 3
├── README.md               # 1-paragraph intro + the brief link
├── screenshots/
│   ├── home-light.png      # 1440×900
│   ├── home-dark.png       # 1440×900
│   ├── pricing-light.png
│   └── ...
└── antigravity-export/     # optional — only if you exported custom HTML/CSS
```

Open a PR titled `template: <slug>` with:
- The brief link in the description
- The list of pages included
- Any "needs new component" follow-ups called out clearly

---

## Step 5 — Engineering imports

Once the PR is approved, engineering runs an import script that:

1. Validates the manifest against the component palette
2. Creates the pages on the SpiderIQ-owned source tenant (`cli_spideriq_templates`)
3. Deploys a preview, captures the live URL + a thumbnail screenshot
4. Inserts a row into `content_site_templates` so the gallery shows your template
5. Verifies a tenant can apply it without errors

You'll get a comment on the PR with the preview URL. Eyeball it, request changes if needed, then we merge.

---

## Quality bar

Before opening the PR:

- ✅ Every section maps to a palette component
- ✅ All pages render in **both light and dark mode** (verify in Antigravity preview)
- ✅ Copy is real-ish — not lorem ipsum, not "Your Headline Here". Use plausible content for the target persona.
- ✅ Mobile breakpoints look correct (the components are responsive — but eyeball them)
- ✅ No images larger than 800kb in `screenshots/` (compress before commit)
- ✅ No images that imply a feature SpiderPublish doesn't have (no checkout flows, no auth screens, no in-app dashboards)

---

## See also

- [templates/COMPONENT-PALETTE.md](./templates/COMPONENT-PALETTE.md) — the available components and their prop schemas
- [templates/_template-skeleton.json](./templates/_template-skeleton.json) — manifest skeleton to copy
- [LEARNINGS.md → Apply-site-template gotchas](./LEARNINGS.md#apply-site-template-gotchas-2026-04-25) — what does/doesn't carry over when a customer applies your template
- [skills/recipes/apply-template/](./skills/recipes/apply-template/) — what a customer agent does when they apply your template
- Existing reference templates (engineering-built, intentionally bare): see the gallery at `https://app.spideriq.ai/dashboard/content/templates-gallery`

---

## Questions?

- **Engineering counterpart**: ping the SpiderPublish team in #publish or open a discussion on this repo
- **Brief unclear**: comment on the brief doc in the internal repo, don't guess
- **Need a new component**: open an issue here titled `component: <name>` describing the section + a screenshot — engineering ships components separately from templates
