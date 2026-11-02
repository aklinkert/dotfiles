#!/usr/bin/env bash
# Guarded merge of a reviewed PR head. Never uses --auto or --admin.
# Usage: merge.sh <pr-url> <reviewed-head-sha>
# Refuses (prints "NOT MERGED <url>: <reason>", exit 3) when the PR is not open, is a draft, the head differs from
#   the reviewed sha, mergeable != MERGEABLE, mergeStateStatus is not CLEAN|HAS_HOOKS|UNSTABLE, or a check is pending.
#   A failing check is tolerated only with UNSTABLE and `gh pr checks --required` exiting 0 (all required passed).
# Method: squash, else rebase, else merge, as allowed by the repo. Success: "MERGED <url> <method> at <sha8>".
# Env: GH_HOST (GitHub Enterprise; derived from the URL when it is not github.com).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ $# -eq 2 ] || { echo "usage: $0 <pr-url> <reviewed-head-sha>" >&2; exit 2; }
url=$1 want=$2
parse_pr_url "$url"

refuse() { echo "NOT MERGED $url: $1"; exit 3; }

pr=$(gh pr view "$url" --json state,isDraft,headRefOid,mergeable,mergeStateStatus,statusCheckRollup </dev/null)
get() { printf '%s' "$pr" | jq -r "$1"; }

head=$(get .headRefOid); mergeable=$(get .mergeable); mstate=$(get .mergeStateStatus)
[ "$(get .state)" = OPEN ] || refuse "PR is $(get .state)"
[ "$(get .isDraft)" = false ] || refuse "PR is a draft"
[ "$head" = "$want" ] || refuse "head is ${head:0:8}, reviewed ${want:0:8}"
[ "$mergeable" = MERGEABLE ] || refuse "mergeable=$mergeable"
case $mstate in CLEAN|HAS_HOOKS|UNSTABLE) ;; *) refuse "mergeStateStatus=$mstate" ;; esac

failing=$(printf '%s' "$pr" | jq -r "$CHECKS_JQ"'classify | .failing | join(",")')
pending=$(printf '%s' "$pr" | jq -r "$CHECKS_JQ"'classify | .pending | join(",")')
[ -z "$pending" ] || refuse "pending checks: $pending"
if [ -n "$failing" ]; then
  [ "$mstate" = UNSTABLE ] || refuse "failing checks: $failing"
  rc=0
  gh pr checks "$url" --required </dev/null >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 0 ] || refuse "failing checks: $failing (required checks not all passed, or none are required)"
fi

repo_json=$(gh api "repos/$PR_REPO" </dev/null)
method=
if [ "$(printf '%s' "$repo_json" | jq -r .allow_squash_merge)" = true ]; then method=squash
elif [ "$(printf '%s' "$repo_json" | jq -r .allow_rebase_merge)" = true ]; then method=rebase
elif [ "$(printf '%s' "$repo_json" | jq -r .allow_merge_commit)" = true ]; then method=merge
fi
[ -n "$method" ] || refuse "no merge method allowed by the repo"

if ! out=$(gh pr merge "$url" "--$method" --match-head-commit "$head" </dev/null 2>&1); then
  echo "NOT MERGED $url: gh pr merge failed: $(printf '%s' "$out" | strip_ctrl | head -n 3 | tr '\n' ' ')"
  exit 1
fi
echo "MERGED $url $method at ${head:0:8}"
