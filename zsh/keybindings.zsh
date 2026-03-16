# Zsh-specific keybindings
# Loaded from .zshrc

# Use emacs-style keybindings (can change to vi with: bindkey -v)
bindkey -e

# History search with arrow keys
bindkey '^[[A' history-beginning-search-backward  # Up arrow
bindkey '^[[B' history-beginning-search-forward   # Down arrow

# Additional useful keybindings
bindkey '^[[1;5C' forward-word                    # Ctrl+Right arrow - move forward one word
bindkey '^[[1;5D' backward-word                   # Ctrl+Left arrow - move backward one word
bindkey '^[[H' beginning-of-line                  # Home key
bindkey '^[[F' end-of-line                        # End key
bindkey '^[[3~' delete-char                       # Delete key

# Zsh line editor (zle) widgets for better editing
# Ctrl+U - delete from cursor to beginning of line
bindkey '^U' backward-kill-line

# Ctrl+K - delete from cursor to end of line (default)
# Ctrl+W - delete word backward (default)
# Alt+Backspace - delete word backward
bindkey '^[^?' backward-kill-word

# Accept autosuggestion with Ctrl+Space or End key
bindkey '^ ' autosuggest-accept
bindkey '^[[F' autosuggest-accept
