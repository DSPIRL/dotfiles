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
varSyncthingInstall="Y"
varHyprlandInstall="N"
varKanataInstall="N"

if [[ "${chassis}" == "laptop" ]]; then
    read -rp 'Do you want to install Kanata for custom keyboard layouts? (Y/N): ' varKanataInstall
fi

read -rp 'Do you want to install Hyprland packages? (Y/N): ' varHyprlandInstall

# Default packages
cd "${HOME}"
paru -S $(awk -v RS= '{$1=$1}1' "${DOTPKG}/cachyosBasePackages.txt") \
    $([[ "${varHyprlandInstall^^}" == "Y" ]] && $(awk -v RS= '{$1=$1}1' "${DOTPKG}/cachyosHyprlandPackages.txt"))

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

# SSH config setup
bash "${DOTMODS}/ssh_config.sh"
