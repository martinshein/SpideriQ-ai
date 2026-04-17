# recipes/scroll-sequence

Cinematic scroll-scrubbed hero from a source video — the cheap way. Replaces the "roll your own" trap that costs agents 12 hours and produces black-frame bugs.

## The 5-step recipe

1. **Upload source video** (or reference one already in R2).
   Tool: `upload_file` / `media_import_from_url`
   Output: `https://media.cdn.spideriq.ai/clients/{cid}/path/source.mp4`

2. **Submit `extract_frames` job.**
   Tool: `submit_job(type="spiderVideo", payload={action:"extract_frames", ...})`
   Key params:
   - `video_url` — the mp4 from step 1
   - `strategy` — `"target_frames"` (default 120), `"fps"` (fixed N per second), or `"duration_fps"`
   - `output_format` — `"webp"` (recommended — 7× smaller than JPEG)

3. **Poll until completion.**
   Tool: `get_job_results(job_id)`
   Status: `completed` → manifest lives at `data.manifest = { base_url, pattern, count }`

4. **Create the page with a `sys-scroll-sequence` block.**
   Tool: `content_create_page` or `content_update_page`
   Block shape:
   ```json
   {
     "type": "component",
     "component_slug": "sys-scroll-sequence",
     "props": {
       "base_url": "<from manifest>",
       "pattern":  "<from manifest>",
       "count":    <from manifest>,
       "scroll_distance_vh": 400,
       "preload_strategy": "progressive"
     }
   }
   ```

5. **Publish + deploy.**
   - `content_publish_page` (dry_run → confirm_token)
   - `content_deploy_site_preview` → open `preview_url`, verify scroll
   - `content_deploy_site_production(confirm_token)`

## Why not roll your own?

- `sys-scroll-sequence` v1.0.0 is Tier 3 (deps: gsap + ScrollTrigger) and handles canvas setup, sticky positioning, GSAP wiring, progressive preload (±15 frame window) — all of it.
- Hardcoding 100+ URLs in a custom component triggers CDN rate-limit drops → black-frame "flashlight strobe" during scroll.
- Tier 3 CDN deps (gsap, ScrollTrigger) are deduplicated globally — your component doesn't pay load cost twice.

## Files in this skill

- `SKILL.md` — this file (human-readable recipe)
- `schema.yaml` — Tier 2 MCP-call sequence (structured for tool-consumers)
- `impl.ts` — Tier 3 self-contained TypeScript against `@spideriq/core`

## Recommended frame counts

| Scroll section length | Frames | Strategy |
|---|---|---|
| Short hero (~400vh) | 90-120 | `target_frames: 120` |
| Medium hero (~600vh) | 120-180 | `target_frames: 150` |
| Long cinematic (1000vh+) | 180-240 | `target_frames: 200` |

More than 240 frames: consider splitting into two sequences or using a video instead.

## See also

- [AGENTS.md → Scroll-Linked Hero](../../../AGENTS.md#scroll-linked-hero-image-sequence--use-sys-scroll-sequence)
- [LEARNINGS.md → Media & Scroll-Sequences](../../../LEARNINGS.md#media--scroll-sequences)
- [examples/scroll-sequence.sh](../../../examples/scroll-sequence.sh) — runnable bash version
- [components/scroll-sequence.json](../../../components/scroll-sequence.json) — block-config reference
