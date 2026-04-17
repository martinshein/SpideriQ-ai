# recipes/bulk-media-upload

Upload a local directory of files directly to the SpiderIQ CDN. Returns a `{filename: public_url}` map so you can reference uploaded assets programmatically.

**Kills the pinggy / serveo / localhost.run / catbox.moe workaround** — you don't need a public tunnel for local files. Just multipart-POST them.

## When to use

- You have 5+ local files to host on the CDN (screenshots, logos, pre-produced frames, bulk assets for a page).
- You need predictable filenames (the backend preserves your filename on multipart uploads — unlike `media_import_from_url`, which prepends a timestamp).
- You want each file's public URL back in the same call, for immediate reference in page blocks or component props.

## When NOT to use

- Scroll-sequence frames from a source video → use [recipes/scroll-sequence](../scroll-sequence/) instead. `extract_frames` produces predictably-named frames server-side without round-tripping through a local directory.
- Single file → just use `upload_file` directly, no recipe needed.
- Files you can already reach via a public URL → use `media_import_from_url` with the `urls: [...]` batch form.

## Files in this skill

- `SKILL.md` — this file
- `shell.md` — shell/curl loop for agents without a TS runtime
- `impl.ts` — self-contained Node 18+ TypeScript (uses native `fetch` + `fs`)

## Tier 3 TypeScript (`impl.ts`)

```bash
cd skills/recipes/bulk-media-upload
SPIDERIQ_TOKEN=cli_xxx:sk_xxx:secret_xxx \
  SPIDERIQ_PROJECT_ID=cli_xxx \
  FOLDER=campaign-2026-04 \
  npx tsx impl.ts ./path/to/local/dir/
```

Output (JSON on stdout):

```json
{
  "logo.png":    "https://media.cdn.spideriq.ai/clients/.../campaign-2026-04/logo.png",
  "banner.webp": "https://media.cdn.spideriq.ai/clients/.../campaign-2026-04/banner.webp"
}
```

An agent consuming this output would pipe it to `jq` or parse the JSON directly.

## Tier 2 shell/curl (`shell.md`)

See `shell.md` for a POSIX-sh loop that iterates a directory and curls each file. Slower (no concurrency) but runs in any shell without Node.

## Key rules

1. **Filenames are preserved** — the file's name on disk is the key in R2. So `frames/frame_0001.webp` → `{folder}/frame_0001.webp`. Use this for `sys-scroll-sequence` if you've pre-produced frames locally.
2. **Folder is flat** — don't use subdirectories in the `folder` param. If you want nesting, walk the directory tree yourself and include slashes in the `folder` value per file.
3. **Rate limit** — 100 requests/minute by default. The impl.ts batches with a small concurrency (5 parallel) to avoid tripping the limit.
4. **Content-Type** — auto-detected from file extension. Pass `content_type` explicitly if your file has no extension.

## Anti-patterns

- DON'T tunnel a local directory via pinggy/serveo/localhost.run and then call `media_import_from_url` against the tunnel URLs. Free tunnels inject HTML interstitials that get saved as `.webp` with 200 OK.
- DON'T upload to a third-party host (catbox.moe, raw.githubusercontent.com, imgur) and reference those URLs from your site. No tenant isolation, no CDN caching, eventual link rot.
- DON'T use `upload_base64` in a loop for 100+ files — the JSON-encoding overhead and the single-shot body limits make it slower than multipart. Multipart (this recipe) is the right choice.
