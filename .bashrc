[[ $- != *i* ]] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=-1
HISTFILESIZE=-1

export VISUAL=vim
export EDITOR="$VISUAL"
export LESSHISTFILE=$HOME/.cache/lesshst
export TERM=xterm
export PAGER=less
export COMP_KNOWN_HOSTS_WITH_HOSTFILE=""

PS1='[\u@\h \W]\$ '

. /etc/profile
for file in $HOME/.env/bashrc \
            /etc/voidedtech/skel/bash_aliases \
            $HOME/.private/etc/env \
            /usr/share/bash-completion/bash_completion \
            $HOME/.config/user-dirs.dirs \
            $HOME/.env/machine/bashrc; do
    if [ -e $file ]; then
        . $file
    fi
done

# check the window size after each command
shopt -s checkwinsize

if [ -x /usr/bin/drudge ]; then
    drudge motd.highlight
fi
