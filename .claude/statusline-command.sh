#!/usr/bin/env bash
# Claude Code status line — Liquidprompt-style
# Receives JSON on stdin from Claude Code

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Git branch (skip optional lock, suppress errors)
git_branch=""
if git_branch_raw=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch="$git_branch_raw"
elif git_branch_raw=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
  git_branch="$git_branch_raw"
fi

# Build status line using ANSI colors (dimmed by terminal)
user_host=$(printf '\033[32m%s@%s\033[0m' "$(whoami)" "$(hostname -s)")
dir_part=$(printf '\033[34m%s\033[0m' "$short_cwd")

branch_part=""
if [ -n "$git_branch" ]; then
  branch_part=$(printf ' \033[33m(%s)\033[0m' "$git_branch")
fi

model_part=""
if [ -n "$model" ]; then
  model_part=$(printf ' \033[36m[%s]\033[0m' "$model")
fi

ctx_part=""
if [ -n "$used" ]; then
  ctx_int=${used%.*}
  if [ -n "$input_tokens" ] && [ -n "$context_window_size" ]; then
    # Format token counts in a human-readable way (k = thousands)
    fmt_tokens() {
      local n=$1
      if [ "$n" -ge 1000 ]; then
        printf '%dk' "$((n / 1000))"
      else
        printf '%d' "$n"
      fi
    }
    cur_fmt=$(fmt_tokens "$input_tokens")
    max_fmt=$(fmt_tokens "$context_window_size")
    ctx_part=$(printf ' \033[35mctx:%s%% (%s/%s)\033[0m' "$ctx_int" "$cur_fmt" "$max_fmt")
  else
    ctx_part=$(printf ' \033[35mctx:%s%%\033[0m' "$ctx_int")
  fi
fi

vim_part=""
if [ -n "$vim_mode" ]; then
  vim_part=$(printf ' \033[1;33m[%s]\033[0m' "$vim_mode")
fi

printf '%s %s%s%s%s%s' \
  "$user_host" \
  "$dir_part" \
  "$branch_part" \
  "$model_part" \
  "$ctx_part" \
  "$vim_part"
