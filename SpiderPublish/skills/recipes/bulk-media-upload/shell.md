# bulk-media-upload — shell/curl variant

For agents or environments without a Node runtime. Pure POSIX-sh — no bashisms.

## Prerequisites

- `curl` — present on almost every system
- `jq` — used to parse upload responses. Install via `apt install jq` / `brew install jq` if missing.

## Usage

```sh
SPIDERIQ_TOKEN='cli_xxx:sk_xxx:secret_xxx'
SPIDERIQ_API_URL='https://spideriq.ai'
PID='cli_xxx'
FOLDER='campaign-2026-04'
SRC_DIR='./frames'

: > /tmp/uploads.json
echo '{' >> /tmp/uploads.json

first=1
for f in "$SRC_DIR"/*; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  resp=$(curl -sS -X POST "$SPIDERIQ_API_URL/api/v1/dashboard/projects/$PID/content/media/upload" \
    -H "Authorization: Bearer $SPIDERIQ_TOKEN" \
    -F "file=@$f" \
    -F "folder=$FOLDER")
  url=$(echo "$resp" | jq -r '.url // empty')
  if [ -n "$url" ]; then
    if [ $first -eq 0 ]; then echo ',' >> /tmp/uploads.json; fi
    first=0
    printf '  "%s": "%s"' "$name" "$url" >> /tmp/uploads.json
    echo "  uploaded $name" >&2
  else
    echo "  FAILED $name: $resp" >&2
  fi
done

echo '' >> /tmp/uploads.json
echo '}' >> /tmp/uploads.json
cat /tmp/uploads.json
```

## Output

A `{filename: public_url}` JSON map on stdout. Pipe it to `jq` to cherry-pick URLs for page-block props:

```sh
bash bulk-upload.sh > uploads.json
HERO_URL=$(jq -r '."hero.webp"' uploads.json)
```

## Notes

- Serial only — no concurrency. For 100+ files, use `impl.ts` (Tier 3) instead — it batches at 5 parallel.
- No retry logic. If the API throws 429 (rate limit), run the script again on the failed files.
- Content-Type is auto-detected by the backend from the file extension — include the extension in the filename.
