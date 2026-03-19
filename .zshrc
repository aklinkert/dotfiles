# Zsh Configuration - Modern shell with Oh My Zsh
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# IMPORTANT: Load PATH and environment BEFORE Oh My Zsh
# This ensures plugins can find commands like docker, direnv, kubectl, etc.

# Load shell-agnostic common configuration (sets PATH, exports, aliases)
source ~/dotfiles/shell_common.sh

# Load OS-specific configuration (adds Homebrew, asdf, etc. to PATH)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source "${HOME}/dotfiles/linux_common.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  source "${HOME}/dotfiles/darwin_common.sh"
fi

# Now that PATH is set up, configure Oh My Zsh

# Git prompt settings - enable detailed status indicators
# These must be set before Oh My Zsh loads
export GIT_PROMPT_DIRTY="%{$fg[red]%}✗%{$reset_color%}"
export GIT_PROMPT_CLEAN="%{$fg[green]%}✓%{$reset_color%}"

# Enable git status in prompt (shows untracked, modified, etc.)
# This makes robbyrussell theme more informative
DISABLE_UNTRACKED_FILES_DIRTY="false"

# git-prompt plugin settings (provides detailed status indicators)
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}) %{$fg[green]%}✓"

# Show indicators for uncommitted changes
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}+"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}△"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}-"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}➜"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}═"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}?"

# Theme - using robbyrussell (clean, fast, git-aware)
# Other good options: agnoster, powerlevel10k/powerlevel10k, spaceship
# skaro, simonoff
ZSH_THEME="sunrise"

# Oh My Zsh plugins
# Standard plugins: $ZSH/plugins/
# Custom plugins: $ZSH_CUSTOM/plugins/
plugins=(
  git                          # Git aliases and functions
  git-prompt                   # Enhanced git status in prompt
  docker                       # Docker completion and aliases  
  docker-compose              # Docker Compose completion
  kubectl                      # Kubectl completion and aliases
  asdf                         # asdf version manager
  direnv                       # direnv integration
  z                            # Jump to frequently used directories
  zsh-syntax-highlighting     # Syntax highlighting (must be last or near-last)
  zsh-autosuggestions         # Command suggestions based on history
)

# Load Oh My Zsh (now with PATH properly set)
source $ZSH/oh-my-zsh.sh

# Re-source shell_common.sh AFTER Oh My Zsh to override plugin aliases
# Oh My Zsh git plugin sets its own aliases (gl, gp, etc.)
# We want our custom aliases to take precedence
source ~/dotfiles/shell_common.sh

# Load shared functions
source ~/dotfiles/functions.sh

# Zsh-specific: reload alias
alias reload="source ~/.zshrc"

# Zsh-specific configurations will be loaded from ~/dotfiles/zsh/
if [ -d ~/dotfiles/zsh ]; then
  # Load zsh-specific completions
  [ -f ~/dotfiles/zsh/completions.zsh ] && source ~/dotfiles/zsh/completions.zsh
  
  # Load zsh-specific keybindings
  [ -f ~/dotfiles/zsh/keybindings.zsh ] && source ~/dotfiles/zsh/keybindings.zsh
  
  # Load zsh-specific plugins configuration
  [ -f ~/dotfiles/zsh/plugins.zsh ] && source ~/dotfiles/zsh/plugins.zsh
fi

# iTerm2 shell integration (zsh)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Load customer-specific configurations
for f in "$HOME/dotfiles/customers"/*.sh; do
    if [ -f "$f" ]; then
        source "$f"
    fi
done

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/alex/.lmstudio/bin"
# End of LM Studio CLI section

# Zsh Options
setopt AUTO_CD              # cd by typing directory name if it's not a command
setopt AUTO_PUSHD           # Make cd push old directory onto directory stack
setopt PUSHD_IGNORE_DUPS    # Don't push multiple copies of same directory
setopt PUSHD_SILENT         # Don't print directory stack after pushd/popd
setopt CORRECT              # Spelling correction for commands
setopt EXTENDED_GLOB        # Extended globbing syntax
setopt NO_CASE_GLOB         # Case-insensitive globbing
setopt NUMERIC_GLOB_SORT    # Sort filenames numerically when possible

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY       # Append to history file
setopt SHARE_HISTORY        # Share history between sessions
setopt HIST_IGNORE_DUPS     # Don't record duplicates
setopt HIST_IGNORE_SPACE    # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks from history
