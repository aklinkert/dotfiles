#!/usr/bin/env bash
# List open Renovate PRs with files, commit authors and check state, one JSON object per line.
# Usage: list-prs.sh <owner | owner/repo | PR-URL>...
# Output (jq -c): url, repo, number, title, labels[], draft, mergeable, mergeState, reviewDecision,
#   headSha, headRef, baseRef, createdAt, author, automerge (true|false|null), files[], filesTruncated,
#   additions, deletions, foreignCommitAuthors[], commitsTruncated, checks{failing,pending,passed,skipped}.
# Env: RENOVATE_AUTHOR (default app/renovate), RENOVATE_LOGIN_RE, GH_HOST (GitHub Enterprise).
# Exit: non-zero if any scope failed (errors on stderr, remaining scopes still processed).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ $# -ge 1 ] || { echo "usage: $0 <owner|owner/repo|PR-URL>..." >&2; exit 2; }

FIELDS=number,url,title,body,labels,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefOid,headRefName,baseRefName,createdAt,author,files,commits,statusCheckRollup,additions,deletions

# shellcheck disable=SC2016
EMIT='
{url, repo: $repo, number, title,
 labels: [.labels[].name], draft: .isDraft, mergeable, mergeState: .mergeStateStatus, reviewDecision,
 headSha: .headRefOid, headRef: .headRefName, baseRef: .baseRefName, createdAt, author: .author.login,
 automerge: (if ((.body // "") | test("\\*\\*Automerge\\*\\*: Enabled")) then true
             elif ((.body // "") | test("\\*\\*Automerge\\*\\*: Disabled")) then false
             else null end),
 files: [.files[].path], filesTruncated: ((.files | length) >= 100), additions, deletions,
 foreignCommitAuthors: ([.commits[].authors[]
     | if (.login // "") == "" then "<unlinked:\(.name // "?")>"
       elif (.login | test($re)) then empty
       else .login end] | unique),
 commitsTruncated: ((.commits | length) >= 250),
 checks: classify}'

failed=0
for scope in "$@"; do
  urls=
  case $scope in
    http://*|https://*)
      urls=$scope ;;
    */*)
      if ! urls=$(gh pr list -R "$scope" --author "$RENOVATE_AUTHOR" --state open --json url --limit 200 --jq '.[].url' </dev/null); then
        echo "list-prs: cannot list $scope" >&2; failed=1; continue
      fi ;;
    *)
      if ! urls=$(gh search prs --owner "$scope" --author "$RENOVATE_AUTHOR" --state open --json url --limit 200 --jq '.[].url' </dev/null); then
        echo "list-prs: cannot search $scope" >&2; failed=1; continue
      fi ;;
  esac
  while IFS= read -r url; do
    [ -n "$url" ] || continue
    if ! parse_pr_url "$url"; then failed=1; continue; fi
    if ! pr=$(gh pr view "$url" --json "$FIELDS" </dev/null); then
      echo "list-prs: cannot read $url" >&2; failed=1; continue
    fi
    printf '%s' "$pr" | jq -c --arg repo "$PR_REPO" --arg re "$RENOVATE_LOGIN_RE" "$CHECKS_JQ$EMIT"
  done <<EOF
$urls
EOF
done
exit "$failed"
