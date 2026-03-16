# Shell-agnostic configuration
# This file is sourced by both .bash_profile and .zshrc
# Use only POSIX-compatible syntax that works in both bash and zsh

# PATH Configuration
export PATH=~/.asdf/shims:~/bin:/usr/local/bin:$HOME/go/bin:$HOME/bin:$PATH:${HOME}/.krew/bin

# Environment Variables
export NODE_ENV=development
export NVM_DIR=~/.nvm
export GOPATH=~/go
export GIT_MERGE_AUTOEDIT=no
export GPG_TTY=$(tty)
export EDITOR="code -w"
export LC_ALL=en_US.UTF-8

# Liquidprompt settings (bash-specific but harmless in zsh)
export LP_ENABLE_TITLE=1
export LP_ENABLE_AWS_PROFILE=0
export LP_ENABLE_KUBECONTEXT=0
export LP_PS1

# Docker configuration
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

# Silence bash deprecation warning on macOS
export BASH_SILENCE_DEPRECATION_WARNING=1

# ls/eza alias - check if eza is available
if command -v eza >/dev/null 2>&1; then
  alias ll="eza -l --git --all --long --header"
else
  alias ll="ls -al"
fi

# Git aliases
alias ga="git add"
alias gaa="git add --all :/"
alias grc="gaa; git rebase --continue"
alias gcm="git commit -s -S -m"
alias gca="git commit -s -S --amend"
alias gcan="git commit -s -S --amend --no-edit"
alias gpr="git pull-request"
alias gpo="git push origin"
alias gp="git pull --rebase"
alias gpp="gp ; gpo"
alias gd="git diff"
alias gds="git diff --staged"
alias grs="git restore --staged ."
alias gs="git status"
alias gsa="git stash save"
alias gsp="git stash pop"
alias gf="git fetch --prune && git branch --merged | grep -v \"\*\" | xargs -n 1 git branch -d; git branch -vv | grep ': gone]' | grep -v '\*' | awk '{ print \$1; }' | xargs -r git branch -D"
alias gl="git log --pretty=oneline --abbrev-commit --graph --decorate"

# Git rebase aliases
alias grom="git rebase origin/main"
alias gurm="git checkout main && gp && git checkout - && grom"
alias grod="git rebase origin/dev"
alias gurd="git checkout dev && gp && git checkout - && grod"
alias gron="git rebase origin/next"
alias gurn="git checkout next && gp && git checkout - && gron"

# Text processing aliases
alias first_col="awk '{ print \$1 }'"
alias remove_first_line="tail -n +2"
alias second_col="awk '{ print \$2 }'"
alias third_col="awk '{ print \$3 }'"
alias to_lower="awk '{ print tolower(\$0)} '"
alias to_upper="awk '{ print toupper(\$0)} '"

# Tool aliases
alias k="kubectl"
alias tf="terraform"
alias please="sudo"
alias go-vendors="go mod download && go mod tidy"
alias dc="docker compose"

# Shell switching helper
alias switch-shell="~/dotfiles/switch-shell.sh"
