#!/bin/sh
# PostToolUse on *agent_network__net_register: cache the address the server
# returned (it may differ from the requested name on collision) so
# statusline-command.sh can show the real one.
in=$(cat)
sid=$(printf '%s' "$in" | jq -r '.session_id // empty')
printf '%s' "$sid" | grep -Eq '^[0-9a-f-]{36}$' || exit 0
# MCP responses arrive as an object, a JSON string, or a content array of text blocks.
addr=$(printf '%s' "$in" | jq -r '
  [.tool_response | .. | (objects | .address?), (strings | fromjson? | .. | objects | .address?)]
  | map(select(type == "string")) | first // empty' 2>/dev/null)
printf '%s' "$addr" | grep -Eq '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$' || exit 0
dir="$HOME/.cache/agent-net"
mkdir -p "$dir" && printf '%s\n' "$addr" > "$dir/$sid"
exit 0
