#!/usr/bin/env bash

set -e -o pipefail

script_parent_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
git_repo_dir="$(realpath "${script_parent_dir:?}/..")"

ARGS_FILE="${git_repo_dir:?}/config/ARGS"

get_package_version() {
    pkg_name="${1:?}"
    image_key_prefix="${2:?}"
    image_name="$(get_config_arg "${image_key_prefix:?}_NAME")"
    image_tag="$(get_config_arg "${image_key_prefix:?}_TAG")"

    docker run --rm \
        "${image_name:?}:${image_tag:?}" \
        sh -c \
        "apt-get -qq update && apt list 2>/dev/null ${pkg_name:?} | grep '${pkg_name:?}\/' | sed -E 's#([^ ]+)/[^ ]+ ([^ ]+) .+#\2#g'"
}

get_config_arg() {
    arg="${1:?}"
    sed -n -E "s/^${arg:?}=(.*)\$/\\1/p" ${ARGS_FILE:?}
}

set_config_arg() {
    arg="${1:?}"
    val="${2:?}"
    sed -i -E "s/^${arg:?}=(.*)\$/${arg:?}=${val:?}/" ${ARGS_FILE:?}
}

pkg="Postfix"
pkg_install_name="postfix"
config_ver_key="POSTFIX_VERSION"
config_image_key_prefix="BASE_IMAGE"

existing_upstream_ver=$(get_config_arg ${config_ver_key:?})
latest_upstream_ver=$(get_package_version ${pkg_install_name:?} ${config_image_key_prefix:?})

if [[ "${existing_upstream_ver:?}" == "${latest_upstream_ver:?}" ]]; then
    echo "Existing config is already up to date and pointing to the latest upstream ${pkg:?} version '${latest_upstream_ver:?}'"
else
    echo "Updating ${pkg:?} ${config_ver_key:?} '${existing_upstream_ver:?}' -> '${latest_upstream_ver:?}'"
    set_config_arg "${config_ver_key:?}" "${latest_upstream_ver:?}"
    git add ${ARGS_FILE:?}
    git commit -m "feat: Bump upstream ${pkg:?} version to ${latest_upstream_ver:?}."
fi
