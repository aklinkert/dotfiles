export NODE_ENV=development
export NVM_DIR=~/.nvm
export GIT_MERGE_AUTOEDIT=no
export GOPATH=~/go
export PATH=~/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$HOME/go/bin:$PATH

alias ll="ls -alh"
alias ga="git add"
alias gaa="git add --all :/"
alias grc="gaa; git rebase --continue"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias gpr="git pull-request"
alias grom="git rebase origin/master"
alias grod="git rebase origin/develop"
alias gpo="git push origin"
alias gp="git pull --rebase"
alias gs="git status"
alias gsa="git stash save"
alias gsp="git stash pop"
alias gf="git fetch --prune && git branch --merged | grep -v \"\*\" | xargs -n 1 git branch -d"
alias gl="git log --pretty=oneline --abbrev-commit --graph --decorate"
alias gfrs="git flow release start"
alias gfrf="git flow release finish"
alias gfhs="git flow hotfix start"
alias gfhf="git flow hotfix finish"
alias git="hub"
alias dns="sudo killall -HUP mDNSResponder"
alias first_col="awk '{ print \$1 }'"
alias remove_first_line="tail -n +2"
alias second_col="awk '{ print \$2 }'"
alias third_col="awk '{ print \$3 }'"
alias cobra-init="GOPATH=$HOME cobra init ."
alias k="kubectl"
alias tf="terraform"
alias please="sudo"

for f in $HOME/dotfiles/customers/*; do
  source $f
done

source ~/functions.sh
source ~/liquidprompt
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && source "/usr/local/etc/profile.d/bash_completion.sh"

if [ -f "/usr/local/opt/nvm/nvm.sh" ]; then
    source "/usr/local/opt/nvm/nvm.sh"
fi

[ -f "$HOME/.tokens" ] && source "$HOME/.tokens"
[ -f /usr/local/etc/bash_completion ] && source /usr/local/etc/bash_completion

eval "$(direnv hook bash)"
eval "$(thefuck --alias)"
source <(kubectl completion bash)
