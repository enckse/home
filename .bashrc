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

bash ~/.local/bin/applications.sh

export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

for file in $HOME/.pass/env $HOME/store/personal/config/etc/private.exports; do
    if [ -e $file ]; then
        . $file
    fi
done

_gitpull() {
    TMP_GIT_PULL=$HOME/.cache/gitpull/
    mkdir -p $TMP_GIT_PULL
    TMP_GIT_TODAY=$TMP_GIT_PULL$(date +%Y-%m-%d)
    if [ ! -e $TMP_GIT_TODAY ]; then
        rm -f $TMP_GIT_PULL*
        for f in $GIT_DIRS; do
            dname=$(dirname $f)
            remotes=$(git -C $dname remote | wc -l)
            if [ $remotes -gt 0 ]; then
                echo "pulling $dname"
                git -C $dname pull
            fi
        done
        touch $TMP_GIT_TODAY
    fi
}

(_gitpull | systemd-cat -t gitpull &) > /dev/null 2>&1
