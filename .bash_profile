export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

export PYTHONPATH=/src/github/ansible/lib:
export MANPATH=/src/github/ansible/docs/man:
export PATH=~/bin:/src/github/ansible/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$PATH

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

alias l="ls -alh"
alias cl="clear"
alias ga="git add"
alias gaa="git add --all :/"
alias grc="gaa; git rebase --continue"
alias gcm="git commit -m"
alias gca="git commit --ammend"
alias gpo="git push origin $1 && git push origin --tags"
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
alias gfrs="git flow release start"
alias gfrf="git flow release finish"
alias gfhs="git flow hotfix start"
alias gfhf="git flow hotfix finish"
alias git="hub"
alias fuck='eval $(thefuck $(fc -ln -1)); history -r'
alias FUCK='fuck'

source ~/git-completion.bash
source ~/liquidprompt
