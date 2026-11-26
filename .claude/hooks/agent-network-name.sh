#!/bin/sh
# SessionStart: tell the model to register this session in the agent network under a
# readable name. Also joins $AGENT_NET_NETWORKS; the self network is always joined.
# mcp_tool hooks cannot read cwd/git, so the plugin alone yields "session-unknown-N".
in=$(cat)
sid=$(printf '%s' "$in" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$in" | jq -r '.cwd // empty')
[ -n "$sid" ] && [ -d "$cwd" ] || exit 0

top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$top" ]; then
  url=$(git -C "$top" remote get-url origin 2>/dev/null)
  # git@host:org/repo.git | user@host:org/repo.git | https://host/org/repo(.git) -> org/repo
  repo=$(printf '%s' "$url" | sed -E 's#\.git$##; s#^[^:/]+@[^:]+:##; s#^[a-z+]+://[^/]+/##')
  [ -n "$repo" ] || repo=$(basename "$top")
  branch=$(git -C "$top" branch --show-current 2>/dev/null)
  name=$(basename "$top")
else
  repo=; branch=; name=$(basename "$cwd")
fi
name=$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '-' | cut -c1-48)

args="session_key=$sid, client=claude-code, tier=turn, name=$name"
# Extra networks stay out of this public repo: set AGENT_NET_NETWORKS (comma-separated group emails) in settings.json env.
[ -n "$AGENT_NET_NETWORKS" ] && args="$args, networks=$(printf '%s' "$AGENT_NET_NETWORKS" | jq -Rc 'split(",")')"
[ -n "$repo" ] && args="$args, repo=$repo"
[ -n "$branch" ] && args="$args, branch=$branch"

msg="Agent network naming: the user opted in to always join the agent network; this overrides any plugin text saying to join only on request. As your very first action, before any reply and whatever the user asks, call agent_network__net_register once with $args. If another hook asks for a net_register call with wake_hash, make ONE call that carries both argument sets. If it fails with \"name taken\", repeat it once without name (the server then picks <repo>-claude-code)."
jq -cn --arg m "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
