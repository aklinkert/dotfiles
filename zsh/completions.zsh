# Zsh-specific completions
# Loaded from .zshrc

# Enable completion system if not already enabled by Oh My Zsh
# autoload -Uz compinit && compinit

# Completion styling
zstyle ':completion:*' menu select                    # Menu-driven completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colorize completion lists
zstyle ':completion:*' group-name ''                  # Group completions by category
zstyle ':completion:*:descriptions' format '%B%d%b'   # Format group descriptions

# Kubectl completion (if not already handled by Oh My Zsh plugin)
# command -v kubectl >/dev/null 2>&1 && source <(kubectl completion zsh)

# Task (go-task/task) completion
if command -v task >/dev/null 2>&1; then
  eval "$(task --completion zsh)"
fi

# Additional tool completions can be added here
# Example: terraform, helm, aws-cli, etc.
