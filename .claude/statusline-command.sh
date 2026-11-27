#!/usr/bin/env bash
# Wrapper around claudia-statusline (real binary: statusline-bin).
# - Appends the active CCS profile when running under ~/.ccs/instances/<profile>.
# - Collapses long working-dir paths so the right-hand segments (git, context,
#   model, cost) stay on-screen. claudia-statusline emits the full home-relative
#   path with no width cap, so deep worktree CWDs push the tail off the terminal.

BIN="/Users/alex/.local/bin/statusline-bin"

# Pin a UTF-8 locale: the width-wrap below measures string length with
# ${#clean}, which under a C/unset locale counts multibyte glyphs (the PR
# segment's ✓ ✗ ● ○ icons) as multiple chars each, throwing off the wrap math
# and triggering early/incorrect line breaks.
export LC_ALL="${LC_ALL:-C.UTF-8}"

# Subcommands (migrate, health, context-learning, ...) pass straight through.
if [ "$#" -gt 0 ]; then
  exec "$BIN" "$@"
fi

input="$(cat)"
out="$(printf '%s' "$input" | "$BIN")"
esc=$'\033'

# Optional GitHub PR segment. Claude Code includes an optional top-level `pr`
# object (number, url, review_state) when an open PR exists for the current
# branch/worktree; statusline-bin doesn't render it, so build it here from the
# raw stdin JSON. Absent `pr`/fields or missing jq → pr_seg stays empty (no-op).
pr_seg=""
if command -v jq >/dev/null 2>&1; then
  # Single jq call (this runs on every render): emit number + review_state
  # tab-separated so both come back from one invocation.
  # \x1f separator: tab is IFS-whitespace, so empty fields would collapse.
  IFS=$'\x1f' read -r pr_num pr_state session_id transcript < <(printf '%s' "$input" | jq -r '"\(.pr.number // "")\u001f\(.pr.review_state // "")\u001f\(.session_id // "")\u001f\(.transcript_path // "")"' 2>/dev/null)
  # Injection hardening: pr_num must be a bare integer before it ever reaches
  # output/printf. review_state is safe as-is since it's only matched against
  # fixed `case` patterns below, never interpolated.
  [[ "$pr_num" =~ ^[0-9]+$ ]] || pr_num=""
  if [ -n "$pr_num" ]; then
    pr_color="" pr_icon=""
    case "$pr_state" in
      approved)           pr_color="${esc}[38;5;42m";    pr_icon=" ✓" ;;
      changes_requested)  pr_color="${esc}[38;5;196m";   pr_icon=" ✗" ;;
      pending)            pr_color="${esc}[38;5;214m";   pr_icon=" ●" ;;
      draft)               pr_color="${esc}[2;38;5;245m"; pr_icon=" ○" ;;
    esac
    if [ -n "$pr_color" ]; then
      pr_seg="${pr_color}PR #${pr_num}${pr_icon}${esc}[0m"
    else
      pr_seg="PR #${pr_num}"
    fi
  fi
fi

# Collapse the leading cyan directory segment.
# - Claude worktrees live at <git-root>/.claude/worktrees/<name>; collapse those
#   to the git root (the worktree name is already shown in the git branch).
# - Otherwise, when still too long, keep first two and last two components.
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

# Agent-network address peers use to reach this session, exactly as the server
# returned it to net_register (hooks/agent-network-address.sh caches it). No
# cache entry = not registered yet, so show nothing rather than guess.
# A server-side join (net_inbox hook, no tool call) or a rename only says the address
# in hook context. Scan transcript bytes added since the last render; the unescaped
# '"type":"hook_additional_context"' only matches a real hook attachment, not pasted text.
net_seg=""
if [[ "$session_id" =~ ^[0-9a-f-]{36}$ ]]; then
  cache="$HOME/.cache/agent-net/$session_id"
  if [[ -f "$transcript" ]]; then
    size=$(wc -c < "$transcript" | tr -d ' ')
    off=$(cat "$cache.off" 2>/dev/null); [[ "$off" =~ ^[0-9]+$ && "$off" -le "$size" ]] || off=0
    if (( size > off )); then
      found="$(tail -c +"$((off + 1))" "$transcript" | head -c "$((size - off))" \
        | grep -F '"type":"hook_additional_context"' \
        | grep -oE "this session's address is (now )?[A-Za-z0-9._-]+/[A-Za-z0-9._-]+" | tail -1 | awk '{print $NF}')"
      mkdir -p "${cache%/*}"
      [[ -n "$found" ]] && printf '%s\n' "$found" > "$cache"
      printf '%s\n' "$size" > "$cache.off"
    fi
  fi
  addr="$(head -1 "$cache" 2>/dev/null)"
  [[ "$addr" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] && net_seg="${esc}[38;5;110m✉ ${addr}${esc}[0m"
fi

# Assemble the full styled line, profile first, path collapsed:
#   ⚙ profile • <path> • <git> • <context> • <model> • <cost> …
if [[ "$out" == "${esc}[36m"*"${esc}[0m"* ]]; then
  rest="${out#"${esc}[36m"}"          # strip leading cyan
  path="${rest%%"${esc}[0m"*}"        # path up to reset
  tail="${rest#*"${esc}[0m"}"         # separator + remaining segments
  full="${prefix}${esc}[36m$(shorten_path "$path")${esc}[0m${tail}"
  [ -n "$pr_seg" ] && full="${full}${sep}${pr_seg}"
  [ -n "$net_seg" ] && full="${full}${sep}${net_seg}"
else
  full="${prefix}${out}"
  [ -n "$pr_seg" ] && full="${full}${sep}${pr_seg}"
  [ -n "$net_seg" ] && full="${full}${sep}${net_seg}"
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
