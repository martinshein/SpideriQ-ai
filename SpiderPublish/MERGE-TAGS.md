# Merge Tags — SpiderPublish Personalization Cheat Sheet

> **Type `{{ firstname }}`, we fill it in per visitor.**

A Mailchimp-style merge-tag vocabulary for dynamic landing pages. Drop the same flat tokens you'd use in Mailchimp/HubSpot/ActiveCampaign/SendGrid emails into a Liquid template, and each visitor sees content personalized from their own CRM record.

**Live reference:** https://docs.spideriq.ai/site-builder/merge-tags/
**API endpoint:** `GET https://spideriq.ai/api/v1/content/variables?format=yaml` (no auth, ~3.8k tokens)
**MCP tool:** `content_get_variables` — tagged "START HERE for personalized landing pages" in `@spideriq/mcp-publish@0.1.0+` (atomic, recommended) and `@spideriq/mcp@0.8.3+` (kitchen sink)

---

## The 30-second pitch

1. Create a page with `template: "dynamic_landing"`.
2. Use merge tags in the Liquid body: `{{ firstname }}`, `{{ company_name }}`, `{{ city }}`, `{{ industry }}`, `{{ email }}`, `{{ logo }}`, `{{ rating }}`, …
3. Publish + deploy.
4. **Preview without real data:** `https://<your-domain>/lp/<slug>/demo` — serves a built-in Mario's Pizzeria fixture with every tag populated.
5. **Real URL per lead:** `https://<your-domain>/lp/<slug>/<google_place_id>` — Liquid renderer looks up the business via IDAP and fills every tag.

Merge tags only bind on `template: "dynamic_landing"`. On other templates (`default`, `landing`, `blank`) they render as empty strings — safe, just not useful.

---

## The 10 most common patterns

Copy-paste and tweak. All examples are MDX-safe (fenced code blocks).

### 1. Personal CTA opener

```liquid
<h1>Hey {{ firstname }} at {{ company_name }},</h1>
<p>We noticed your {{ rating }}★ rating in {{ city }}. We think we can help.</p>
<a href="mailto:{{ email }}" class="cta">Get in touch</a>
```

### 2. Logo + industry header

```liquid
<header class="hero">
  <img src="{{ logo }}" alt="{{ company_name }} logo" width="160">
  <div>
    <h1>{{ company_name }}</h1>
    <p>{{ industry }} · {{ team_size }} people · founded {{ founded }}</p>
  </div>
</header>
```

### 3. Review social proof

```liquid
<section>
  <div class="stars">
    {% if rating >= 4.5 %}★★★★★
    {% elsif rating >= 3.5 %}★★★★
    {% elsif rating >= 2.5 %}★★★
    {% else %}★★{% endif %}
  </div>
  <h2>{{ rating }}★ across {{ reviews_count }} reviews</h2>
  <p>{{ company_name }} is already the top {{ industry | downcase }} in {{ city }}.</p>
</section>
```

### 4. Pain points (SpiderSite AI-identified)

```liquid
<ul class="pain-points">
  {% for pain in pain_points %}
    <li>{{ pain }}</li>
  {% endfor %}
</ul>
```

### 5. Multi-email contact list

```liquid
<ul class="emails">
  {% for email in emails %}
    <li>
      <a href="mailto:{{ email.address }}">{{ email.address }}</a>
      {% if email.deliverable %}✓ verified{% endif %}
      <small>({{ email.status }})</small>
    </li>
  {% endfor %}
</ul>
```

### 6. Team cards

```liquid
<ul class="team">
  {% for contact in contacts %}
    <li>
      {% if contact.photo %}<img src="{{ contact.photo }}" width="40">{% endif %}
      <strong>{{ contact.full_name }}</strong> — {{ contact.position }}
      {% if contact.linkedin_url %}
        · <a href="{{ contact.linkedin_url }}">LinkedIn</a>
      {% endif %}
    </li>
  {% endfor %}
</ul>
```

### 7. Registry officers (EU / US companies)

```liquid
{% if officers %}
  <h3>Leadership on record at {{ legal_name }}</h3>
  <ul>
    {% for officer in officers %}
      <li>{{ officer.name }} — {{ officer.role }}</li>
    {% endfor %}
  </ul>
{% endif %}
```

### 8. Conditional-by-rating CTA

```liquid
{% if rating >= 4.5 %}
  <p>You're crushing it, {{ firstname }}. Let us help you scale.</p>
{% elsif rating >= 3.5 %}
  <p>You're doing well. Here's how we help {{ company_name }} hit 4.5★.</p>
{% else %}
  <p>We noticed room to grow. Let's talk about what's possible.</p>
{% endif %}
```

### 9. Call-buttons with fallback

```liquid
<div class="contact-buttons">
  {% if phone %}<a href="tel:{{ phone }}">Call {{ company_name }}</a>{% endif %}
  {% if mobile %}<a href="sms:{{ mobile }}">Text {{ firstname }}</a>{% endif %}
  {% if website %}<a href="{{ website }}">{{ domain }}</a>{% endif %}
</div>
```

### 10. Safe-default with `| default:`

```liquid
<h1>{{ firstname | default: "Hi there" }} — welcome to our proposal.</h1>
<p>We've prepared this for {{ company_name | default: "your business" }}.</p>
<p>Annual revenue: {{ revenue | default: "[not on file]" }}.</p>
```

---

## Full reference (auto-generated)

<!-- SOURCE: apps/liquid-renderer/merge-tags.spec.json -->

**Spec version:** 1.0.0 · Authoritative reference: https://docs.spideriq.ai/site-builder/merge-tags/

### Company

| Tag | What | Example |
|-----|------|---------|
| `{{ company_name }}` | Business name (Google Maps) | `Mario's Pizzeria` |
| `{{ legal_name }}` | Registered legal name (falls back to company_name) | `Mario's Pizzeria LLC` |
| `{{ industry }}` | Industry classification | `Restaurants & Food Service` |
| `{{ description }}` | Short marketing description | `Family-owned Neapolitan pizzeria…` |
| `{{ website }}` | Primary website URL | `https://mariospizzeria.com` |
| `{{ domain }}` | Domain (no scheme) | `mariospizzeria.com` |
| `{{ logo }}` | Logo URL (domain crawl > Maps photo) | `…/logo.png` |
| `{{ photo }}` | Hero photo | `…/storefront.jpg` |
| `{{ rating }}` | Google Maps rating 0-5 | `4.6` |
| `{{ reviews_count }}` | Total reviews | `234` |
| `{{ lead_score }}` | SpiderSite lead score 0-1 | `0.87` |
| `{{ place_id }}` | Google Place ID | `ChIJd8BlQ2BZwokRAFUEcm_qrcA` |
| `{{ vat_number }}` | VAT / tax registration | `GB123456789` |
| `{{ registration_number }}` | Companies House / SEC / SunBiz # | `L98000004231` |

### Contact (top person — owner/founder/exec preferred)

| Tag | What | Example |
|-----|------|---------|
| `{{ firstname }}` | First name | `Alessandro` |
| `{{ lastname }}` | Last name | `Romano` |
| `{{ full_name }}` | Full name | `Alessandro Romano` |
| `{{ job_title }}` | Position | `Owner & Head Chef` |
| `{{ email }}` | Best verified email | `info@mariospizzeria.com` |
| `{{ phone }}` | Main phone (E.164) | `+13055551234` |
| `{{ mobile }}` | Mobile phone (E.164) | `+13055559876` |
| `{{ linkedin_url }}` | LinkedIn profile | `https://linkedin.com/in/…` |

### Location

| Tag | Example |
|-----|---------|
| `{{ address }}` | `2341 Collins Ave` |
| `{{ city }}` | `Miami Beach` |
| `{{ region }}` / `{{ state }}` | `Florida` |
| `{{ country }}` / `{{ country_code }}` | `United States` / `US` |
| `{{ postal_code }}` / `{{ zip }}` | `33139` |

### Vitals

| Tag | Example |
|-----|---------|
| `{{ team_size }}` | `24` |
| `{{ founded }}` | `1998` |
| `{{ revenue }}` | `2840000` |

### Arrays (for `{% for %}` loops)

| Tag | Projection | Example use |
|-----|------------|-------------|
| `{{ emails }}` | `{ address, status, score, deliverable }` | `{% for e in emails %}{{ e.address }}{% endfor %}` |
| `{{ phones }}` | `{ number, type, carrier, valid }` | `{% for p in phones %}{{ p.number }}{% endfor %}` |
| `{{ contacts }}` | `{ firstname, lastname, full_name, email, position, linkedin_url, photo }` | `{% for c in contacts %}…{% endfor %}` |
| `{{ officers }}` | `{ name, role, appointed, resigned, nationality }` | `{% for o in officers %}…{% endfor %}` |
| `{{ categories }}` | `string[]` | `{% for cat in categories %}…{% endfor %}` |
| `{{ pain_points }}` | `string[]` | `{% for p in pain_points %}…{% endfor %}` |

**Full reference** with every selection rule: `curl https://spideriq.ai/api/v1/content/variables?format=yaml` (3.8k tokens, includes the authoritative picker logic for every tag).

---

## How tags with multiple candidates pick

| Tag | Rule |
|---|---|
| `{{ email }}` | Sort by status rank (`deliverable > unknown > risky > catch_all`) → highest `score` → most recent `last_verified_at`. First result wins. |
| `{{ firstname }}` / `{{ lastname }}` / `{{ full_name }}` / `{{ job_title }}` | Prefer contacts whose `position` matches `/(ceo|founder|owner|president|director|head|chief|principal|managing partner)/i`; else first contact. |
| `{{ phone }}` | Prefer `businesses.phone_e164`; else first valid phone in `related.phones`. |
| `{{ mobile }}` | First phone with `phone_type = "mobile"`; empty if none. |
| `{{ logo }}` | Prefer `domains[0].logo_url` (from SpiderSite crawl); else `businesses.image_url`. |
| `{{ industry }}` | Prefer `domains[0].company_vitals.industry`; else `businesses.categories[0]`. |
| `{{ team_size }}` | Prefer `domains[0].company_vitals.team_size`; else `company_registry.financials.employees`. |
| `{{ founded }}` | Prefer `domains[0].company_vitals.founded`; else year from `company_registry.incorporation_date`. |
| `{{ legal_name }}` | `company_registry.name` else `businesses.name`. |
| `{{ city }}` | `businesses.city` else `company_registry.city`. |
| `{{ linkedin_url }}` | Top contact's `linkedin_url` else `linkedin_profiles[0].linkedin_url`. |

---

## Null safety

Every singular returns `""` (empty string) when the source is missing. Every array returns `[]`. Templates never throw.

- `{% if revenue %}` branches correctly when revenue is missing (empty string is falsy in Liquid).
- `{{ revenue | default: "not on file" }}` gives a graceful fallback.
- `{% for pain in pain_points %}…{% else %}<p>Nothing discovered yet.</p>{% endfor %}` handles empty arrays with the else clause.

---

## Testing with the demo fixture

Before any real scraping has happened, preview every merge tag against a built-in fixture:

```
https://<your-domain>/lp/<your-slug>/demo
https://<your-domain>/lp/<your-slug>/?preview=sample-lead
```

The demo dataset is **Mario's Pizzeria** in Miami Beach — 4.6★ / 234 reviews, 3 contacts (owner + GM + sous chef), 4 emails at all 4 verification states (so your `{% if email.deliverable %}` conditionals can be tested), 2 phones, full `company_vitals`, `company_registry` with 3 officers + financials, 1 LinkedIn profile. Every merge tag binds to a realistic value.

Safe to share internally; every tenant's demo URL shows the same fixture.

---

## Power user: the raw `lead` object

Merge tags are a flat surface over the full IDAP response. For anything not surfaced — e.g. `company_vitals.tech_stack[]` — the raw nested shape is still in scope:

```liquid
{% for tech in lead.related.domains[0].company_vitals.tech_stack %}
  <span class="tech-pill">{{ tech }}</span>
{% endfor %}
```

Both surfaces are always available.

---

## Discovery

- **REST:** `GET https://spideriq.ai/api/v1/content/variables?format=yaml`
- **MCP:** `content_get_variables` (shipped in `@spideriq/mcp-publish@0.1.0+` and `@spideriq/mcp@0.8.3+`, no auth for this specific tool)
- **Public docs:** https://docs.spideriq.ai/site-builder/merge-tags/ — the full Docusaurus page with syntax highlighting + search
- **Complete example:** `examples/personalized-landing.sh` — end-to-end script that creates + publishes + deploys a personalized landing page using the demo fixture

---

Part of the [SpiderPublish starter kit](https://github.com/martinshein/SpideriQ-ai/tree/main/SpiderPublish). See `CLAUDE.md` and `AGENTS.md` for the full agent-first authoring guide.
