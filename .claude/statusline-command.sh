#!/usr/bin/env bash
# Wrapper around claudia-statusline (real binary: statusline-bin).
# - Appends the active CCS profile when running under ~/.ccs/instances/<profile>.
# - Collapses long working-dir paths so the right-hand segments (git, context,
#   model, cost) stay on-screen. claudia-statusline emits the full home-relative
#   path with no width cap, so deep worktree CWDs push the tail off the terminal.

BIN="/Users/alex/.local/bin/statusline-bin"

# Subcommands (migrate, health, context-learning, ...) pass straight through.
if [ "$#" -gt 0 ]; then
  exec "$BIN" "$@"
fi

input="$(cat)"
out="$(printf '%s' "$input" | "$BIN")"

# Collapse the leading cyan directory segment.
# - Claude worktrees live at <git-root>/.claude/worktrees/<name>; collapse those
#   to the git root (the worktree name is already shown in the git branch).
# - Otherwise, when still too long, keep first two and last two components.
esc=$'\033'
shorten_path() {
  local p="$1" max=45
  # Inside a Claude worktree → show the git root (parent of .claude/worktrees).
  [[ "$p" == */.claude/worktrees/* ]] && p="${p%/.claude/worktrees/*}"
  [ "${#p}" -le "$max" ] && { printf '%s' "$p"; return; }
  local -a seg
  IFS=/ read -ra seg <<< "$p"
  local n=${#seg[@]}
  (( n <= 4 )) && { printf '%s' "$p"; return; }
  printf '%s/%s/…/%s/%s' "${seg[0]}" "${seg[1]}" "${seg[n-2]}" "${seg[n-1]}"
}

profile=""
case "$CLAUDE_CONFIG_DIR" in
  */.ccs/instances/*) profile="$(basename "$CLAUDE_CONFIG_DIR")" ;;
esac

# dim grey bullet separator, matching the one claudia-statusline emits
sepc="${esc}[38;5;245m•${esc}[0m"
sep=" ${sepc} "
prefix=""
[ -n "$profile" ] && prefix="${esc}[2;38;5;245m⚙ ${profile}${esc}[0m${sep}"

# Two-line layout: line 1 = ⚙ profile • <path>, line 2 = everything else
# (git branch, context, model, cost, day usage). Keeping the profile and the
# collapsed path on line 1 guarantees both are always visible; the metrics
# reflow onto line 2 instead of being truncated off the right edge.
if [[ "$out" == "${esc}[36m"*"${esc}[0m"* ]]; then
  rest="${out#"${esc}[36m"}"          # strip leading cyan
  path="${rest%%"${esc}[0m"*}"        # path up to reset
  tail="${rest#*"${esc}[0m"}"         # separator + remaining segments
  tail="${tail#"$sep"}"               # drop the separator now leading line 2
  printf '%s%s\n%s' "$prefix" "${esc}[36m$(shorten_path "$path")${esc}[0m" "$tail"
elif [ -n "$prefix" ]; then
  printf '%s\n%s' "${prefix%"$sep"}" "$out"
else
  printf '%s' "$out"
fi
