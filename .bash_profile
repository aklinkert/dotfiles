export NODE_ENV=development
export NVM_DIR=~/.nvm
export GIT_MERGE_AUTOEDIT=no
export GOPATH=~:~/src/github.com/costacruise/one/go-apis/:~/src/github.com/costacruise/one/go-apis/vendor/
export PATH=~/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$GOPATH/bin:$PATH

alias ll="ls -alh"
alias cl="clear"
alias ga="git add"
alias gaa="git add --all :/"
alias grc="gaa; git rebase --continue"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias gpr="git pull-request"
alias gpo="git push origin"
alias gpot="git push origin --tags"
alias grom="git rebase origin/master"
alias grod="git rebase origin/develop"
alias gp="git pull"
alias gs="git status"
alias gsa="git stash save"
alias gsp="git stash pop"
alias gd="git diff"
alias gu="git up"
alias gf="git fetch --prune && git branch --merged | grep -v \"\*\" | xargs -n 1 git branch -d"
alias gl="git log --pretty=oneline --abbrev-commit --graph --decorate"
alias gfrs="git flow release start"
alias gfrf="git flow release finish"
alias gfhs="git flow hotfix start"
alias gfhf="git flow hotfix finish"
alias git="hub"
alias fuck='eval $(thefuck $(fc -ln -1)); history -r'
alias FUCK='fuck'
alias dns="sudo killall -HUP mDNSResponder"

function docker-clean-images() {
    docker rmi -f $(docker images -a | grep "<none>" | awk '{print $3}')
}

function docker-remove-stopped() {
    docker ps --filter status=exited -q | xargs docker rm -f
}

function hash-key () {
    echo -n "${1}" | openssl dgst -sha256 | cut -c-9
}

function gobuild-linux() {
    CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-s' -installsuffix cgo -o "$(basename "$PWD")" .
}

source ~/liquidprompt
source "/usr/local/opt/nvm/nvm.sh"
[ -f "$HOME/.tokens" ] && source "$HOME/.tokens"
[ -f /usr/local/etc/bash_completion ] && source /usr/local/etc/bash_completion

alias aws-login="eval $(aws ecr get-login)"

