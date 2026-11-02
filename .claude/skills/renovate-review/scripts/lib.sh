#!/usr/bin/env bash
# Shared helpers, sourced by the other scripts (not run directly).
# Env: RENOVATE_AUTHOR (default app/renovate), RENOVATE_LOGIN_RE (default ^renovate(\[bot\])?$).
# shellcheck disable=SC2034

RENOVATE_AUTHOR="${RENOVATE_AUTHOR:-app/renovate}"
if [ -z "${RENOVATE_LOGIN_RE:-}" ]; then
  RENOVATE_LOGIN_RE='^renovate(\[bot\])?$'
fi

# Sets PR_HOST PR_OWNER PR_REPO PR_NUM from https://<host>/<owner>/<repo>/pull/<n>;
# exports GH_HOST for non-github.com hosts.
parse_pr_url() {
  local url=$1 rest
  case $url in
    https://*/*/*/pull/*) ;;
    *) echo "not a PR URL: $url" >&2; return 1 ;;
  esac
  rest=${url#https://}
  PR_HOST=${rest%%/*}; rest=${rest#*/}
  PR_OWNER=${rest%%/*}; rest=${rest#*/}
  PR_REPO=$PR_OWNER/${rest%%/*}; rest=${rest#*/pull/}
  PR_NUM=${rest%%[!0-9]*}
  [ -n "$PR_NUM" ] || { echo "not a PR URL: $url" >&2; return 1; }
  if [ "$PR_HOST" != github.com ]; then
    export GH_HOST=$PR_HOST
  fi
}

# jq definition: `classify` turns a PR object (with statusCheckRollup) into
# {failing:[names], pending:[names], passed:N, skipped:N}.
# shellcheck disable=SC2016
CHECKS_JQ='
def classify:
  (.statusCheckRollup // [])
  | map(
      if (.__typename == "StatusContext") or (has("context") and (has("name") | not)) then
        {n: .context,
         s: (if .state == "SUCCESS" then "passed"
             elif (.state == "PENDING" or .state == "EXPECTED") then "pending"
             else "failing" end)}
      else
        {n: .name,
         s: (if (.status != "COMPLETED") or ((.conclusion // "") == "") then "pending"
             elif (.conclusion == "SUCCESS" or .conclusion == "NEUTRAL") then "passed"
             elif .conclusion == "SKIPPED" then "skipped"
             else "failing" end)}
      end)
  | {failing: [.[] | select(.s == "failing") | .n],
     pending: [.[] | select(.s == "pending") | .n],
     passed: (map(select(.s == "passed")) | length),
     skipped: (map(select(.s == "skipped")) | length)};
'

# Strip control characters (keeps newline and tab).
strip_ctrl() { LC_ALL=C tr -d '\000-\010\013-\037\177'; }
