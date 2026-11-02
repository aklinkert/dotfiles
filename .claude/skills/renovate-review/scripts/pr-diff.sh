#!/usr/bin/env bash
# Compact view of a PR change: per file the "+++ b/<path>" line and only the changed lines.
# Usage: pr-diff.sh <pr-url>
# Output: lines cut to 200 chars, at most 60 changed lines per file, then "... N more lines".
# Env: GH_HOST (GitHub Enterprise; derived from the URL when it is not github.com).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ $# -eq 1 ] || { echo "usage: $0 <pr-url>" >&2; exit 2; }
parse_pr_url "$1"

gh pr diff "$1" --color never </dev/null | awk '
  function flush() {
    if (extra > 0) printf "... %d more lines\n", extra
    extra = 0; n = 0
  }
  /^diff --git / { flush(); hdr = 1; split($0, g, " b/"); gitpath = g[2]; next }
  hdr && /^\+\+\+ / {
    if ($0 == "+++ /dev/null") print "+++ /dev/null (deleted " gitpath ")"; else print substr($0, 1, 200)
    next
  }
  hdr && /^@@/ { hdr = 0; next }
  hdr { next }
  /^[-+]/ {
    if (n < 60) { print substr($0, 1, 200); n++ } else extra++
  }
  END { flush() }
' | strip_ctrl
