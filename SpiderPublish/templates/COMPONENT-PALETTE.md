# Component Palette

The reusable section types you compose templates from.

Every component in this palette is shipped as `is_global=true` on the SpiderIQ-owned source tenant, which means **every** template in the gallery references the same instance — no per-template forks. When engineering ships a fix to (say) `pricing-3tier`, every template that uses it gets the fix.

Designers compose templates from this palette. **Don't invent new section types** — if you need a section that's not here, open an issue titled `component: <name>` so engineering can add it before your template ships.

> **Phase C palette (2026-04-26)**: 30 sections across 11 categories, 12 of which are featured (surfaced first on the section library). All sections are also browsable + insertable via the dashboard at `/dashboard/content/sections-library`.

---

## Header / Footer

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

### `footer-rich` *(new in Phase C)*
Content-heavy footer: brand block + 4 link columns + newsletter signup + bottom legal row. Use when `footer-minimal` isn't doing enough work.

| Prop | Type | Notes |
|---|---|---|
| `brand_name` / `brand_tagline` | string | Top-left brand block. |
| `newsletter_action` | string \| null | Form POST URL. Omit to hide the signup. |
| `newsletter_placeholder` / `newsletter_submit` | string | |
| `columns` | `[{ heading, items: [{ label, path }] }]` | 2–4 columns. |
| `social` | `[{ platform, url }]` | |
| `copyright_text` | string | |

---

## Hero

### `hero-headline`
Text-only hero — headline, subheadline, single (or dual) CTA. No image.

| Prop | Type | Notes |
|---|---|---|
| `headline` | string | Max ~80 chars to render well on mobile. |
| `subheadline` | string | One sentence. Aim for ~120 chars. |
| `cta_text` / `cta_path` | string | |
| `secondary_cta_text` | string \| null | Optional. Renders as ghost button next to primary. |
| `secondary_cta_path` | string \| null | |
| `eyebrow` | string \| null | Tiny label above headline ("New", "v2.0", etc.) |

### `hero-with-image`
Two-column hero — copy + CTA on left, image on right.

| Prop | Type | Notes |
|---|---|---|
| `headline` / `subheadline` | string | |
| `cta_text` / `cta_path` | string | |
| `image_url` | string | 800×600 minimum. PNG, JPG, or WebP. |
| `image_alt` | string | Accessibility — required. |

### `hero-video-bg` *(new in Phase C)*
Full-bleed hero with a muted looping background video, centered headline, primary CTA. Self-contained (includes its own `<video>`).

| Prop | Type | Notes |
|---|---|---|
| `video_url` | string | MP4. Use a curated bg-video's `r2_url`, or your own. |
| `poster_url` | string \| null | First-frame JPEG. |
| `headline` / `cta_text` / `cta_path` | string | |
| `subheadline` / `eyebrow` | string \| null | |

### `hero-split-cta` *(new in Phase C)*
Two-column hero with **two** CTAs side-by-side (signup + book-a-demo, free + paid, etc.) and an illustration panel.

| Prop | Type | Notes |
|---|---|---|
| `headline` / `subheadline` | string | |
| `primary_cta_text` / `primary_cta_path` | string | |
| `secondary_cta_text` / `secondary_cta_path` | string | |
| `image_url` / `image_alt` | string \| null | Optional right-panel image. |
| `eyebrow` | string \| null | |

### `hero-stats-inline` *(new in Phase C)*
Centered hero with headline + CTA, followed by a 2–4 column stats strip.

| Prop | Type | Notes |
|---|---|---|
| `headline` / `subheadline` / `cta_text` / `cta_path` | string | |
| `stats` | `[{ value, label }]` | 2–4 items. e.g. `{value: "99.99%", label: "Uptime SLA"}`. |

### `hero-with-bg-video` *(new in Phase C)*
**Transparent** hero designed to sit on top of `sys-bg-video`. Use this when you want the SAME bg video to back multiple blocks (header → hero → cta).

| Prop | Type | Notes |
|---|---|---|
| `headline` / `cta_text` / `cta_path` | string | |
| `subheadline` / `eyebrow` | string \| null | |

---

## Features

### `features-3col`
Three-column feature grid. Each cell: icon + heading + body.

| Prop | Type | Notes |
|---|---|---|
| `section_title` / `section_subtitle` | string \| null | Optional. |
| `features` | `[{ icon, heading, body }]` | Exactly 3, 6, or 9 items. |

`icon` values: any [lucide-react](https://lucide.dev/icons/) icon name (lowercase, kebab-case). E.g. `"zap"`, `"shield-check"`, `"chart-bar"`.

### `features-icon-list`
Vertical icon list — better for 5+ features that don't fit a grid.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | |
| `features` | `[{ icon, heading, body }]` | 4–8 items typical. |

### `features-2col-large` *(new in Phase C)*
Two larger feature panels with image + heading + body, side-by-side. Better than 3-col when each pillar deserves its own visual.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | |
| `features` | `[{ image_url?, image_alt?, heading, body, cta_text?, cta_path? }]` | Exactly 2. |

### `features-checklist` *(new in Phase C)*
Vertical checkmark list — for plan-comparison or "everything you get" sections. Single column, dense.

| Prop | Type | Notes |
|---|---|---|
| `section_title` / `section_subtitle` | string \| null | |
| `items` | `string[]` | 1–N items. |

---

## Pricing

### `pricing-3tier`
Three-tier pricing card row. The middle tier renders highlighted.

| Prop | Type | Notes |
|---|---|---|
| `section_title` / `section_subtitle` | string | |
| `tiers` | `[{ name, price, period, features: string[], cta_text, cta_path, highlighted? }]` | Exactly 3. Set `highlighted: true` on the middle tier. |

### `pricing-toggle` *(new in Phase C)*
Three-tier pricing card row with a CSS-only monthly/annual price switch. No JS.

| Prop | Type | Notes |
|---|---|---|
| `section_title` / `section_subtitle` | string \| null | |
| `annual_save_label` | string \| null | "Save 20%" badge text. |
| `tiers` | `[{ name, price_monthly, price_annual, features: string[], cta_text, cta_path, highlighted? }]` | Exactly 3. |

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
| `author_name` / `author_title` | string | |
| `author_photo_url` | string \| null | |

### `logo-cloud` *(new in Phase C)*
Single-row strip of customer logos with optional eyebrow ("Trusted by teams at..."). Place under the hero for instant credibility.

| Prop | Type | Notes |
|---|---|---|
| `eyebrow` | string \| null | "Trusted by teams at" etc. |
| `logos` | `[{ image_url, alt, url? }]` | 4–12 items. |

### `stats-bar` *(new in Phase C)*
Full-width band of 3–4 large stats. Use mid-page to break up text-heavy sections.

| Prop | Type | Notes |
|---|---|---|
| `stats` | `[{ value, label }]` | 2–4 items. |

### `customer-quotes-carousel` *(new in Phase C)*
Horizontal scroll-snap testimonial row — touch-friendly, swipes naturally on mobile, no JS.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | |
| `quotes` | `[{ quote, author_name, author_title, author_photo_url? }]` | 2+ items. |

---

## Content

### `content-rich-text` *(new in Phase C)*
Centered prose column with typographic styles for h2/h3/blockquote/lists. Use for "About", "Manifesto", or long-form sections.

| Prop | Type | Notes |
|---|---|---|
| `eyebrow` | string \| null | |
| `html_content` | string | Arbitrary HTML — h2/h3/p/blockquote/ul/ol/li/img/a all styled. |

### `content-image-grid` *(new in Phase C)*
Responsive image grid with optional captions. 3-up desktop, 2-up tablet, 1-up mobile.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | |
| `images` | `[{ url, alt, caption? }]` | 3+ items. |

### `content-comparison-table` *(new in Phase C)*
Side-by-side feature comparison table. "Us vs them", plan tiers, or product variants.

| Prop | Type | Notes |
|---|---|---|
| `section_title` | string \| null | |
| `columns` | `string[]` | Header labels. |
| `rows` | `[{ feature, values: string[] }]` | `values.length` should match `columns.length`. |

---

## Forms

### `contact-form` *(new in Phase C)*
Two-column layout: copy on the left, name/email/message form on the right. POSTs to the URL you specify.

| Prop | Type | Notes |
|---|---|---|
| `headline` / `body` | string | |
| `email` | string \| null | Surfaced as a "Or email us at" line. |
| `submit_text` | string | |
| `action_url` | string | Form POST endpoint. |

### `newsletter-signup` *(new in Phase C)*
Centered single-row email input + subscribe button. Use mid-page or in `footer-rich`.

| Prop | Type | Notes |
|---|---|---|
| `headline` / `body` / `submit_text` / `action_url` | string | |
| `placeholder` | string \| null | Default: "you@company.com" |
| `fineprint` | string \| null | "Unsubscribe any time." etc. |

---

## Team / About

### `team-grid` *(new in Phase C)*
Headshot + name + role grid for team or about pages. 4-up desktop, 2-up tablet, 1-up mobile.

| Prop | Type | Notes |
|---|---|---|
| `section_title` / `section_subtitle` | string \| null | |
| `members` | `[{ name, role, photo_url, bio? }]` | 1+ items. |

### `about-story` *(new in Phase C)*
Two-column narrative — image on one side, headline + paragraphs on the other. For "About us", "Our story", "Why we built this".

| Prop | Type | Notes |
|---|---|---|
| `eyebrow` | string \| null | |
| `image_url` / `image_alt` / `headline` | string | |
| `paragraphs` | `string[]` | 1+ items. |
| `cta_text` / `cta_path` | string \| null | |

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
| `cta_text` / `cta_path` | string | |

### `cta-banner`
Full-width footer CTA — typically the last block before the footer. Has body copy + 1–2 CTAs.

| Prop | Type | Notes |
|---|---|---|
| `headline` / `body` | string | |
| `cta_text` / `cta_path` | string | Primary CTA. |
| `secondary_cta_text` / `secondary_cta_path` | string \| null | Optional. |

---

## System (special-purpose wrappers)

### `sys-bg-video` *(new in Phase C)*
Wraps arbitrary children in a full-bleed background video. Pair with `hero-with-bg-video` (or any other transparent block) when you want the SAME video to back multiple blocks.

| Prop | Type | Notes |
|---|---|---|
| `video_slug` | string \| null | Reference a clip from the curated catalog. Resolved by the renderer to `video_url + poster_url`. If both `video_slug` and `video_url` are provided, `video_url` wins. |
| `video_url` | string \| null | Direct MP4 URL — bypasses the catalog. |
| `poster_url` | string \| null | |
| `overlay_color` | string \| null | CSS color for the dim overlay. Default: `#000000`. |
| `overlay_opacity` | number \| null | 0–1. Default: `0.45`. |
| `min_height_vh` | int \| null | Viewport-height percentage. Default: `80`. |
| `children_html` | string \| null | Pre-rendered HTML to drop into the content layer. |

---

## Background-Video Catalog

12 curated clips you can use directly via `hero-video-bg.video_url` or `sys-bg-video.video_slug`. Browse the catalog at `/dashboard/content/bg-videos-library`.

| Slug | Category | Description |
|---|---|---|
| `nature-coastal-waves` ⭐ | nature | Slow rolling waves on a sandy beach. |
| `nature-forest-canopy` | nature | Sunlight filtering through a forest canopy. |
| `nature-mountain-mist` | nature | Mist rolling across a mountain ridge at dawn. |
| `city-aerial-night` ⭐ | city | Top-down drone shot of a city at night. |
| `city-rainy-street` | city | Empty street, neon glow, reflections. |
| `abstract-gradient-flow` ⭐ | abstract | Slow morphing color gradient — brand-neutral. |
| `abstract-particles` | abstract | Drifting bokeh particles on dark background. |
| `food-pour-coffee` | food | Slow-motion espresso pour. |
| `tech-circuit-board` | tech | Macro pan across a glowing circuit board. |
| `tech-server-rack` ⭐ | tech | Slow dolly along server racks, status LEDs. |
| `people-team-meeting` | people | Over-the-shoulder team around a laptop. |
| `people-keyboard-typing` | people | Top-down close-up of mechanical-keyboard typing. |

⭐ = featured.

To add a new clip to the catalog, open an issue titled `bg-video: <slug>` with the source license, dimensions, and a 60-second preview link.

---

## What's NOT in the palette (yet)

If your brief calls for any of these, open an issue first — engineering will ship the component before your template can land:

- Image gallery / lightbox (more than the hero's single image or `content-image-grid`)
- Video embed (single inline video, not background)
- Blog post grid (we use the existing `posts` content type instead)
- Calendar / booking embed (handled separately by SpiderBook)
- Map embed (Google Maps / Mapbox)
- Code playground / live demo
- Author bio block (separate from `team-grid`)

---

## See also

- [CONTRIBUTING-TEMPLATES.md](../CONTRIBUTING-TEMPLATES.md) — the full submission flow
- [_template-skeleton.json](./_template-skeleton.json) — manifest skeleton
- [components/](../components/) — JSON schemas for the existing public-component reference set (separate from this palette — those are agent-authoring examples, this palette is template-only)
