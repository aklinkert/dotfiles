# Bash-specific completions and configurations
# Only sourced when running bash

# Homebrew bash completion (macOS)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
  . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

# Bash completion (Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -f "/etc/profile.d/bash_completion.sh" ]; then
  source /etc/profile.d/bash_completion.sh
fi

# Tool completions for bash
if command -v task >/dev/null 2>&1; then
  eval "$(task --completion bash)"
fi

if command -v kubectl >/dev/null 2>&1; then
  eval "$(kubectl completion bash)"
fi
