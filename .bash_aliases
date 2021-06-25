#!/bin/bash
alias diff="diff -u"
alias ls='ls --color=auto'
alias duplicates="fdupes ."
alias grep="rg"

if [ ! -z "$SERVER_SYSTEM" ]; then
dirty-memory() {
    watch -n 1 grep -e Dirty: -e Writeback: /proc/meminfo
}

full-apk-update() {
    apk update
    apk upgrade
    if [ -x /usr/bin/lxc-ls ]; then
        for f in $(lxc-ls); do
            lxc-attach -n $f -- apk update
            lxc-attach -n $f -- apk upgrade
        done
    fi
}
fi

if [ ! -z "$DEVELOPMENT_SYSTEM" ]; then
glint() {
    if command -v go &> /dev/null; then
        local f
        goimports -l . | grep -v bindata.go | sed 's/^/[goimports]    /g'
        revive ./... | sed 's/^/[revive]       /g'
        for f in $(find . -type f -name "*.go" -exec dirname {} \; | sort -u); do
            go vet $f | sed 's/^/[govet]        /g'
        done
        golangci-lint run
    fi
}

plint() {
    local p files
    files="$@"
    if [ -z "$files" ]; then
        files=$(find . -type f -name "*.py")
    fi
    for p in pycodestyle pydocstyle pyflakes; do
        $p $files | sed "s/^/$p: /g"
    done
}

_vim_plugins() {
    for f in "vim-airline/vim-airline" "dense-analysis/ale"; do
        echo "$f"
        p="$HOME/.vim/pack/dist/start/"
        if [ ! -d $p ]; then
            mkdir -p $p
        fi
        p="$p"$(echo $f | cut -d "/" -f 2)
        if [ ! -d $p ]; then
            git clone "https://github.com/$f" $p
        fi
        git -C $p pull
    done
}

sys-upgrade() {
    local f p
    echo "-> update ports"
    sudo port selfupdate
    sudo port upgrade outdated
    echo "-> update kitty"
    kitty-updater
    echo "-> cleanup ports"
    sudo port uninstall inactive
    sudo port reclaim
    echo "-> update vim plugins"
    _vim_plugins
    echo "-> setup defaults"
    if [ "$(which python)" == "/usr/bin/python" ]; then
        sudo port select --set python python39;
    fi
    which pycodestyle 2>&1 || sudo port select --set pycodestyle pycodestyle-py39
    which pydocstyle 2>&1 || sudo port select --set pydocstyle py39-pydocstyle
    which pyflakes 2>&1 || sudo port select --set pyflakes py39-pyflakes
    echo "go tools"
    go get golang.org/x/tools/cmd/goimports
}
fi
