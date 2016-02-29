export NODE_ENV=development
export NVM_DIR=~/.nvm
if [ -f $(brew --prefixnvm)/nvm.sh ]; then
  source  $(brew --prefix nvm)/nvm.sh
fi

export PYTHONPATH=/src/github/ansible/lib:
export MANPATH=/src/github/ansible/docs/man:
export PATH=~/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$PATH

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

alias ll="ls -alh"
alias cl="clear"
alias ga="git add"
alias gaa="git add --all :/"
alias grc="gaa; git rebase --continue"
alias gcm="git commit -m"
alias gca="git commit --amend"
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
alias dns="sudo killall -HUP mDNSResponder"
alias docker-env='eval "$(docker-machine env default)"'

update-docker-host(){
	# clear existing docker.local entry from /etc/hosts
	sudo sed -i '' '/[[:space:]]docker\.local$/d' /etc/hosts

	# get ip of running machine
	export DOCKER_IP="$(echo ${DOCKER_HOST} | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"

	# update /etc/hosts with docker machine ip
	[[ -n $DOCKER_IP ]] && sudo /bin/bash -c "echo \"${DOCKER_IP}	docker.local\" >> /etc/hosts"
}

source ~/git-completion.bash
source ~/liquidprompt

export KUBERNETES_PROVIDER=aws
export KUBE_AWS_ZONE=eu-central-1a
export AWS_S3_REGION=eu-central-1
export MASTER_SIZE=t2.micro
export MINION_SIZE=t2.micro
export INSTANCE_PREFIX=kube
