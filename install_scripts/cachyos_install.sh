#!/usr/bin/env bash

set -u

#==============================================================#
# Define script location variable
DOTS="${HOME}/.local/share/chezmoi"
DOTPKG="${DOTS}/package_lists"
DOTSCRIPTS="${DOTS}/install_scripts"
DOTMODS="${DOTSCRIPTS}/modules"
#==============================================================#

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if [[ "${ID:-}" != "cachyos" ]]; then
    echo "This installer is for CachyOS only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

chassis="$(hostnamectl chassis 2>/dev/null || true)"
varSyncthingInstall="N"
varKanataInstall="N"

read -rp 'Do you want to install Syncthing? (Y/N): ' varSyncthingInstall

if [[ "${chassis}" == "laptop" ]]; then
    read -rp 'Do you want to install Kanata for custom keyboard layouts? (Y/N): ' varKanataInstall
fi

# Sudo access
sudo echo "Sudo access granted for this script"
while true; do
    sudo -v
    sleep 240
done &

# Store the PID of the background process for this install script
SUDO_KEEP_ALIVE_PID=$!
trap 'kill "${SUDO_KEEP_ALIVE_PID}" >/dev/null 2>&1 || true' EXIT

# Default packages
cd "${HOME}"
paru -S $(awk -v RS= '{$1=$1}1' "${DOTPKG}/cachyosBasePackages.txt") \
    $([[ "${varSyncthingInstall^^}" == "Y" ]] && echo syncthing)

# Syncthing setup
if [[ "${varSyncthingInstall^^}" == "Y" ]]; then
    bash "${DOTMODS}/syncthing.sh"
fi

# Kanata install
if [[ "${varKanataInstall^^}" == "Y" ]]; then
    if command -v cargo >/dev/null 2>&1; then
        cargo install kanata
    elif [[ -x "${HOME}/.cargo/bin/cargo" ]]; then
        "${HOME}/.cargo/bin/cargo" install kanata
    else
        echo "Skipping Kanata install: cargo is not available."
    fi
fi

# Zoxide setup
/usr/bin/zoxide init nushell >"${HOME}/.zoxide.nu"

# Apply dotfiles with chezmoi
chezmoi apply

# SSH config setup
bash "${DOTMODS}/ssh_config.sh"
