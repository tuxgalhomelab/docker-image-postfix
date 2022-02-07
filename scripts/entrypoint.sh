#!/usr/bin/env bash
set -e -o pipefail

setup_postfix() {
    echo "Setting up postfix ..."

    echo
}

start_postfix () {
    echo "Starting postfix"
    exec /usr/sbin/postfix start-fg
}

if [ "$1" = 'postfix-oneshot' ]; then
    setup_postfix
    start_postfix
else
    exec "$@"
fi
