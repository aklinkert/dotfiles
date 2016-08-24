export NODE_ENV=development
export NVM_DIR=~/.nvm
if [ -f $(brew --prefix nvm)/nvm.sh ]; then
  source  $(brew --prefix nvm)/nvm.sh
fi

export GIT_MERGE_AUTOEDIT=no
export GOPATH=/src/go
export PATH=~/bin:/usr/local/sbin:/usr/local/etc:/usr/local/bin:$GOPATH/bin:$PATH

if [ -f $(brew --prefix homebrew/php/php56)  ]; then
  export PATH="$(brew --prefix homebrew/php/php56)/bin:$PATH"
fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

if type npm version &>/dev/null; then
  npm completion | bash

  _npm_completion () {
        local words cword
        if type _get_comp_words_by_ref &>/dev/null; then
            _get_comp_words_by_ref -n = -n @ -w words -i cword
        else
            cword="$COMP_CWORD"
            words=("${COMP_WORDS[@]}")
        fi

        local si="$IFS"


        # if your npm command includes `install` or `i `
        if [[ ${words[@]} =~ 'install' ]] || [[ ${words[@]} =~ 'i ' ]]; then
            local cur=${COMP_WORDS[COMP_CWORD]}

            # supply autocomplete words from `~/.npm`, with $cur being value of current expansion like 'expre'
            COMPREPLY=( $( compgen -W "$(ls ~/.npm )" -- $cur ) )
        else
            IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
                COMP_LINE="$COMP_LINE" \
                COMP_POINT="$COMP_POINT" \
                npm completion -- "${words[@]}" \
                2>/dev/null)) || return $?
        fi

        IFS="$si"
    }

    complete -o default -F _npm_completion npm  
fi

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

function docker-clean-images() {
    docker rmi -f $(docker images -a | grep "<none>" | awk '{print $3}')
}

function docker-remove-stopped() {
    docker ps --filter status=exited -q | xargs docker rm -f
}

hash-key () {
    echo -n "${1}" | openssl dgst -sha256 | cut -c-9
}
source ~/git-completion.bash
source ~/liquidprompt

# The next line updates PATH for the Google Cloud SDK.
[[ -s "$HOME/google-cloud-sdk/path.bash.inc" ]] && source "$HOME/google-cloud-sdk/path.bash.inc"

# The next line enables shell command completion for gcloud.
[[ -s "$HOME/google-cloud-sdk/completion.bash.inc" ]] && source "$HOME/google-cloud-sdk/completion.bash.inc"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

[[ -s "$HOME/.sloppy_config" ]] && source "$HOME/.sloppy_config"
