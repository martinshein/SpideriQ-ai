/**
 * recipes/scroll-sequence — Tier 3 self-contained TypeScript recipe.
 *
 * Preferred path (v2.87.0+): calls the single `/scroll-sequence/from-video`
 * endpoint, which wraps extract_frames + block insertion server-side.
 * Then orchestrates preview + confirm_token + production deploy.
 *
 * Zero external dependencies — Node 18+ fetch only. Copy-paste into any
 * agent sandbox (Claude Code, Cursor, Antigravity, plain Node) and run.
 *
 * Usage:
 *   SPIDERIQ_TOKEN=cli_xxx:sk_xxx:secret_xxx \
 *   SPIDERIQ_PROJECT_ID=cli_xxx \
 *   SPIDERIQ_API_URL=https://spideriq.ai \
 *   VIDEO_URL=https://media.cdn.spideriq.ai/.../source.mp4 \
 *   PAGE_SLUG=home \
 *   npx tsx impl.ts
 *
 *   Optional: TARGET_FRAMES (default: 120), POSITION (default: append)
 */

type Json = Record<string, unknown>;

const {
  SPIDERIQ_TOKEN: TOKEN,
  SPIDERIQ_PROJECT_ID: PID,
  SPIDERIQ_API_URL: API_URL = "https://spideriq.ai",
  VIDEO_URL,
  PAGE_SLUG,
  TARGET_FRAMES = "120",
  POSITION = "append",
} = process.env;

if (!TOKEN || !PID || !VIDEO_URL || !PAGE_SLUG) {
  console.error(
    "Missing env. Set SPIDERIQ_TOKEN, SPIDERIQ_PROJECT_ID, VIDEO_URL, PAGE_SLUG."
  );
  process.exit(1);
}

const API = `${API_URL}/api/v1`;
const headers = {
  Authorization: `Bearer ${TOKEN}`,
  "Content-Type": "application/json",
};

async function http<T = Json>(
  method: string,
  path: string,
  body?: Json
): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    throw new Error(`${method} ${path} → ${res.status} ${await res.text()}`);
  }
  return (await res.json()) as T;
}

function parsePosition(p: string): unknown {
  if (p === "append" || p === "prepend") return p;
  try {
    return JSON.parse(p);
  } catch {
    return p;
  }
}

async function run() {
  console.log(`[1/4] building scroll-sequence block from ${VIDEO_URL}`);
  const result = await http<{
    job_id: string;
    manifest: { base_url: string; pattern: string; count: number };
    page: { slug: string; status: string };
  }>(
    "POST",
    `/dashboard/projects/${PID}/scroll-sequence/from-video`,
    {
      video_url: VIDEO_URL,
      page_slug: PAGE_SLUG,
      target_frames: Number(TARGET_FRAMES),
      position: parsePosition(POSITION),
    }
  );
  console.log(
    `      job_id=${result.job_id}  frames=${result.manifest.count}  page=${result.page.slug}`
  );

  console.log(`[2/4] deploying preview`);
  const preview = await http<{ preview_url: string; confirm_token: string }>(
    "POST",
    `/dashboard/projects/${PID}/content/deploy/preview`
  );
  console.log(`      preview: ${preview.preview_url}`);

  console.log(
    `[3/4] verify the preview in a browser. Press ENTER to promote, Ctrl-C to abort.`
  );
  await new Promise((r) => process.stdin.once("data", r));

  console.log(`[4/4] promoting to production`);
  const prod = await http<{ status: string; version_id: number }>(
    "POST",
    `/dashboard/projects/${PID}/content/deploy/production?confirm_token=${preview.confirm_token}`
  );
  console.log(`      status: ${prod.status}, version: ${prod.version_id}`);
  console.log(
    `\nDone. Check /${PAGE_SLUG} on your primary domain once edge caches flush (~60s).`
  );
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
