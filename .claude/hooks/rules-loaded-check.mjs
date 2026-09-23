#!/usr/bin/env node
// Verifies that the global rule files under ~/.claude/rules/ are actually
// IMPORTED by the CLAUDE.md that this profile loads — not merely referenced
// in prose.
//
// Why this exists: `~/.claude/rules/` is not auto-loaded by Claude Code. Only
// CLAUDE.md and its `@`-imports are. For months the global CLAUDE.md said
// "See `~/.claude/rules/` for detailed rules", which loads nothing, so the
// orchestrator-only rule in agent-delegation.md never reached any session and
// the harness default ("do not use the Agent tool unless asked") won instead.
// A missing `@` line fails silently in exactly the same way, so it needs a
// check that runs on its own.
//
// Two modes:
//   SessionStart hook  — silent when healthy, injects a warning when not.
//   --report           — prints a checklist for every CCS profile. Run by hand.
//
// It verifies configuration, which is what causes loading. It cannot read the
// assembled system prompt, so it cannot observe the load itself. To confirm
// that end-to-end, ask a fresh session to quote a line from a rule file.

import { readFileSync, existsSync, readdirSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname, resolve } from "node:path";

const HOME = homedir();
const RULES_DIR = join(HOME, ".claude", "rules");
const MAX_IMPORT_DEPTH = 5; // Claude Code's own limit

const expand = (p, base) =>
  p.startsWith("~/") ? join(HOME, p.slice(2)) : resolve(base, p);

/** Every `@path` import on its own line, ignoring fenced code blocks. */
function importsOf(file) {
  const out = [];
  let fenced = false;
  for (const line of readFileSync(file, "utf8").split("\n")) {
    if (/^\s*```/.test(line)) fenced = !fenced;
    if (fenced) continue;
    const m = /^\s*@(\S+)\s*$/.exec(line);
    if (m) out.push(expand(m[1], dirname(file)));
  }
  return out;
}

/** Transitive closure of the imports reachable from a CLAUDE.md. */
function reachable(entry) {
  const seen = new Set();
  const walk = (file, depth) => {
    if (depth > MAX_IMPORT_DEPTH || !existsSync(file)) return;
    for (const imp of importsOf(file)) {
      const key = existsSync(imp) ? realpathSync(imp) : imp;
      if (seen.has(key)) continue;
      seen.add(key);
      walk(imp, depth + 1);
    }
  };
  walk(entry, 0);
  return seen;
}

/** The CLAUDE.md a given config dir loads, or null. */
function claudeMdFor(configDir) {
  const p = join(configDir, "CLAUDE.md");
  return existsSync(p) ? realpathSync(p) : null;
}

function auditConfigDir(configDir) {
  const problems = [];
  const md = claudeMdFor(configDir);
  if (!md) {
    return { configDir, md: null, problems: [`no CLAUDE.md in ${configDir}`], loaded: [] };
  }

  const loaded = reachable(md);
  const rules = existsSync(RULES_DIR)
    ? readdirSync(RULES_DIR).filter((f) => f.endsWith(".md")).sort()
    : [];

  if (rules.length === 0) problems.push(`${RULES_DIR} holds no .md rule files`);

  for (const f of rules) {
    const full = realpathSync(join(RULES_DIR, f));
    if (!loaded.has(full)) {
      problems.push(`rules/${f} is NOT imported by ${md} — its rules do not apply`);
    } else if (readFileSync(full, "utf8").replace(/^---[\s\S]*?---/, "").trim() === "") {
      problems.push(`rules/${f} is imported but empty`);
    }
  }

  // An import naming a file that does not exist is a silent no-op.
  for (const imp of loaded) {
    if (!existsSync(imp)) problems.push(`@${imp} is imported but missing — silently ignored`);
  }

  // The regression this hook was written for: pointer prose, no import.
  const body = readFileSync(md, "utf8");
  if (/`?~\/\.claude\/rules\/`?/.test(body) && rules.some((f) => !loaded.has(realpathSync(join(RULES_DIR, f))))) {
    problems.push(
      "CLAUDE.md points at ~/.claude/rules/ in prose but does not import it. " +
        "A prose pointer loads nothing — add `@~/.claude/rules/<file>.md` lines.",
    );
  }

  return { configDir, md, problems, loaded: [...loaded] };
}

const ccsInstances = () => {
  const d = join(HOME, ".ccs", "instances");
  return existsSync(d)
    ? readdirSync(d, { withFileTypes: true })
        .filter((e) => e.isDirectory() && !e.name.startsWith("."))
        .map((e) => join(d, e.name))
    : [];
};

if (process.argv.includes("--report")) {
  const dirs = [...new Set([join(HOME, ".claude"), ...ccsInstances()])];
  let bad = 0;
  for (const dir of dirs) {
    const r = auditConfigDir(dir);
    const name = dir.replace(HOME, "~");
    if (r.problems.length === 0) {
      console.log(`[ok]   ${name} -> ${r.md?.replace(HOME, "~")} (${r.loaded.length} imports)`);
    } else {
      bad++;
      console.log(`[FAIL] ${name}`);
      for (const p of r.problems) console.log(`         - ${p}`);
    }
  }
  process.exit(bad === 0 ? 0 : 1);
}

// Hook mode: audit only the config dir this session actually uses.
const configDir = process.env.CLAUDE_CONFIG_DIR || join(HOME, ".claude");
const { problems } = auditConfigDir(configDir);

if (problems.length > 0) {
  const text =
    "Global rule files are not loaded for this session. Until this is fixed, " +
    "treat the following as unverified rather than in force:\n" +
    problems.map((p) => `  - ${p}`).join("\n") +
    `\nRun \`node ~/.claude/hooks/rules-loaded-check.mjs --report\` for every profile.`;
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: text },
    }),
  );
}
process.exit(0);
