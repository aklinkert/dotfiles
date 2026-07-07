#!/usr/bin/env bash
# Auto-update Claude Code plugins from git-sourced marketplaces.
#
# WHY NOT `claude plugin update`: that command reports success but does NOT
# persist the new pin to installed_plugins.json while an interactive session
# owns the plugin state — it defers to a restart that never rewrites the file.
# So we advance the pins ourselves: refresh each marketplace's git checkout,
# then repoint every plugin from a git-sourced marketplace to the checkout's
# current HEAD (the plugin cache subdir is named by the marketplace short SHA).
#
# Fired from SessionStart (backgrounded, non-blocking) + throttled. Edits apply
# to the NEXT session (this one already loaded its plugins).

set -u

CLAUDE_DIR="${HOME}/.claude"
STAMP="${CLAUDE_DIR}/.plugin-auto-update.stamp"
LOG="${CLAUDE_DIR}/.plugin-auto-update.log"
THROTTLE_HOURS="${CLAUDE_PLUGIN_UPDATE_THROTTLE_HOURS:-12}"

CLAUDE_BIN="$(command -v claude || true)"
[ -z "${CLAUDE_BIN}" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# Throttle: skip if stamp newer than THROTTLE_HOURS.
if [ -f "${STAMP}" ]; then
  now=$(date +%s)
  last=$(stat -f %m "${STAMP}" 2>/dev/null || stat -c %Y "${STAMP}" 2>/dev/null || echo 0)
  [ $(( (now - last) / 3600 )) -lt "${THROTTLE_HOURS}" ] && exit 0
fi
touch "${STAMP}"

{
  echo "=== plugin-auto-update $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

  # 1. Refresh every marketplace git checkout (also downloads new plugin cache dirs).
  "${CLAUDE_BIN}" plugin marketplace update 2>&1

  # 2. Advance pins ourselves — see header for why the CLI can't.
  CLAUDE_DIR="${CLAUDE_DIR}" python3 - <<'PY'
import json, os, subprocess, datetime, tempfile

cdir = os.environ["CLAUDE_DIR"]
inst_path = os.path.join(cdir, "plugins", "installed_plugins.json")
mkt_path  = os.path.join(cdir, "plugins", "known_marketplaces.json")

with open(inst_path) as f: inst = json.load(f)
with open(mkt_path)  as f: mkt  = json.load(f)

def git_head(repo):
    try:
        return subprocess.check_output(
            ["git", "-C", repo, "rev-parse", "HEAD"],
            stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return None

now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
changed = False

for key, entries in inst.get("plugins", {}).items():
    if "@" not in key:
        continue
    plugin, mname = key.rsplit("@", 1)
    m = mkt.get(mname)
    # Only git-sourced marketplaces have a moving HEAD to track.
    if not m or m.get("source", {}).get("source") != "git":
        continue
    loc = m.get("installLocation")
    if not loc or not os.path.isdir(loc):
        continue
    head = git_head(loc)
    if not head:
        continue
    short = head[:12]
    cache_dir = os.path.join(cdir, "plugins", "cache", mname, plugin, short)
    if not os.path.isdir(cache_dir):
        print(f"--- {key}: HEAD {short} not yet in cache; run `claude plugin update {key}` once to fetch it")
        continue
    for e in entries:
        if e.get("gitCommitSha") == head:
            continue
        print(f"--- {key}: {e.get('gitCommitSha','?')[:12]} -> {short}")
        e["installPath"]  = cache_dir
        e["version"]      = short
        e["gitCommitSha"] = head
        e["lastUpdated"]  = now
        changed = True

if changed:
    d = os.path.dirname(inst_path)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".installed_plugins.", suffix=".tmp")
    with os.fdopen(fd, "w") as f:
        json.dump(inst, f, indent=2)
        f.write("\n")
    os.replace(tmp, inst_path)   # atomic
    print("=== installed_plugins.json updated (applies next session) ===")
else:
    print("=== all git-sourced plugins already at HEAD ===")
PY

  echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
} >> "${LOG}" 2>&1

tail -n 500 "${LOG}" > "${LOG}.tmp" 2>/dev/null && mv "${LOG}.tmp" "${LOG}"
exit 0
