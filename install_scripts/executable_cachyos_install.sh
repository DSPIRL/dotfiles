#!/usr/bin/env bash

set -u

#==============================================================#
# Define script location variable
DOTS="${HOME}/.local/share/chezmoi"
DOTPKG="${DOTS}/package_lists"
DOTSCRIPTS="${DOTS}/install_scripts"
DOTMODS="${DOTSCRIPTS}/modules"
#==============================================================#

run_module() {
    local module="$1"

    if [[ -f "${DOTMODS}/${module}" ]]; then
        bash "${DOTMODS}/${module}"
    elif [[ -f "${DOTMODS}/executable_${module}" ]]; then
        bash "${DOTMODS}/executable_${module}"
    else
        echo "Missing install module: ${module}" >&2
        return 1
    fi
}

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
mapfile -t installPackages < <(awk 'NF { print }' "${DOTPKG}/cachyosBasePackages.txt")

if [[ "${varHyprlandInstall^^}" == "Y" ]]; then
    mapfile -t hyprlandPackages < <(awk 'NF { print }' "${DOTPKG}/cachyosHyprlandPackages.txt")
    installPackages+=("${hyprlandPackages[@]}")
fi

paru -S "${installPackages[@]}"

# Greetd setup
if [[ "${varHyprlandInstall^^}" == "Y" ]]; then
    run_module greetd.sh
fi

# Syncthing setup
if [[ "${varSyncthingInstall^^}" == "Y" ]]; then
    run_module syncthing.sh
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
run_module ssh_config.sh
