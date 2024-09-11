export PATH=~/bin:/usr/local/bin:$HOME/go/bin:$HOME/bin:$PATH:${HOME}/.krew/bin

export NODE_ENV=development
export NVM_DIR=~/.nvm
export GOPATH=~/go

export GIT_MERGE_AUTOEDIT=no

export GPG_TTY=$(tty)
export EDITOR="code -w"
export DC="docker-compose"

alias reload="source ~/.bash_profile"

if [ -n "$(which eza)" ]; then
  alias ll="eza -l --git --all --long --header"
else
  alias ll="ls -al"
fi

alias ga="git add"
alias gaa="git add --all :/"
alias grc="gaa; git rebase --continue"
alias gcm="git commit -s -S ${GIT_COMMIT_GPG_KEY_ID:-} -m"
alias gca="git commit -s -S ${GIT_COMMIT_GPG_KEY_ID:-} --amend"
alias gcan="git commit -s -S ${GIT_COMMIT_GPG_KEY_ID:-} --amend --no-edit"
alias gpr="git pull-request"
alias grom="git rebase origin/main"
alias grod="git rebase origin/dev"
alias gron="git rebase origin/next"
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
alias gurd="git checkout dev && gp && git checkout - && grod"
alias gurn="git checkout next && gp && git checkout - && gron"
alias first_col="awk '{ print \$1 }'"
alias remove_first_line="tail -n +2"
alias second_col="awk '{ print \$2 }'"
alias third_col="awk '{ print \$3 }'"
alias dc='eval "$DC"'
alias k="kubectl"
alias tf="terraform"
alias please="sudo"
alias aws-login="aws sso login --no-browser"
alias go-vendors="go mod download && go mod tidy"

# consuming OS specific configuration/function files
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source "${HOME}/dotfiles/linux.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  source "${HOME}/dotfiles/darwin.sh"
fi

source ~/functions.sh

export LC_ALL=en_US.UTF-8
export LP_ENABLE_TITLE=1
# export LP_MARK_PREFIX=$'\n'
export LP_ENABLE_AWS_PROFILE=0
export LP_ENABLE_KUBECONTEXT=0
export LP_PS1

# Only load Liquidprompt in interactive shells, not from a script or from scp
[[ $- = *i* ]] && source ~/dotfiles/liquidprompt/liquidprompt

eval "$(direnv hook bash)"
source <(kubectl completion bash)

for f in "$HOME/dotfiles/customers/*.sh"; do
    echoc blue "Including customer config for ${f}"
    source $f
done

# BEGIN SNIPPET: Platform.sh CLI configuration
HOME=${HOME:-'/Users/alex'}
export PATH="$HOME/"'.platformsh/bin':"$PATH"
if [ -f "$HOME/"'.platformsh/shell-config.rc' ]; then . "$HOME/"'.platformsh/shell-config.rc'; fi
# END SNIPPET

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

if [ -n "${PROJECT_PREFIX}" ]; then
  lp_title "${PROJECT_PREFIX} - `basename $(pwd)`"
else
  lp_title "`basename $(pwd)`"
fi
