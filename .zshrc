source ~/.zshenv

python3 $binaries/gpg-helper.py
export GPG_TTY=$(tty)

_vimsetup() {
    airline=~/.vim/pack/dist/start/vim-airline
    if [ ! -d $airline ]; then
        git clone https://github.com/vim-airline/vim-airline $airline
    fi
    tmp=~/.vim/tmp
    if [ ! -d $tmp ]; then
        mkdir -p $tmp
    fi
    tmpfile=$tmp/$(date +%Y%m%d)
    if [ ! -e $tmpfile ]; then
        for o in swap tmp undo; do
            find ~/.vim/$o -type f -mtime +1 -delete
        done
        touch $tmpfile
    fi
}

_vimsetup

brew() {
    cfg=~/.config/
    /opt/homebrew/bin/brew $@
    rm -f $cfg/Brewfile
    cwd=$PWD
    cd $cfg && /opt/homebrew/bin/brew bundle dump
    cd $cwd
}

source ~/Git/personal/zshrc
pwgen() {
    python3 $binaries/pwgen.py $@
}

totp() {
    python3 $binaries/totp.py $@
}
