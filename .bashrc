#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

. /etc/voidedtech/bash/bashrc

source ~/.variables

# check the window size after each command
shopt -s checkwinsize

for file in $HOME/.bash_aliases \
            /etc/voidedtech/bash/aliases \
            $HOME/.bash_completion \
            /usr/share/bash-completion/bash_completion \
            $HOME/.config/user-dirs.dirs; do
    if [ -e $file ]; then
        . $file
    fi
done

unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

for opt in ide; do
    bash ~/.local/bin/$opt.sh
done

export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

for file in $HOME/.pass/env $HOME/store/personal/config/etc/private.exports; do
    if [ -e $file ]; then
        . $file
    fi
done
