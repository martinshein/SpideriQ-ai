# upload-host-media

Upload and host files on the SpiderIQ CDN (Cloudflare R2, served via `media.cdn.spideriq.ai`). Also covers video import and processing status.

**Exposed via:** `@spideriq/mcp-publish`. Tool namespace: `upload_*`, `media_*`.

## When to use

- Uploading a local file (image, mp4, document) to the CDN
- Importing a file from a public URL
- Listing or deleting files the tenant has previously uploaded
- Checking processing status of a video import

## When NOT to use

- **Bulk upload from a local directory** → use [recipes/bulk-media-upload](../recipes/bulk-media-upload/) — it batches + returns a URL map in one call
- Producing scroll-sequence frames from a video → use SpiderVideo `extract_frames` (not this skill); see [recipes/scroll-sequence](../recipes/scroll-sequence/)
- Media library UI (managing assets in the dashboard) → that's a dashboard flow, not an MCP tool

## Common tool chains

| Goal | Chain |
|---|---|
| Upload a local file | `upload_file({file, folder})` → returns `{ url: "https://media.cdn.spideriq.ai/..." }` |
| Upload a base64 blob | `upload_base64({data, filename, folder})` |
| Import a public URL | `media_import_from_url({url, folder, filename?})` — supports batch via `urls: [...]` |
| List tenant files | `list_files({folder?, limit?})` |
| Delete a file | `delete_file({key})` |
| Import a video + get status | `media_import_video` → poll `media_get_video_status` |

## Key rules

1. `media_import_from_url` accepts a `filename` per item but the SpiderMedia backend currently prepends a timestamp (`YYYYMMDD_HHMMSS_`) to R2 keys. If you need predictable filenames for `sys-scroll-sequence` or similar, use `upload_file` (multipart) instead — it writes the key you ask for.
2. Use `folder` to group related assets: `folder="clients/{client_id}/campaign-2026-04/"`.
3. Returned URLs are public — no auth needed to view.
4. Files over 25MB go through a chunked path; same API, longer duration.

## Anti-patterns (see LEARNINGS.md "Media & Scroll-Sequences")

- Tunneling local files through pinggy / serveo / localhost.run to use with `media_import_from_url` → tunnels inject HTML interstitials that get saved as `.webp` with 200 OK
- Hosting site assets on catbox.moe / raw.githubusercontent.com → no tenant isolation, rate limits, link rot
- Hardcoding 100+ URLs in component JS — use `extract_frames` + `sys-scroll-sequence` pattern

## See also

- [recipes/bulk-media-upload](../recipes/bulk-media-upload/) — the preferred local-directory path
- [recipes/scroll-sequence](../recipes/scroll-sequence/) — video → frames (doesn't go through this skill; uses SpiderVideo directly)

## Upstream

Full opvsHUB source: [spideragent/skills/opvsHUB/skills/upload-host-media/](https://github.com/martinshein/SpiderIQ/tree/main/spideragent/skills/opvsHUB/skills/upload-host-media) (internal)
