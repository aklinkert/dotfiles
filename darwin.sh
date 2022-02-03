ssh-add -K

export BASH_SILENCE_DEPRECATION_WARNING=1

if [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
    source "/usr/local/etc/profile.d/bash_completion.sh"
fi

if [ -f "/usr/local/opt/nvm/nvm.sh" ]; then
    source "/usr/local/opt/nvm/nvm.sh"
fi
