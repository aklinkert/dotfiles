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
# WHY WE MATERIALIZE THE CACHE DIR OURSELVES: `plugin marketplace update` only
# advances the marketplace checkout; it does not populate
# cache/<marketplace>/<plugin>/<sha12>. Waiting for that dir to appear made
# every pin land exactly one update cycle late. A cache dir is a plain copy of
# the plugin's source dir inside the checkout, so we copy it, drop any
# .orphaned_at GC marker, and pin in the same run.
#
# Fired from SessionStart (backgrounded, non-blocking) + throttled to one run
# per day. Edits apply to the NEXT session (this one already loaded its
# plugins).

set -u

CLAUDE_DIR="${HOME}/.claude"
STAMP="${CLAUDE_DIR}/.plugin-auto-update.stamp"
LOG="${CLAUDE_DIR}/.plugin-auto-update.log"
# 20h, not 24h: a 24h window skips a day whenever the first session of the day
# starts slightly earlier than the previous one.
THROTTLE_HOURS="${CLAUDE_PLUGIN_UPDATE_THROTTLE_HOURS:-20}"

CLAUDE_BIN="$(command -v claude || true)"
[ -z "${CLAUDE_BIN}" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# Throttle: skip if stamp newer than THROTTLE_HOURS. CLAUDE_PLUGIN_UPDATE_FORCE=1 bypasses.
if [ -f "${STAMP}" ] && [ "${CLAUDE_PLUGIN_UPDATE_FORCE:-0}" != "1" ]; then
  now=$(date +%s)
  last=$(stat -f %m "${STAMP}" 2>/dev/null || stat -c %Y "${STAMP}" 2>/dev/null || echo 0)
  [ $(( (now - last) / 3600 )) -lt "${THROTTLE_HOURS}" ] && exit 0
fi
touch "${STAMP}"

{
  echo "=== plugin-auto-update $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

  # 1. Refresh every marketplace git checkout.
  "${CLAUDE_BIN}" plugin marketplace update 2>&1

  # 2. Materialize the cache dir for the new HEAD and advance pins ourselves —
  #    see header for why the CLI can't.
  CLAUDE_DIR="${CLAUDE_DIR}" python3 - <<'PY'
import datetime, json, os, shutil, subprocess, tempfile

cdir = os.environ["CLAUDE_DIR"]
plugins_dir = os.path.join(cdir, "plugins")
inst_path = os.path.join(plugins_dir, "installed_plugins.json")
mkt_path  = os.path.join(plugins_dir, "known_marketplaces.json")

with open(inst_path) as f: inst = json.load(f)
with open(mkt_path)  as f: mkt  = json.load(f)

def git_head(repo):
    try:
        return subprocess.check_output(
            ["git", "-C", repo, "rev-parse", "HEAD"],
            stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return None


def plugin_source_dir(checkout, plugin):
    """Resolve a plugin's source directory inside its marketplace checkout."""
    try:
        with open(os.path.join(checkout, ".claude-plugin", "marketplace.json")) as f:
            entries = json.load(f).get("plugins", [])
    except Exception:
        return None
    for entry in entries:
        if not isinstance(entry, dict) or entry.get("name") != plugin:
            continue
        src = entry.get("source")
        if isinstance(src, dict):
            src = src.get("source") or src.get("path")
        if not isinstance(src, str):
            return None  # remote source (git/github): not a path in this checkout
        path = os.path.normpath(os.path.join(checkout, src))
        # Refuse to copy from outside the checkout.
        if not path.startswith(os.path.join(checkout, "")):
            return None
        return path if os.path.isdir(path) else None
    return None


def materialize(cache_dir, source_dir):
    """Copy source_dir -> cache_dir atomically. Returns True on success."""
    parent = os.path.dirname(cache_dir)
    os.makedirs(parent, exist_ok=True)
    staging = tempfile.mkdtemp(dir=parent, prefix=".materialize.")
    target = os.path.join(staging, "payload")
    try:
        # Ignore the runtime markers Claude Code writes into a cache dir so a
        # fresh copy stays clean.
        shutil.copytree(source_dir, target, symlinks=True,
                        ignore=shutil.ignore_patterns(".git", ".in_use", ".orphaned_at"))
        os.rename(target, cache_dir)
        return True
    except Exception as err:
        print(f"    materialize failed: {err}")
        return False
    finally:
        shutil.rmtree(staging, ignore_errors=True)


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
    cache_dir = os.path.join(plugins_dir, "cache", mname, plugin, short)

    if not os.path.isdir(cache_dir):
        source_dir = plugin_source_dir(loc, plugin)
        if not source_dir:
            print(f"--- {key}: cannot resolve source dir for HEAD {short}; skipped")
            continue
        if not materialize(cache_dir, source_dir):
            continue
        print(f"--- {key}: materialized cache dir {short}")

    # Clear the GC's orphan marker: the pin below makes this dir live again.
    orphan = os.path.join(cache_dir, ".orphaned_at")
    if os.path.exists(orphan):
        try:
            os.remove(orphan)
        except OSError:
            pass

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
    fd, tmp = tempfile.mkstemp(dir=plugins_dir, prefix=".installed_plugins.", suffix=".tmp")
    with os.fdopen(fd, "w") as f:
        json.dump(inst, f, indent=2)
        f.write("\n")
    os.replace(tmp, inst_path)   # atomic
    print("=== installed_plugins.json updated (applies next session) ===")
else:
    print("=== all git-sourced plugins already at HEAD ===")

# Housekeeping: Claude Code leaves abandoned git staging dirs in the cache.
cache_root = os.path.join(plugins_dir, "cache")
cutoff = datetime.datetime.now().timestamp() - 24 * 3600
for name in (os.listdir(cache_root) if os.path.isdir(cache_root) else []):
    if not name.startswith("temp_git_"):
        continue
    path = os.path.join(cache_root, name)
    try:
        if os.path.getmtime(path) < cutoff:
            shutil.rmtree(path, ignore_errors=True)
            print(f"--- pruned stale staging dir {name}")
    except OSError:
        pass
PY

  echo "=== done $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
} >> "${LOG}" 2>&1

tail -n 500 "${LOG}" > "${LOG}.tmp" 2>/dev/null && mv "${LOG}.tmp" "${LOG}"
exit 0
