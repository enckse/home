#!/bin/bash

HPCSSH=/usr/lib/hpcssh
TICKETS="$HOME/.cache/tickets/"
OSSH="$HPCSSH/ossh/bin/"

if [ -z "$1" ]; then
    echo "no command specified"
    exit 1
fi

_connect() {
    if [ ! -x $OSSH/$1 ]; then
        echo "invalid command"
        return
    fi

    mkdir -p $TICKETS
    chmod 700 $TICKETS
    export KRB5CCNAME=DIR:$TICKETS

    KRB5=${HPCSSH}/krb5/
    export PATH=${KRB5}bin:${HPCSSH}/ossh/bin:$PATH
    export KRB5_CONFIG=${KRB5}etc/krb5.conf
    export OPENSC_CONF="${KRB5}etc/opensc.conf"
    pkinit -V
    if [ $? -ne 0 ]; then
        return
    fi
    $1 ${@:2}
}

cwd=$PWD
cd $HPCSSH
_connect $@
cd $cwd