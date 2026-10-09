#!/usr/bin/env bash

set -euo pipefail

#==============================================================#
# Define script location variables
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
        echo "paru not found; using pacman for Hyprland packages."
        sudo pacman -S --needed "${packages[@]}"
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

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "chezmoi is required to deploy the Hyprland and Quickshell configuration." >&2
    exit 1
fi

cd "${HOME}"
mapfile -t hyprlandPackages < <(awk 'NF && $1 !~ /^#/ { print }' "${DOTPKG}/cachyosHyprlandPackages.txt")

install_packages "${hyprlandPackages[@]}"
run_module backlight.sh
run_module greetd.sh
run_module kwallet.sh

# Import existing live toggles before applying managed defaults over their Lua files.
if [[ -r "${HOME}/.config/hypr/config/opacity-toggle.lua" || \
      -r "${HOME}/.config/hypr/config/blur-toggle.lua" || \
      -r "${HOME}/.config/hypr/config/performance-profile.lua" ]]; then
    bash "${DOTS}/dot_config/hypr/scripts/executable_desktop-settings.sh" status >/dev/null
fi

# Deploy only the desktop configuration; do not overwrite unrelated dotfiles.
chezmoi apply "${HOME}/.config/hypr" "${HOME}/.config/quickshell" \
    "${HOME}/.config/rofi" "${HOME}/.config/wallust" \
    "${HOME}/.local/scripts/wallust-refresh"

# NetworkManager supplies nmcli/nmtui; hypridle starts with the Hyprland session.
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
bash "${HOME}/.config/hypr/scripts/desktop-settings.sh" status >/dev/null
bash "${HOME}/.config/hypr/scripts/quickshell-healthcheck.sh" || \
    echo "Review the health-check report; Quickshell starts on your next Hyprland login."
echo "Desktop setup complete. Log into Hyprland to start Quickshell and hypridle."
