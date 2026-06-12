#!/usr/bin/env python3
"""Aggregate Claude Code prompt history across ALL CCS profiles for a date range.

Reads ~/.ccs/instances/*/history.jsonl (each line: display, timestamp[ms],
project, sessionId) and emits a structured digest grouped by project. The agent
turns this digest into a readable recap; this script only does the data work so
the raw history never enters the conversation context.

Usage:
  recap.py                # current week (Mon 00:00 -> now)
  recap.py week           # same as above
  recap.py last-week      # previous Mon..Sun
  recap.py today
  recap.py yesterday
  recap.py 2026-06-08             # that day only
  recap.py 2026-06-08 2026-06-12  # explicit inclusive range
"""
import json, os, sys, datetime
from collections import defaultdict, Counter

INSTANCES = os.path.expanduser("~/.ccs/instances")


def parse_range(argv):
    now = datetime.datetime.now()
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    arg = argv[1] if len(argv) > 1 else "week"

    def ymd(s):
        return datetime.datetime.strptime(s, "%Y-%m-%d")

    if len(argv) > 2 and argv[1][:1].isdigit() and argv[2][:1].isdigit():
        start, end = ymd(argv[1]), ymd(argv[2]) + datetime.timedelta(days=1)
        label = f"{argv[1]} → {argv[2]}"
    elif arg[:1].isdigit():
        start = ymd(arg); end = start + datetime.timedelta(days=1)
        label = arg
    elif arg == "today":
        start, end, label = today, now, "today"
    elif arg == "yesterday":
        start = today - datetime.timedelta(days=1); end = today; label = "yesterday"
    elif arg == "last-week":
        this_mon = today - datetime.timedelta(days=today.weekday())
        start = this_mon - datetime.timedelta(days=7); end = this_mon
        label = "last week"
    else:  # week
        start = today - datetime.timedelta(days=today.weekday()); end = now
        label = "this week"
    return start, end, label


def short(proj):
    s = proj.replace(os.path.expanduser("~/src/"), "").replace(os.path.expanduser("~/"), "~/")
    if "/.claude/worktrees/" in s:
        s = s.split("/.claude/worktrees/")[0] + " (worktree)"
    return s or "(unknown)"


def main():
    start, end, label = parse_range(sys.argv)
    s_ms, e_ms = start.timestamp() * 1000, end.timestamp() * 1000

    profiles = []
    if os.path.isdir(INSTANCES):
        profiles = sorted(d for d in os.listdir(INSTANCES)
                          if os.path.isfile(os.path.join(INSTANCES, d, "history.jsonl")))

    rows = []
    per_profile = Counter()
    for p in profiles:
        for line in open(os.path.join(INSTANCES, p, "history.jsonl"), errors="ignore"):
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except Exception:
                continue
            ts = d.get("timestamp", 0)
            if not (s_ms <= ts < e_ms):
                continue
            rows.append((p, ts, d.get("project", ""), d.get("sessionId", ""), d.get("display", "")))
            per_profile[p] += 1

    print(f"# RECAP DIGEST — {label}  ({start:%Y-%m-%d} → {end:%Y-%m-%d})")
    print(f"profiles scanned: {', '.join(profiles) or 'none'}")
    if not rows:
        print("no activity in range")
        return
    sessions = set((r[0], r[3]) for r in rows)
    print(f"totals: {len(rows)} prompts | {len(sessions)} sessions | "
          f"{len(set(short(r[2]) for r in rows))} projects")
    print("by profile: " + ", ".join(f"{k}={v}" for k, v in per_profile.most_common()))
    by_day = Counter()
    day_ts = {}
    for r in rows:
        k = datetime.datetime.fromtimestamp(r[1] / 1000).strftime("%a %m-%d")
        by_day[k] += 1
        day_ts.setdefault(k, r[1])
    print("by day: " + ", ".join(f"{k}={by_day[k]}" for k in sorted(by_day, key=lambda x: day_ts[x])))

    byproj = defaultdict(list)
    for r in rows:
        byproj[short(r[2])].append(r)

    print("\n## PROJECTS (by activity)")
    for proj, ds in sorted(byproj.items(), key=lambda x: -len(x[1])):
        sess = len(set(r[3] for r in ds))
        days = sorted(set(datetime.datetime.fromtimestamp(r[1] / 1000).strftime("%a") for r in ds),
                      key=lambda d: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].index(d))
        print(f"\n### {proj}  [{len(ds)} prompts / {sess} sessions / {','.join(days)}]")
        # first prompt of each session = task intent; skip pure slash/bang noise when possible
        seen, intents = set(), []
        for r in sorted(ds, key=lambda x: x[1]):
            sid = r[3]
            if sid in seen:
                continue
            seen.add(sid)
            intents.append(r[4].replace("\n", " ").strip()[:110])
        for it in intents[:15]:
            print("  -", it)


if __name__ == "__main__":
    main()
