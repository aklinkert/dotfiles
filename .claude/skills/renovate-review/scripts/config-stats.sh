#!/usr/bin/env bash
# Data for a Renovate config audit of one repo, as readable sections.
# Usage: config-stats.sh <owner/repo>
# Sections: config file, PR volume (30/90 days), Dependency Dashboard, merge settings and branch rules, open PRs.
# Env: RENOVATE_AUTHOR (default app/renovate), GH_HOST (GitHub Enterprise).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

case ${1:-} in */*) repo=$1 ;; *) echo "usage: $0 <owner/repo>" >&2; exit 2 ;; esac
RAW='Accept: application/vnd.github.raw+json'
section() { printf '\n== %s ==\n' "$1"; }

def_branch=$(gh api "repos/$repo" --jq .default_branch </dev/null)

section "config file (default branch $def_branch)"
found=
for p in renovate.json renovate.json5 .github/renovate.json .github/renovate.json5 .gitlab/renovate.json .renovaterc .renovaterc.json .renovaterc.json5; do
  if body=$(gh api -H "$RAW" "repos/$repo/contents/$p" </dev/null 2>/dev/null); then
    found=$p
    echo "path: $p"
    printf '%s\n' "$body" | strip_ctrl
    break
  fi
done
if [ -z "$found" ]; then
  if pj=$(gh api -H "$RAW" "repos/$repo/contents/package.json" </dev/null 2>/dev/null) \
    && cfg=$(printf '%s' "$pj" | jq '.renovate // empty' 2>/dev/null) && [ -n "$cfg" ]; then
    echo "path: package.json (renovate key)"
    printf '%s\n' "$cfg" | strip_ctrl
  else
    echo "no renovate config"
  fi
fi

section "PR volume (author $RENOVATE_AUTHOR)"
since=$(jq -nr 'now - 90 * 86400 | strftime("%Y-%m-%d")')
if prs=$(gh pr list -R "$repo" --author "$RENOVATE_AUTHOR" --state all --search "created:>=$since" \
  --json number,state,createdAt,mergedAt,closedAt,title,labels,headRefName --limit 1000 </dev/null); then
  # Group PR heuristic: a "update ..." title without " to " (e.g. "update Helm") counts as a group PR.
  printf '%s' "$prs" | jq -r '
    def win($d): map(select(.c >= (now - $d * 86400)));
    def cnt($s): map(select(.state == $s)) | length;
    def r1: (. * 10 | round) / 10;
    def pct($a; $b): if $b == 0 then "n/a" else "\(($a * 1000 / $b | round) / 10)%" end;
    map(. + {c: (.createdAt | fromdateiso8601)}) as $all
    | ($all | map(select(.state == "MERGED"))) as $merged
    | ($merged | map(((.mergedAt | fromdateiso8601) - .c) / 3600) | sort) as $h
    | ($h | length) as $n
    | "since \($since) (PRs created in window)",
      "last 30d: created=\($all | win(30) | length) merged=\($all | win(30) | cnt("MERGED")) closed_unmerged=\($all | win(30) | cnt("CLOSED")) open=\($all | win(30) | cnt("OPEN"))",
      "last 90d: created=\($all | length) merged=\($all | cnt("MERGED")) closed_unmerged=\($all | cnt("CLOSED")) open=\($all | cnt("OPEN"))",
      "PRs per week (90d): \(($all | length) / (90 / 7) | r1)",
      "hours to merge: median=\(if $n == 0 then "n/a" elif $n % 2 == 1 then $h[($n - 1) / 2 | floor] | r1 else (($h[$n / 2 - 1] + $h[$n / 2]) / 2) | r1 end) p90=\(if $n == 0 then "n/a" else $h[(0.9 * $n | ceil) - 1] | r1 end)",
      "group PRs among merged: \($merged | map(select(.title | test("^[a-z]+(\\(.*\\))?: update ") and (contains(" to ") | not))) | length) of \($n) (\(pct($merged | map(select(.title | test("^[a-z]+(\\(.*\\))?: update ") and (contains(" to ") | not))) | length; $n)))",
      "closed unmerged (noise signal): \($all | cnt("CLOSED"))",
      ($all | map(select(.state == "CLOSED")) | .[0:10][] | "  closed: #\(.number) \(.title)"),
      "top dependencies:",
      ($all
        | map(.title | (capture("update dependency (?<n>\\S+)").n)
            // (capture("update helm release (?<n>\\S+)").n)
            // (capture("update (?<n>\\S+) docker tag").n)
            // (capture("update (?<n>\\S+) (to|digest|action)").n)
            // empty)
        | group_by(.) | map({n: .[0], c: length}) | sort_by(-.c) | .[0:10][]
        | "  \(.c)x \(.n)")' --arg since "$since" | strip_ctrl
else
  echo "unavailable: could not list PRs"
fi

section "Dependency Dashboard issue"
if dash=$(gh issue list -R "$repo" --author "$RENOVATE_AUTHOR" --state open --search "Dependency Dashboard in:title" \
  --json url,title --limit 10 </dev/null 2>&1); then
  printf '%s' "$dash" | jq -r '[.[] | select(.title | test("Dependency Dashboard"))] | if length == 0 then "none" else .[0].url end'
else
  echo "unknown: $(printf '%s' "$dash" | strip_ctrl | head -n 1)"
fi

section "merge settings"
gh api "repos/$repo" </dev/null --jq '"allow_squash=\(.allow_squash_merge) allow_rebase=\(.allow_rebase_merge) allow_merge=\(.allow_merge_commit) allow_auto_merge=\(.allow_auto_merge) delete_branch_on_merge=\(.delete_branch_on_merge)"'

section "branch protection ($def_branch)"
if out=$(gh api "repos/$repo/branches/$def_branch/protection" </dev/null 2>&1); then
  printf '%s' "$out" | jq -r '"classic: strict=\(.required_status_checks.strict // "n/a") contexts=\([.required_status_checks.contexts // [] | .[]] | join(",")) required_reviews=\(.required_pull_request_reviews.required_approving_review_count // 0)"'
elif printf '%s' "$out" | grep -q '404'; then
  echo "classic: none (404, or no admin access to read it)"
else
  echo "classic: unreadable: $(printf '%s' "$out" | strip_ctrl | head -n 1)"
fi
if out=$(gh api "repos/$repo/rules/branches/$def_branch" </dev/null 2>&1); then
  printf '%s' "$out" | jq -r 'if length == 0 then "rulesets: no rules" else .[] | "ruleset rule: " + .type + (if (.type == "pull_request" or .type == "required_status_checks") then " " + (.parameters | tostring) else "" end) end' | strip_ctrl
else
  echo "rulesets: unreadable: $(printf '%s' "$out" | strip_ctrl | head -n 1)"
fi

section "open Renovate PRs"
if open=$(gh pr list -R "$repo" --author "$RENOVATE_AUTHOR" --state open --json number,createdAt,url --limit 200 </dev/null); then
  printf '%s' "$open" | jq -r 'if length == 0 then "open: 0" else (min_by(.createdAt)) as $o | "open: \(length)", "oldest: \($o.url) age_days=\(((now - ($o.createdAt | fromdateiso8601)) / 86400 * 10 | round) / 10)" end'
else
  echo "unavailable: could not list open PRs"
fi
