# Linux-specific configuration (shell-agnostic)
# Works with both bash and zsh

# pbcopy/pbpaste aliases for Linux (using xclip)
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# k9s alias if installed from source
if [ -d "/home/alex/src/github.com/derailed/k9s" ]; then
  alias k9s="/home/alex/src/github.com/derailed/k9s/execs/k9s"
fi

# Homebrew on Linux
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi
