#!/usr/bin/env bash
set -e -o pipefail

setup_postfix() {
    echo "Setting up postfix ..."

    if [[ "${PRE_LAUNCH_HOOK}" != "" ]]; then
        echo "PRE_LAUNCH_HOOK is non-empty ..."
        echo "PRE_LAUNCH_HOOK=\"${PRE_LAUNCH_HOOK:?}\""
        echo "PRE_LAUNCH_HOOK_ARGS=\"${PRE_LAUNCH_HOOK_ARGS}\""
        echo -e "Invoking Pre-launch hook ...\n\n$(realpath ${PRE_LAUNCH_HOOK:?}) ${PRE_LAUNCH_HOOK_ARGS}\n\n"
        $(realpath ${PRE_LAUNCH_HOOK:?}) ${PRE_LAUNCH_HOOK_ARGS}
    fi

    echo
}

start_postfix () {
    echo "Starting postfix"
    exec /usr/sbin/postfix start-fg
}

setup_postfix
start_postfix
