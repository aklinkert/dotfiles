export PATH=~/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$PATH
export EDITOR="subl -w"

alias l="ls -al"
alias cl="clear"

alias ga="git add"
alias gaa="git add --all :/"
alias gcm="git commit -m"
alias gcam="git commit -am"
alias gpo="git push origin"
alias grom="git rebase origin/master"
alias grod="git rebase origin/develop"
alias gp="git pull"
alias gs="git status"
alias gsa="git stash save"
alias gsp="git stash pop"
alias gd="git diff"
alias gf="git fetch --prune && git branch --merged | grep -v \"\*\" | xargs -n 1 git branch -d"
alias gb="git branch"
alias gl="git log --pretty=oneline --abbrev-commit --graph --decorate"

source ~/git-completion.bash
source ~/liquidprompt
