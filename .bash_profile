export NODE_ENV=development
export NVM_DIR=~/.nvm
export GIT_MERGE_AUTOEDIT=no
export GOPATH=~
export PATH=~/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$GOPATH/bin:$PATH

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
alias gp="git pull"
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

function kube-port-forward {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: kube-port-forward <namespace> <deployment> <port>"
        return
    fi

    command="kubectl -n "$1" port-forward $(kubectl get pods -n $1 | grep $2 | head -n 1 | awk '{ print $1 }') $3"
    echo "executing ${command}"

    eval ${command}
}

# thefuck config
eval $(thefuck --alias)
eval $(thefuck --alias FUCK)

function docker-clean-images {
    docker images -f dangling=true -q | xargs docker rmi -f
}

function docker-delete-images {
    if [ "${1}" == "" ]; then echo "Please pass a name pattern for grep"; return; fi

    echo "Deleting the following images:"
    docker images | grep "$1" | awk '{ print $1 }' | tr '\n' ' '
    docker images | grep "$1" | awk '{ print $3 }' | xargs docker rmi -f
}

function docker-delete-all-images {
    read -p "Are you FUCKING SURE? There is no way back! " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return
    fi

    docker images -q | xargs docker rmi -f
}

function docker-remove-status {
    docker ps --filter status=$1 -q | xargs docker rm -f
}

function docker-remove-stopped {
    docker-remove-status exited
}

function docker-remove-all {
    docker ps -a -q | xargs docker rm -f
}

function docker-stop-all {
    docker ps --filter status=running -q | xargs docker stop
}

function hash-key {
    echo -n "${1}" | openssl dgst -sha256 | cut -c-9
}

function gobuild-linux {
    CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-s' -installsuffix cgo -o "$(basename "$PWD")" .
}

function http-server {
    docker rm http-server || true
    echo "Server listening on http://localhost:8080 "
    docker run --name http-server -it -p 8080:80  -v "$(pwd):/usr/share/nginx/html:ro" nginx:alpine
}

source ~/git-completion.bash
source ~/liquidprompt

source "/usr/local/opt/nvm/nvm.sh"
[ -f "$HOME/.tokens" ] && source "$HOME/.tokens"
[ -f /usr/local/etc/bash_completion ] && source /usr/local/etc/bash_completion

function  aws-login {
	eval $(aws ecr get-login)
}

function clear-dns-cache {
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    echo "DNS cache flushed"
}

eval "$(direnv hook bash)"
