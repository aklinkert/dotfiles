# Bash Profile - Updated for bash/zsh dual support
# Sources shared configuration and bash-specific settings

# Load shell-agnostic common configuration
source ~/dotfiles/shell_common.sh

# Load shared functions
source ~/dotfiles/functions.sh

# Load OS-specific configuration
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source "${HOME}/dotfiles/linux_common.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  source "${HOME}/dotfiles/darwin_common.sh"
fi

# Bash-specific: reload alias
alias reload="source ~/.bash_profile"

# Bash-specific: completions
source ~/dotfiles/bash/completions.bash

# Liquidprompt (bash-specific prompt)
# Only load in interactive shells, not from a script or from scp
if [[ $- = *i* ]]; then
  source ~/dotfiles/liquidprompt/liquidprompt

  if [[ $(type -t lp_title) == function ]]; then
    if [ -n "${PROJECT_PREFIX}" ]; then
      lp_title "${PROJECT_PREFIX} - $(basename $(pwd))"
    else
      lp_title "$(basename $(pwd))"
    fi
  fi
fi

# direnv integration
eval "$(direnv hook bash)"

# iTerm2 shell integration (bash)
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# Load customer-specific configurations
for f in "$HOME/dotfiles/customers"/*.sh; do
    if [ -f "$f" ]; then
        source "$f"
    fi
done

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/alex/.lmstudio/bin"
# End of LM Studio CLI section

