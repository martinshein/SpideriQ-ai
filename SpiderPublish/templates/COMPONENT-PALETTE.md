# Component Palette

The reusable section types you compose templates from.

Every component in this palette is shipped as `is_global=true` on the SpiderIQ-owned source tenant, which means **every** template in the gallery references the same instance — no per-template forks. When engineering ships a fix to (say) `pricing-3tier`, every template that uses it gets the fix.

Designers compose templates from this palette. **Don't invent new section types** — if you need a section that's not here, open an issue titled `component: <name>` so engineering can add it before your template ships.

> **Note for designers**: This palette describes the *target contract*. The first batch of components ships alongside the substrate PR (engineering work in progress). Once shipped, this doc becomes the single source of truth — schemas listed here will exactly match what's deployed.

---

## Header / footer

### `header-nav-cta`
Top-of-page navigation bar with logo, links, and a primary CTA button.

| Prop | Type | Notes |
|---|---|---|
| `logo_text` | string | Brand text shown in the top-left. Pair with logo_url if you want an image. |
| `logo_url` | string \| null | Optional logo image. PNG/SVG. |
| `nav_items` | `[{ label, path }]` | 3–5 items typical. More crowds the bar. |
| `cta_text` | string | "Get started", "Book a demo", etc. |
| `cta_path` | string | Where the CTA links. |

### `footer-minimal`
Single-row footer: copyright + 2-column link list + social icons.

| Prop | Type | Notes |
|---|---|---|
| `copyright_text` | string | "© 2026 Acme, Inc." |
| `columns` | `[{ heading, items: [{ label, path }] }]` | Max 4 columns. |
| `social` | `[{ platform, url }]` | platform ∈ `twitter \| linkedin \| github \| youtube`. |

---

## Hero

### `hero-headline`
Text-only hero — headline, subheadline, single CTA. No image.

| Prop | Type | Notes |
|---|---|---|
| `headline` | string | Max ~80 chars to render well on mobile. |
| `subheadline` | string | One sentence. Aim for ~120 chars. |
| `cta_text` | string | "Get started", "Try it free", etc. |
| `cta_path` | string | |
| `secondary_cta_text` | string \| null | Optional. Renders as ghost button next to primary. |
| `secondary_cta_path` | string \| null | |
| `eyebrow` | string \| null | Tiny label above headline ("New", "v2.0", etc.) |

### `hero-with-image`
Two-column hero — copy + CTA on left, image on right.

| Prop | Type | Notes |
|---|---|---|
| `headline` | string | |
| `subheadline` | string | |
| `cta_text` / `cta_path` | string | |
| `image_url` | string | 800×600 minimum. PNG, JPG, or WebP. |
| `image_alt` | string | Accessibility — required. |

---

## Features

### `features-3col`
Three-column feature grid. Each cell: icon + heading + body.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | Optional. |
| `section_subtitle` | string \| null | |
| `features` | `[{ icon, heading, body }]` | Exactly 3, 6, or 9 items (3-col grid). |

`icon` values: any [lucide-react](https://lucide.dev/icons/) icon name (lowercase, kebab-case). E.g. `"zap"`, `"shield-check"`, `"chart-bar"`.

### `features-icon-list`
Vertical icon list — better for 5+ features that don't fit a grid.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | |
| `features` | `[{ icon, heading, body }]` | 4–8 items typical. |

---

## Pricing

### `pricing-3tier`
Three-tier pricing card row. The middle tier renders highlighted.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string | |
| `section_subtitle` | string \| null | |
| `tiers` | `[{ name, price, period, features: string[], cta_text, cta_path, highlighted? }]` | Exactly 3. Set `highlighted: true` on the middle tier to emphasize. |

Example tier:
```json
{
  "name": "Pro",
  "price": "$29",
  "period": "/month",
  "features": ["Up to 10 sites", "Custom domains", "Priority support"],
  "cta_text": "Start trial",
  "cta_path": "/signup?plan=pro",
  "highlighted": true
}
```

---

## Social proof

### `testimonials-grid`
Three-column quote grid — author photo + quote + name + title.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | "Trusted by teams at..." etc. |
| `testimonials` | `[{ quote, author_name, author_title, author_photo_url? }]` | 3, 6, or 9 items. |

### `testimonials-quote`
Single oversized hero quote with attribution. Use for one anchor testimonial per page.

| Prop | Type | Notes |
|---|---|---|
| `quote` | string | One paragraph max. |
| `author_name` | string | |
| `author_title` | string | |
| `author_photo_url` | string \| null | |

---

## FAQ

### `faq-accordion`
Collapsible Q&A list.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string | "Frequently asked questions" or similar. |
| `items` | `[{ question, answer }]` | 5–10 items typical. |

---

## CTAs

### `cta-button`
Centered single-CTA banner. Use to break up a long page.

| Prop | Type | Notes |
|---|---|---|
| `headline` | string | |
| `body` | string \| null | |
| `cta_text` | string | |
| `cta_path` | string | |

### `cta-banner`
Full-width footer CTA — typically the last block before the footer. Has body copy + 1–2 CTAs.

| Prop | Type | Notes |
|---|---|---|
| `headline` | string | |
| `body` | string | |
| `cta_text` / `cta_path` | string | Primary CTA. |
| `secondary_cta_text` / `secondary_cta_path` | string \| null | Optional. |

---

## What's NOT in the palette (yet)

If your brief calls for any of these, open an issue first — engineering will ship the component before your template can land:

- Logo cloud / customer logo strip
- Stats bar / counter row
- Image gallery (more than the hero's single image)
- Comparison table
- Video embed
- Newsletter signup form
- Blog post grid (we use the existing `posts` content type instead)
- Calendar / booking embed (handled separately by SpiderBook)

---

## Visual tokens

All palette components use SpiderPublish's semantic Tailwind tokens. **Don't hardcode colors in component overrides** — the tokens auto-handle light + dark mode and tenant-level theming via `content_settings`.

| Token | Use for |
|---|---|
| `bg-bg` | Page background |
| `bg-surface` | Card / elevated surface |
| `bg-surface-elevated` | Modal / overlay surface |
| `text-fg` | Primary text |
| `text-fg-muted` | Secondary text |
| `text-fg-subtle` | Tertiary / placeholder text |
| `border-subtle` | Default border |
| `border-strong` | Emphasized border |
| `bg-success` / `text-success` | Success states (Publish button, "Live" badges) |
| `bg-warn` / `text-warn` | Warnings, gold-style accents |
| `bg-error` / `text-error` | Error states |

These resolve from the per-tenant `content_settings` columns (`primary_color`, `surface_color`, `body_text_color`, etc.) at render time. When a customer applies your template, their existing settings override yours for any keys not in `source_settings_keys`.

---

## See also

- [CONTRIBUTING-TEMPLATES.md](../CONTRIBUTING-TEMPLATES.md) — the full submission flow
- [_template-skeleton.json](./_template-skeleton.json) — manifest skeleton
- [components/](../components/) — JSON schemas for the existing public-component reference set (separate from this palette — those are agent-authoring examples, this palette is template-only)
