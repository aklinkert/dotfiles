#!/usr/bin/env bash
# Show why a PR's checks failed: relevant log tail per failed workflow run plus failing external statuses.
# Usage: failed-logs.sh <pr-url>
# Output: "### <workflow> <run url>" then up to 20 matching log lines (error|fail|mismatch|not found|denied|exit code);
#   "### status <context> <target url>" for failing non-Actions contexts; "no failed runs" if nothing failed.
# Env: GH_HOST (GitHub Enterprise; derived from the URL when it is not github.com).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ $# -eq 1 ] || { echo "usage: $0 <pr-url>" >&2; exit 2; }
parse_pr_url "$1"

pr=$(gh pr view "$1" --json headRefOid,statusCheckRollup </dev/null)
sha=$(printf '%s' "$pr" | jq -r '.headRefOid')
found=0

runs=$(gh run list -R "$PR_REPO" --commit "$sha" --json databaseId,name,conclusion,status,url --limit 100 </dev/null)
bad=$(printf '%s' "$runs" | jq -c '.[] | select(.conclusion == "failure" or .conclusion == "cancelled" or .conclusion == "timed_out")')
while IFS= read -r run; do
  [ -n "$run" ] || continue
  found=1
  id=$(printf '%s' "$run" | jq -r '.databaseId')
  printf '### %s %s\n' "$(printf '%s' "$run" | jq -r '.name' | strip_ctrl)" "$(printf '%s' "$run" | jq -r '.url' | strip_ctrl)"
  { gh run view "$id" -R "$PR_REPO" --log-failed </dev/null 2>/dev/null || true; } \
    | strip_ctrl | { grep -iE 'error|fail|mismatch|not found|denied|exit code' || true; } \
    | cut -c1-400 | tail -n 20
done <<EOF
$bad
EOF

ctx=$(printf '%s' "$pr" | jq -r '(.statusCheckRollup // [])[]
  | select(.__typename == "StatusContext" and (.state == "FAILURE" or .state == "ERROR"))
  | "\(.context)\t\(.targetUrl // "-")"' | strip_ctrl)
while IFS= read -r line; do
  [ -n "$line" ] || continue
  found=1
  printf '### status %s %s\n' "${line%%$'\t'*}" "${line#*$'\t'}"
done <<EOF
$ctx
EOF

[ "$found" -eq 1 ] || echo "no failed runs"
