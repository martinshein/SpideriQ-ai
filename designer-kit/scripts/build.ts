#!/usr/bin/env -S npx tsx
/**
 * SpiderPublish Starter Kit build pipeline.
 *
 * Reads canonical content from ./shared and ./manifest.json, emits per-runtime
 * trees under ./runtimes/{claude-code,antigravity,cursor,claude-desktop}.
 *
 * Run with: npm run build
 *
 * Idempotent: wipes & rebuilds runtimes/. Commit the output — degit pulls it.
 */
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import { z } from "zod";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const shared = path.join(root, "shared");
const runtimesDir = path.join(root, "runtimes");

// ── Schemas ─────────────────────────────────────────────────────────────────

const RuntimeSchema = z.object({
  id: z.enum(["claude-code", "antigravity", "cursor", "claude-desktop"]),
  label: z.string(),
  root: z.string(),
  supports: z.array(z.string()),
  main_doc: z.string(),
  skill_path: z.string().nullable(),
  skill_format: z.enum(["claude-skill", "antigravity-ki", "cursor-rule"]).nullable(),
});

const SkillSchema = z.object({
  id: z.string().regex(/^[a-z0-9-]+$/),
  kind: z.enum(["recipe", "core", "guide"]),
  ki_index: z.number().int().positive(),
  title: z.string().min(1),
  summary: z.string().min(40),
  multi_artifact: z.boolean().optional(),
});

const ManifestSchema = z.object({
  version: z.string(),
  description: z.string(),
  // Stamped onto every emitted artifact. MUST be a fixed date, never a build
  // clock: runtimes/ is committed and `build:check` compares it byte-for-byte
  // against a fresh build, so any wall-clock value makes the gate unpassable.
  // Bump it in the same commit that changes shared/.
  updated_at: z.string().regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/),
  runtimes: z.array(RuntimeSchema).length(4),
  skills: z.array(SkillSchema).min(1),
});

type Skill = z.infer<typeof SkillSchema>;
type Runtime = z.infer<typeof RuntimeSchema>;

// ── Helpers ─────────────────────────────────────────────────────────────────

const log = (msg: string) => process.stdout.write(`${msg}\n`);

const skillSourceDir = (s: Skill): string => {
  const sub = s.kind === "recipe" ? "recipes" : s.kind === "core" ? "core-skills" : "guides";
  return path.join(shared, sub, s.id);
};

const readMaybe = (p: string): string | null =>
  fs.existsSync(p) ? fs.readFileSync(p, "utf8") : null;

const writeFile = (p: string, contents: string): void => {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, contents);
};

const copyDir = (from: string, to: string): void => {
  if (!fs.existsSync(from)) return;
  fs.mkdirSync(to, { recursive: true });
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const a = path.join(from, entry.name);
    const b = path.join(to, entry.name);
    if (entry.isDirectory()) copyDir(a, b);
    else if (entry.isFile()) fs.copyFileSync(a, b);
  }
};

const copyFile = (from: string, to: string): void => {
  if (!fs.existsSync(from)) return;
  fs.mkdirSync(path.dirname(to), { recursive: true });
  fs.copyFileSync(from, to);
};

const skillBody = (s: Skill): string => {
  const dir = skillSourceDir(s);
  if (s.kind === "guide") {
    // guides live as antigravity-shape KIs: artifacts/*.md + metadata.json
    const artifactsDir = path.join(dir, "artifacts");
    if (!fs.existsSync(artifactsDir)) throw new Error(`Missing artifacts/ for guide ${s.id}`);
    const files = fs.readdirSync(artifactsDir).filter(f => f.endsWith(".md")).sort();
    if (files.length === 0) throw new Error(`No artifacts/*.md for guide ${s.id}`);
    return files
      .map(f => {
        const body = fs.readFileSync(path.join(artifactsDir, f), "utf8");
        return files.length > 1 ? `<!-- artifact: ${f} -->\n\n${body}` : body;
      })
      .join("\n\n---\n\n");
  }
  // recipes + core: SKILL.md is canonical
  const skillMd = readMaybe(path.join(dir, "SKILL.md"));
  if (!skillMd) throw new Error(`Missing SKILL.md for ${s.kind}/${s.id}`);
  return skillMd;
};

// ── Per-runtime emitters ────────────────────────────────────────────────────

const emitClaudeSkill = (rt: Runtime, s: Skill): void => {
  const subdir = s.kind === "recipe" ? "recipes" : s.kind === "core" ? "core" : "guides";
  const dest = path.join(runtimesDir, rt.id.replace("claude-code", "claude-code"), ".claude", "skills", subdir, s.id, "SKILL.md");
  const frontmatter = [
    "---",
    `name: ${s.id}`,
    `description: ${JSON.stringify(s.summary)}`,
    "---",
    "",
  ].join("\n");
  writeFile(dest, frontmatter + skillBody(s));
  // copy schema.yaml + impl.ts if present
  const src = skillSourceDir(s);
  for (const aux of ["schema.yaml", "impl.ts", "shell.md"]) {
    const from = path.join(src, aux);
    if (fs.existsSync(from)) copyFile(from, path.join(path.dirname(dest), aux));
  }
};

const emitAntigravityKi = (rt: Runtime, s: Skill, updatedAt: string): void => {
  const idx = String(s.ki_index).padStart(2, "0");
  const kiDir = path.join(runtimesDir, rt.id, "knowledge-items", `${idx}-spideriq-${s.id}`);
  // metadata.json
  const meta = {
    title: s.title,
    summary: s.summary,
    createdAt: "2026-05-08T00:00:00Z",
    updatedAt,
    references: [
      `shared/${s.kind === "recipe" ? "recipes" : s.kind === "core" ? "core-skills" : "guides"}/${s.id}/`,
    ],
  };
  writeFile(path.join(kiDir, "metadata.json"), JSON.stringify(meta, null, 2) + "\n");
  // artifacts/
  if (s.kind === "guide") {
    // preserve original multi-file artifact structure
    const fromArtifacts = path.join(skillSourceDir(s), "artifacts");
    copyDir(fromArtifacts, path.join(kiDir, "artifacts"));
  } else {
    writeFile(path.join(kiDir, "artifacts", "workflow.md"), skillBody(s));
  }
};

const emitCursorRule = (rt: Runtime, s: Skill): void => {
  const dest = path.join(runtimesDir, rt.id, ".cursor", "rules", `${s.id}.mdc`);
  // Cursor MDC rules: short YAML frontmatter + body
  const frontmatter = [
    "---",
    `description: ${JSON.stringify(s.summary)}`,
    "alwaysApply: false",
    "---",
    "",
  ].join("\n");
  writeFile(dest, frontmatter + skillBody(s));
};

// ── Top-level doc emission ──────────────────────────────────────────────────

const buildClaudeMainDoc = (manifest: z.infer<typeof ManifestSchema>): string => {
  const intro = `# SpiderPublish — Claude Code Context

> **Built from canonical sources in [shared/](../../shared/).** Edit shared content there, run \`npm run build\` to regenerate.

This file binds your Claude Code session to the SpiderPublish content platform: the safety contract, the tool catalog, and pointers to skills you can pull in by name.

`;
  const binding = readMaybe(path.join(shared, "content", "claude-binding.md")) ?? "";
  const catalog = readMaybe(path.join(shared, "content", "agents-catalog.md")) ?? "";
  const skillIndex = renderSkillIndex(manifest.skills, "claude-code");
  return [intro, binding.trim(), "\n\n---\n\n", catalog.trim(), "\n\n---\n\n", skillIndex].join("");
};

const buildAntigravityMainDoc = (manifest: z.infer<typeof ManifestSchema>): string => {
  const intro = `# SpiderPublish — Antigravity AGENTS.md

> **Built from canonical sources in [shared/](../../shared/).** Edit shared content there, run \`npm run build\` to regenerate.

This kit ships **${manifest.skills.length} pre-built Knowledge Items** under [knowledge-items/](./knowledge-items/) covering capability discovery, page creation, marketplace search, deploy, personalized landing, booking, scroll-sequence, GEO readability, MCP package picking, CLI reference, and IDE extension setup. Install with \`bash install-knowledge-items.sh\`.

`;
  const catalog = readMaybe(path.join(shared, "content", "agents-catalog.md")) ?? "";
  const skillIndex = renderSkillIndex(manifest.skills, "antigravity");
  return [intro, catalog.trim(), "\n\n---\n\n", skillIndex].join("");
};

const buildCursorMainDoc = (manifest: z.infer<typeof ManifestSchema>): string => {
  const intro = `# SpiderPublish — Cursor AGENTS.md

> **Built from canonical sources in [shared/](../../shared/).** Edit shared content there, run \`npm run build\` to regenerate.

Cursor reads this file plus per-skill rules under \`.cursor/rules/*.mdc\`. Each rule is loaded on demand based on its description match.

`;
  const catalog = readMaybe(path.join(shared, "content", "agents-catalog.md")) ?? "";
  const skillIndex = renderSkillIndex(manifest.skills, "cursor");
  return [intro, catalog.trim(), "\n\n---\n\n", skillIndex].join("");
};

const buildClaudeDesktopReadme = (manifest: z.infer<typeof ManifestSchema>): string => {
  return `# SpiderPublish on Claude Desktop

Claude Desktop has no auto-bootstrap (no MCP discovery from a folder, no skill loading). Setup is manual.

## 1. Add MCP server

Edit \`~/Library/Application Support/Claude/claude_desktop_config.json\` (macOS) or the Windows equivalent:

\`\`\`json
{
  "mcpServers": {
    "spideriq-publish": {
      "command": "npx",
      "args": ["-y", "@spideriq/mcp-publish@latest"],
      "env": {
        "SPIDERIQ_TOKEN": "<your-PAT>",
        "SPIDERIQ_API_URL": "https://spideriq.ai"
      }
    }
  }
}
\`\`\`

Then restart Claude Desktop.

## 2. Authenticate + bind project

In a terminal:

\`\`\`bash
npx @spideriq/cli auth request --email admin@company.com
# wait for approval, then in your project root:
npx @spideriq/cli use <project>   # writes ./spideriq.json
\`\`\`

## 3. Reference docs in your prompts

Claude Desktop has no skill auto-loading, so paste relevant context manually:

- [shared/content/claude-binding.md](../../shared/content/claude-binding.md) — Phase 11+12 safety contract
- [shared/content/agents-catalog.md](../../shared/content/agents-catalog.md) — full tool catalog with payload schemas

For task-specific recipes, paste the relevant skill body from [shared/recipes/](../../shared/recipes/):

${manifest.skills.filter(s => s.kind === "recipe").map(s => `- **${s.title}** — \`shared/recipes/${s.id}/SKILL.md\``).join("\n")}

## 4. Optional: build via the CLI

If you prefer terminal-only, [@spideriq/cli](../../shared/guides/cli-quick-reference/) has the same primitives as MCP without an IDE:

\`\`\`bash
npx @spideriq/cli content list-pages --format yaml
npx @spideriq/cli content publish-page --page-id abc-123 --dry-run
\`\`\`
`;
};

const renderSkillIndex = (skills: Skill[], runtimeId: string): string => {
  const groups: Record<string, Skill[]> = { recipe: [], core: [], guide: [] };
  for (const s of skills) groups[s.kind].push(s);
  const skillPath = (s: Skill) => {
    if (runtimeId === "claude-code") {
      const sub = s.kind === "recipe" ? "recipes" : s.kind === "core" ? "core" : "guides";
      return `.claude/skills/${sub}/${s.id}/SKILL.md`;
    }
    if (runtimeId === "antigravity") {
      return `knowledge-items/${String(s.ki_index).padStart(2, "0")}-spideriq-${s.id}/`;
    }
    if (runtimeId === "cursor") {
      return `.cursor/rules/${s.id}.mdc`;
    }
    return `shared/${s.kind === "recipe" ? "recipes" : s.kind === "core" ? "core-skills" : "guides"}/${s.id}/`;
  };
  const renderGroup = (label: string, items: Skill[]) =>
    items.length === 0
      ? ""
      : [
          `### ${label}`,
          "",
          ...items.map(s => `- [${s.title}](${skillPath(s)}) — ${s.summary.split(".")[0]}.`),
          "",
        ].join("\n");
  return [
    "## Skills bundled with this kit",
    "",
    renderGroup("Recipes (multi-step workflows)", groups.recipe),
    renderGroup("Core MCP-namespace skills", groups.core),
    renderGroup("Guides (onboarding + decision aids)", groups.guide),
  ].join("\n");
};

// ── Asset copy (shared → each runtime) ──────────────────────────────────────

const copySharedAssets = (rt: Runtime): void => {
  const dest = path.join(runtimesDir, rt.id);
  copyDir(path.join(shared, "components"), path.join(dest, "components"));
  copyDir(path.join(shared, "examples"), path.join(dest, "examples"));
  copyDir(path.join(shared, "templates"), path.join(dest, "templates"));
  copyFile(path.join(shared, "content", "mcp-config.json"), path.join(dest, ".mcp.json"));
  copyFile(path.join(shared, "content", "spideriq.json.example"), path.join(dest, "spideriq.json.example"));
  copyFile(path.join(shared, "content", "llms-index.txt"), path.join(dest, "llms.txt"));
  // top-level concept docs as monoliths (preserve canonical UPPERCASE filenames)
  const docMap: Record<string, string> = {
    "capabilities.md": "CAPABILITIES.md",
    "surfaces.md": "SURFACES.md",
    "geo.md": "GEO.md",
    "merge-tags.md": "MERGE-TAGS.md",
    "learnings.md": "LEARNINGS.md",
  };
  for (const [src, out] of Object.entries(docMap)) {
    copyFile(path.join(shared, "content", src), path.join(dest, out));
  }
};

const writeAntigravityInstaller = (): void => {
  const script = `#!/usr/bin/env bash
# Install SpiderPublish Antigravity Knowledge Items into ~/.gemini/antigravity/knowledge/
set -euo pipefail
HERE="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
DEST="\${HOME}/.gemini/antigravity/knowledge"
mkdir -p "$DEST"
echo "Installing KIs from $HERE/knowledge-items → $DEST"
for ki in "$HERE"/knowledge-items/*/; do
  name="$(basename "$ki")"
  rm -rf "$DEST/$name"
  cp -r "$ki" "$DEST/$name"
  echo "  ✓ $name"
done
echo
echo "Installed $(ls -1 "$DEST" | wc -l) Knowledge Items. Restart Antigravity to pick them up."
`;
  const dest = path.join(runtimesDir, "antigravity", "install-knowledge-items.sh");
  writeFile(dest, script);
  fs.chmodSync(dest, 0o755);
};

const writeCursorRulesIndex = (): void => {
  const dest = path.join(runtimesDir, "cursor", ".cursor", "rules", "_index.mdc");
  const body = `---
description: "SpiderPublish starter kit — root rule. Always-apply: true. Pulls in per-skill rules on demand based on user intent."
alwaysApply: true
---

This project uses SpiderPublish (SpiderIQ's content platform). Read [AGENTS.md](../../AGENTS.md) for the tool catalog and the Phase 11+12 multi-tenant safety contract before mutating any tenant content.

When the user's intent matches one of the per-skill rules in this directory, that rule auto-loads. Recipes (multi-step workflows) are under \`recipe-*.mdc\`, core MCP namespaces under \`core-*.mdc\`, and onboarding/decision guides under \`guide-*.mdc\`.
`;
  writeFile(dest, body);
};

// ── Main ────────────────────────────────────────────────────────────────────

const main = (): void => {
  // Load + validate manifest
  const manifestPath = path.join(root, "manifest.json");
  const raw = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const manifest = ManifestSchema.parse(raw);
  log(`✓ manifest.json — ${manifest.skills.length} skills, ${manifest.runtimes.length} runtimes`);

  // Validate ki_index uniqueness
  const seen = new Set<number>();
  for (const s of manifest.skills) {
    if (seen.has(s.ki_index)) throw new Error(`Duplicate ki_index ${s.ki_index} for skill ${s.id}`);
    seen.add(s.ki_index);
    // verify source dir exists
    if (!fs.existsSync(skillSourceDir(s))) throw new Error(`Missing source dir for ${s.kind}/${s.id}: ${skillSourceDir(s)}`);
  }

  // Wipe runtimes/
  if (fs.existsSync(runtimesDir)) fs.rmSync(runtimesDir, { recursive: true });
  fs.mkdirSync(runtimesDir, { recursive: true });

  // Emit
  for (const rt of manifest.runtimes) {
    log(`\n→ ${rt.id}`);
    copySharedAssets(rt);

    let mainDoc: string;
    if (rt.id === "claude-code") mainDoc = buildClaudeMainDoc(manifest);
    else if (rt.id === "antigravity") mainDoc = buildAntigravityMainDoc(manifest);
    else if (rt.id === "cursor") mainDoc = buildCursorMainDoc(manifest);
    else mainDoc = buildClaudeDesktopReadme(manifest);
    writeFile(path.join(runtimesDir, rt.id, rt.main_doc), mainDoc);

    if (rt.skill_format === "claude-skill") {
      for (const s of manifest.skills) emitClaudeSkill(rt, s);
      log(`  ✓ ${manifest.skills.length} skills as .claude/skills/`);
    } else if (rt.skill_format === "antigravity-ki") {
      for (const s of manifest.skills) emitAntigravityKi(rt, s, manifest.updated_at);
      writeAntigravityInstaller();
      log(`  ✓ ${manifest.skills.length} Knowledge Items + install-knowledge-items.sh`);
    } else if (rt.skill_format === "cursor-rule") {
      for (const s of manifest.skills) emitCursorRule(rt, s);
      writeCursorRulesIndex();
      log(`  ✓ ${manifest.skills.length} cursor rules + _index.mdc`);
    } else {
      log(`  ✓ ${rt.main_doc} (skills referenced inline; no skill files emitted)`);
    }
  }

  log(`\n✓ Build complete. ${manifest.runtimes.length} runtime trees emitted under runtimes/.`);
};

main();
