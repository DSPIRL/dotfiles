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

install_packages() {
    local packages=("$@")

    if ((${#packages[@]} == 0)); then
        return 0
    fi

    if command -v paru >/dev/null 2>&1; then
        paru -S --needed "${packages[@]}"
    else
        sudo pacman -S --needed "${packages[@]}"
    fi
}

install_brave() {
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub com.brave.Browser
    sudo ln -fvs /var/lib/flatpak/exports/bin/com.brave.Browser /usr/bin/brave
}

install_kanata() {
    if ! command -v cargo >/dev/null 2>&1 && [[ ! -x "${HOME}/.cargo/bin/cargo" ]]; then
        install_packages rustup

        if command -v rustup >/dev/null 2>&1; then
            rustup default stable
        elif [[ -x "${HOME}/.cargo/bin/rustup" ]]; then
            "${HOME}/.cargo/bin/rustup" default stable
        fi
    fi

    if command -v cargo >/dev/null 2>&1; then
        cargo install kanata
    elif [[ -x "${HOME}/.cargo/bin/cargo" ]]; then
        "${HOME}/.cargo/bin/cargo" install kanata
    else
        echo "Skipping Kanata install: cargo is not available."
    fi
}

install_oh_my_posh() {
    if command -v oh-my-posh >/dev/null 2>&1; then
        echo "oh-my-posh is already installed."
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        install_packages curl
    fi

    curl -s https://ohmyposh.dev/install.sh | bash -s
}

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if [[ "${ID:-}" != "cachyos" ]]; then
    echo "This installer is for CachyOS only (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi

varParuInstall="N"
varHyprlandInstall="N"
varKanataInstall="N"
varBraveInstall="N"
varLazyVimInstall="N"
varSyncthingInstall="N"
varVMHostInstall="N"

echo '##### PACKAGE MANAGER #####'
read -rp 'Do you want to install paru? (Y/N): ' varParuInstall

echo ""
echo '##### SYSTEM SETUP #####'
read -rp 'Do you want to install Hyprland packages and setup greetd? (Y/N): ' varHyprlandInstall
read -rp 'Do you want to install and setup VM host tools? (Y/N): ' varVMHostInstall

echo ""
echo '##### APPLICATIONS #####'
read -rp 'Do you want to install Brave Browser? (Y/N): ' varBraveInstall
read -rp 'Do you want to install LazyVim? (Y/N): ' varLazyVimInstall
read -rp 'Do you want to install and setup Syncthing? (Y/N): ' varSyncthingInstall
read -rp 'Do you want to install Kanata for custom keyboard layouts? (Y/N): ' varKanataInstall

if [[ "${varParuInstall^^}" == "Y" ]]; then
    run_module paru.sh
fi

# Default packages
cd "${HOME}"
mapfile -t installPackages < <(awk 'NF && $1 !~ /^#/ { print }' "${DOTPKG}/cachyosBasePackages.txt")

if [[ "${varSyncthingInstall^^}" == "Y" ]]; then
    installPackages+=(syncthing)
fi

if [[ "${varVMHostInstall^^}" == "Y" ]]; then
    mapfile -t vmHostPackages < <(awk 'NF && $1 !~ /^#/ { print }' "${DOTPKG}/cachyosVMPackages.txt")
    installPackages+=("${vmHostPackages[@]}")
fi

install_packages "${installPackages[@]}"

# Oh My Posh setup
install_oh_my_posh

# Hyprland setup
if [[ "${varHyprlandInstall^^}" == "Y" ]]; then
    bash "${DOTSCRIPTS}/executable_hyprland_install.sh"
fi

# Brave setup
if [[ "${varBraveInstall^^}" == "Y" ]]; then
    install_brave
fi

# LazyVim setup
if [[ "${varLazyVimInstall^^}" == "Y" ]]; then
    run_module lazyvim.sh
fi

# Syncthing setup
if [[ "${varSyncthingInstall^^}" == "Y" ]]; then
    run_module syncthing.sh
fi

# Kanata install
if [[ "${varKanataInstall^^}" == "Y" ]]; then
    install_kanata
    bash "${DOTSCRIPTS}/executable_kanata_setup.sh"
fi

# VM host setup
if [[ "${varVMHostInstall^^}" == "Y" ]]; then
    run_module vm_host.sh
    echo "Please review ${DOTPKG}/cachyosVirtualizationInstructions.md for VM creation notes."
fi

# Zoxide setup
if command -v zoxide >/dev/null 2>&1; then
    zoxide init nushell >"${HOME}/.zoxide.nu"
else
    echo "Skipping zoxide setup: zoxide is not available."
fi

# SSH config setup
run_module ssh_config.sh
