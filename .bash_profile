export PATH=~/.asdf/shims:~/bin:/usr/local/bin:$HOME/go/bin:$HOME/bin:$PATH:${HOME}/.krew/bin

export NODE_ENV=development
export NVM_DIR=~/.nvm
export GOPATH=~/go

export GIT_MERGE_AUTOEDIT=no

export GPG_TTY=$(tty)
export EDITOR="code -w"

alias reload="source ~/.bash_profile"

if [ -n "$(which eza)" ]; then
  alias ll="eza -l --git --all --long --header"
else
  alias ll="ls -al"
fi

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

alias grom="git rebase origin/main"
alias gurm="git checkout main && gp && git checkout - && grom"
alias grod="git rebase origin/dev"
alias gurd="git checkout dev && gp && git checkout - && grod"
alias gron="git rebase origin/next"
alias gurn="git checkout next && gp && git checkout - && gron"

alias first_col="awk '{ print \$1 }'"
alias remove_first_line="tail -n +2"
alias second_col="awk '{ print \$2 }'"
alias third_col="awk '{ print \$3 }'"
alias k="kubectl"
alias tf="terraform"
alias please="sudo"
alias go-vendors="go mod download && go mod tidy"
alias dc="docker compose"

source ~/functions.sh

# consuming OS specific configuration/function files
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source "${HOME}/dotfiles/linux.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  source "${HOME}/dotfiles/darwin.sh"
fi

export LC_ALL=en_US.UTF-8
export LP_ENABLE_TITLE=1
# export LP_MARK_PREFIX=$'\n'
export LP_ENABLE_AWS_PROFILE=0
export LP_ENABLE_KUBECONTEXT=0
export LP_PS1

# Only load Liquidprompt in interactive shells, not from a script or from scp
if [[ $- = *i* ]]; then
  source ~/dotfiles/liquidprompt/liquidprompt

  if [[ $(type -t lp_title) == function ]]; then
    if [ -n "${PROJECT_PREFIX}" ]; then
      lp_title "${PROJECT_PREFIX} - `basename $(pwd)`"
    else
      lp_title "`basename $(pwd)`"
    fi
  fi
fi

eval "$(direnv hook bash)"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

if [ -n "$(which task)" ]; then
  eval "$(task --completion bash)"
fi

if [ -n "$(which kubectl)" ]; then
  eval "$(kubectl completion bash)"
fi

for f in "$HOME/dotfiles/customers/*.sh"; do
    echoc blue "Including customer config for ${f}"
    source $f
done
