#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# If not running interactively, don't do anything
. ~/.local/bashrc
case $- in
    *i*) ;;
      *) return;;
esac

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

. ~/.bash_aliases
. ~/.local/aliases
. ~/.bash_completion
. /usr/share/bash-completion/bash_completion

if [[ ! $DISPLAY && XDG_VTNR -eq 1 ]]; then
    export MESA_LOADER_DRIVER_OVERRIDE=i965
    exec startx $HOME/.xinitrc > /tmp/xinit.log 2>&1
    return
fi

export TERM=xterm
export GOPATH="$HOME/.cache/go"
source ~/.config/user-dirs.dirs
if [ ! -z "$SCHROOT_CHROOT_NAME" ]; then
    PS1='[\u@${SCHROOT_CHROOT_NAME} \W]\$ '
    if [ ! -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
    fi
    return
fi

export CHROOT=~/store/chroots/builds
mkdir -p /dev/shm/schroot/overlay

# ssh agent
# Set SSH to use gpg-agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

# gpg setup
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

export UNREAL_SRC=$(readlink ~/store/unreal/current)
export uebp_LogFolder=$HOME/.cache/UAT/

source ~/.pass/env
source ~/store/personal/config/etc/private.exports
