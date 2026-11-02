#!/usr/bin/env bash
# Wait until no check is pending on each PR, re-reading the head every round (Renovate rebases).
# Usage: wait-checks.sh <pr-url>...
# Output per PR: "<url> head=<sha8> state=<mergeStateStatus> failing=<names, comma separated, or ->"
# Env: WAIT_MINUTES (deadline per PR, default 30), POLL_SECONDS (default 30), GH_HOST.
# Exit: 0 unless gh fails; a timeout is reported on stderr and the last state is still printed.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ $# -ge 1 ] || { echo "usage: $0 <pr-url>..." >&2; exit 2; }
WAIT_MINUTES="${WAIT_MINUTES:-30}"
POLL_SECONDS="${POLL_SECONDS:-30}"

for url in "$@"; do
  parse_pr_url "$url"
  deadline=$(( $(date +%s) + WAIT_MINUTES * 60 ))
  while :; do
    pr=$(gh pr view "$url" --json headRefOid,mergeStateStatus,statusCheckRollup </dev/null)
    # UNKNOWN is transient right after a push; treat it like pending.
    pending=$(printf '%s' "$pr" | jq "$CHECKS_JQ"'classify | (.pending | length)')
    state=$(printf '%s' "$pr" | jq -r '.mergeStateStatus')
    if [ "$pending" -eq 0 ] && [ "$state" != UNKNOWN ]; then break; fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "wait-checks: timeout after ${WAIT_MINUTES}m on $url ($pending pending, state $state)" >&2
      break
    fi
    sleep "$POLL_SECONDS"
  done
  printf '%s' "$pr" | jq -r --arg url "$url" "$CHECKS_JQ"'
    "\($url) head=\(.headRefOid[0:8]) state=\(.mergeStateStatus) failing=\(classify | .failing | if length == 0 then "-" else join(",") end)"' \
    | strip_ctrl
done
