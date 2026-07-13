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

# Assemble the full styled line, profile first, path collapsed:
#   ⚙ profile • <path> • <git> • <context> • <model> • <cost> …
if [[ "$out" == "${esc}[36m"*"${esc}[0m"* ]]; then
  rest="${out#"${esc}[36m"}"          # strip leading cyan
  path="${rest%%"${esc}[0m"*}"        # path up to reset
  tail="${rest#*"${esc}[0m"}"         # separator + remaining segments
  full="${prefix}${esc}[36m$(shorten_path "$path")${esc}[0m${tail}"
else
  full="${prefix}${out}"
fi

# Width-aware wrap. Claude Code exports $COLUMNS to the statusline command, and
# it truncates each output line to the pane width (it does not soft-wrap). So we
# keep everything on one row while it fits, and once it would overflow we break
# at " • " segment boundaries onto extra rows — nothing is cut. Profile and path
# come first, so they always land on row one.
shopt -s extglob
cols=$(( ${COLUMNS:-999} - 1 ))
mapfile -t segs <<< "${full//"$sep"/$'\n'}"
line=""; llen=0
for s in "${segs[@]}"; do
  clean=${s//"$esc"\[*([0-9;])m/}     # strip ANSI for width measurement
  slen=${#clean}
  if [ -z "$line" ]; then
    line="$s"; llen=$slen
  elif (( llen + 3 + slen <= cols )); then
    line+="${sep}${s}"; llen=$(( llen + 3 + slen ))
  else
    printf '%s\n' "$line"
    line="$s"; llen=$slen
  fi
done
printf '%s' "$line"
