# Zsh-specific plugin configurations
# Loaded from .zshrc

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'  # Subtle gray for suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # Suggest from history and completions
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20        # Disable for large buffers

# zsh-syntax-highlighting configuration
# Customize highlighting colors (optional)
# ZSH_HIGHLIGHT_STYLES[command]='fg=green'
# ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
# ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan'
# ZSH_HIGHLIGHT_STYLES[function]='fg=cyan'
# ZSH_HIGHLIGHT_STYLES[path]='underline'

# direnv hook (loaded via Oh My Zsh plugin, but can be configured here)
# Additional direnv configuration if needed

# git plugin is loaded by Oh My Zsh, provides many useful aliases
# Common git aliases from the plugin:
# gst = git status
# gco = git checkout
# gcm = git checkout main
# gp = git push
# gl = git pull
# glog = git log with graph
# And many more...

# docker and docker-compose plugins provide completion and aliases
# Examples:
# dps = docker ps
# dexec = docker exec -it
# dcup = docker compose up
# dcdown = docker compose down

# kubectl plugin provides aliases:
# k = kubectl
# kgp = kubectl get pods
# kgs = kubectl get services
# kdp = kubectl describe pod
# And many more...

# z plugin provides directory jumping
# After using a directory, you can jump to it with: z <partial-name>
# Example: z dotfiles (jumps to ~/dotfiles or similar)
