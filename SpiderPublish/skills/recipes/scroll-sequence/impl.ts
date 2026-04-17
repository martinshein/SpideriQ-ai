/**
 * recipes/scroll-sequence — Tier 3 self-contained TypeScript recipe.
 *
 * Takes a source video URL, runs SpiderVideo extract_frames, builds a page with
 * a sys-scroll-sequence block, publishes, and deploys preview + production.
 *
 * Zero external dependencies — Node 18+ fetch only. Copy-paste into any
 * agent sandbox (Claude Code, Cursor, Antigravity, plain Node) and run.
 *
 * Usage:
 *   SPIDERIQ_TOKEN=cli_xxx:sk_xxx:secret_xxx \
 *   SPIDERIQ_PROJECT_ID=cli_xxx \
 *   SPIDERIQ_API_URL=https://spideriq.ai \
 *   VIDEO_URL=https://media.cdn.spideriq.ai/.../source.mp4 \
 *   npx tsx impl.ts
 *
 *   Optional: PAGE_SLUG (default: scroll-hero), TARGET_FRAMES (default: 120)
 */

type Json = Record<string, unknown>;

const {
  SPIDERIQ_TOKEN: TOKEN,
  SPIDERIQ_PROJECT_ID: PID,
  SPIDERIQ_API_URL: API_URL = "https://spideriq.ai",
  VIDEO_URL,
  PAGE_SLUG = "scroll-hero",
  TARGET_FRAMES = "120",
} = process.env;

if (!TOKEN || !PID || !VIDEO_URL) {
  console.error(
    "Missing env. Set SPIDERIQ_TOKEN, SPIDERIQ_PROJECT_ID, VIDEO_URL."
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

async function run() {
  console.log(`[1/7] submitting extract_frames job`);
  const job = await http<{ job_id: string }>("POST", "/jobs/spiderVideo/submit", {
    payload: {
      action: "extract_frames",
      video_url: VIDEO_URL,
      strategy: "target_frames",
      target_frames: Number(TARGET_FRAMES),
      output_format: "webp",
    },
  });
  console.log(`      job_id: ${job.job_id}`);

  console.log(`[2/7] polling until completed...`);
  let manifest: { base_url: string; pattern: string; count: number } | null = null;
  const deadline = Date.now() + 10 * 60 * 1000;
  while (Date.now() < deadline) {
    const status = await http<{ status: string }>(
      "GET",
      `/jobs/${job.job_id}/status`
    );
    if (status.status === "completed") {
      const result = await http<{ data: { manifest: typeof manifest } }>(
        "GET",
        `/jobs/${job.job_id}/results`
      );
      manifest = result.data.manifest!;
      break;
    }
    if (status.status === "failed") throw new Error("extract_frames failed");
    await new Promise((r) => setTimeout(r, 5000));
  }
  if (!manifest) throw new Error("job timed out");
  console.log(
    `      manifest: ${manifest.count} frames, pattern=${manifest.pattern}`
  );

  console.log(`[3/7] creating page with sys-scroll-sequence block`);
  const page = await http<{ id: string }>(
    "POST",
    `/dashboard/projects/${PID}/content/pages`,
    {
      title: "Scroll Hero",
      slug: PAGE_SLUG,
      template: "default",
      blocks: [
        {
          type: "component",
          component_slug: "sys-scroll-sequence",
          props: {
            base_url: manifest.base_url,
            pattern: manifest.pattern,
            count: manifest.count,
            scroll_distance_vh: 400,
            preload_strategy: "progressive",
          },
        },
      ],
    }
  );
  console.log(`      page: ${page.id}`);

  console.log(`[4/7] publishing page (dry_run → confirm)`);
  const dryrun = await http<{ confirm_token: string }>(
    "POST",
    `/dashboard/projects/${PID}/content/pages/${page.id}/publish?dry_run=true`
  );
  await http(
    "POST",
    `/dashboard/projects/${PID}/content/pages/${page.id}/publish?confirm_token=${dryrun.confirm_token}`
  );

  console.log(`[5/7] deploying preview`);
  const preview = await http<{ preview_url: string; confirm_token: string }>(
    "POST",
    `/dashboard/projects/${PID}/content/deploy/preview`
  );
  console.log(`      preview: ${preview.preview_url}`);
  console.log(
    `[6/7] verify the preview in a browser. Press ENTER to promote, Ctrl-C to abort.`
  );
  await new Promise((r) => process.stdin.once("data", r));

  console.log(`[7/7] promoting to production`);
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
