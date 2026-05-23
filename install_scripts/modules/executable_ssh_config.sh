#!/usr/bin/env bash

set -u

ssh_dir="${HOME}/.ssh"
ssh_config="${ssh_dir}/config"
setenv_line="SetEnv TERM=xterm-256color"

mkdir -p "${ssh_dir}"
touch "${ssh_config}"

if ! grep -qxF "${setenv_line}" "${ssh_config}"; then
    printf '%s\n' "${setenv_line}" >>"${ssh_config}"
fi
