/**
 * recipes/bulk-media-upload — Tier 3 self-contained TypeScript.
 *
 * Upload every file in a local directory to the SpiderIQ CDN via multipart POST
 * to /dashboard/projects/{pid}/content/media/upload. Returns a {filename: url}
 * JSON map on stdout.
 *
 * Zero external dependencies. Node 18+ native fetch + fs + path only.
 *
 * Usage:
 *   SPIDERIQ_TOKEN=cli_xxx:sk_xxx:secret_xxx \
 *   SPIDERIQ_PROJECT_ID=cli_xxx \
 *   SPIDERIQ_API_URL=https://spideriq.ai \
 *   FOLDER=campaign-2026-04 \
 *   npx tsx impl.ts ./path/to/local/dir
 *
 *   Optional: CONCURRENCY (default 5), RECURSIVE (default false).
 */

import { readdir, readFile, stat } from "node:fs/promises";
import { basename, extname, join } from "node:path";

const {
  SPIDERIQ_TOKEN: TOKEN,
  SPIDERIQ_PROJECT_ID: PID,
  SPIDERIQ_API_URL: API_URL = "https://spideriq.ai",
  FOLDER = "",
  CONCURRENCY = "5",
  RECURSIVE = "false",
} = process.env;

const SRC = process.argv[2];

if (!TOKEN || !PID || !SRC) {
  console.error(
    "Usage: SPIDERIQ_TOKEN=... SPIDERIQ_PROJECT_ID=... npx tsx impl.ts <dir>"
  );
  process.exit(1);
}

const API = `${API_URL}/api/v1`;
const UPLOAD_URL = `${API}/dashboard/projects/${encodeURIComponent(PID)}/content/media/upload`;
const CONCURRENCY_N = Math.max(1, Number(CONCURRENCY));
const RECURSE = RECURSIVE === "true";

const MIME_BY_EXT: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".mp4": "video/mp4",
  ".webm": "video/webm",
  ".pdf": "application/pdf",
  ".json": "application/json",
  ".txt": "text/plain",
};

async function walk(dir: string): Promise<string[]> {
  const files: string[] = [];
  const entries = await readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      if (RECURSE) files.push(...(await walk(full)));
      continue;
    }
    if (e.isFile()) files.push(full);
  }
  return files;
}

async function uploadOne(
  path: string
): Promise<{ filename: string; url?: string; error?: string }> {
  const name = basename(path);
  const ext = extname(name).toLowerCase();
  const mime = MIME_BY_EXT[ext] ?? "application/octet-stream";
  const bytes = await readFile(path);

  // Build multipart body manually — avoids the formdata-node dep on older Node.
  const form = new FormData();
  form.append("file", new Blob([bytes], { type: mime }), name);
  if (FOLDER) form.append("folder", FOLDER);

  try {
    const res = await fetch(UPLOAD_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${TOKEN}` },
      body: form,
    });
    if (!res.ok) {
      return { filename: name, error: `${res.status} ${await res.text()}` };
    }
    const body = (await res.json()) as { url?: string };
    return { filename: name, url: body.url };
  } catch (e: unknown) {
    return { filename: name, error: String(e) };
  }
}

async function pool<T, R>(
  items: T[],
  n: number,
  fn: (item: T) => Promise<R>
): Promise<R[]> {
  const results: R[] = [];
  let i = 0;
  const workers = Array.from({ length: n }, async () => {
    while (i < items.length) {
      const idx = i++;
      results[idx] = await fn(items[idx]);
    }
  });
  await Promise.all(workers);
  return results;
}

async function main() {
  const s = await stat(SRC);
  if (!s.isDirectory()) {
    console.error(`${SRC} is not a directory`);
    process.exit(1);
  }
  const files = await walk(SRC);
  if (files.length === 0) {
    console.error(`no files in ${SRC}`);
    process.exit(1);
  }
  console.error(
    `uploading ${files.length} file(s) at concurrency=${CONCURRENCY_N}...`
  );

  const results = await pool(files, CONCURRENCY_N, uploadOne);

  const map: Record<string, string> = {};
  let fails = 0;
  for (const r of results) {
    if (r.url) {
      map[r.filename] = r.url;
    } else {
      console.error(`  FAILED ${r.filename}: ${r.error}`);
      fails++;
    }
  }
  console.error(`done. ${Object.keys(map).length} uploaded, ${fails} failed.`);

  process.stdout.write(JSON.stringify(map, null, 2) + "\n");
  if (fails > 0) process.exit(2);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
